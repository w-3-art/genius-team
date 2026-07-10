#!/usr/bin/env bash
# genius-guard-boundary.sh — Boundary guard (P4-08)
# -----------------------------------------------------------------------------
# BLOCKING PreToolUse hook for the irreversible / high-cost boundaries.
# Policy source: decisions/GUARD-POLICY.md — "advisory in-loop, blocking at the
# boundaries". This script ONLY blocks at boundaries; the internal dev loop stays
# advisory (handled by the warning hooks in settings.json, never here).
#
# Boundaries enforced:
#   1. PUSH / PUBLISH / DEPLOY  (git push, npm/pnpm/yarn publish, vercel deploy,
#      railway/netlify/wrangler/flyctl deploy, gh release create, docker push,
#      supabase db push, eas submit). Denied when the pre-deploy checklist has
#      not passed (.genius/state.json phase != "deploy-approved") OR the action
#      is initiated by an active loop whose autonomy_level < L4. Matched ONLY at
#      command position (start / after ; && || | ( { backtick) so a boundary
#      keyword inside an echo/string/comment does NOT fire (GUARD-POLICY §5.1).
#   2. UNVETTED INSTALL  (curl|sh, wget|sh, claude plugin install, cortex skill
#      add) AND unvetted skill-directory writes: a Bash cp/mv/git clone/tee/
#      redirect/curl -o/wget -O/dd of= into a skills path, or a Write tool call
#      whose target is a skills file
#      (.claude/skills/<name>/SKILL.md, **/skills/<name>/SKILL.md). Denied unless
#      .genius/allow-install exists (explicit human vetting). Runs on Bash|Write.
#
# Mechanism (verified in Claude Code 2.1.198, GUARD-POLICY §3): a PreToolUse hook
# denies a tool call by writing this JSON on stdout:
#   {"hookSpecificOutput":{"hookEventName":"PreToolUse",
#     "permissionDecision":"deny","permissionDecisionReason":"<message>"}}
#
# Invariants (GUARD-POLICY §5):
#   - Read the payload as JSON on STDIN, never the environment (P0-12 lesson).
#   - Silent (exit 0, no output) in the nominal case — do not pollute the loop.
#   - Explicit, actionable reason on every deny.
#   - Escape hatch GENIUS_GUARD_OVERRIDE=1 bypasses, ALWAYS logged (never silent).
# -----------------------------------------------------------------------------

set -o pipefail

HOOK_JSON=$(cat)

TOOL=$(printf '%s' "$HOOK_JSON" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
CMD=$(printf '%s'  "$HOOK_JSON" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")
FILE=$(printf '%s' "$HOOK_JSON" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null || echo "")

# Boundaries apply to Bash (shell commands) and Write (skill-file writes). Any
# other tool is out of scope — stay silent (GUARD-POLICY §4 matcher "Bash|Write").
case "$TOOL" in
  Bash|Write) ;;
  *) exit 0 ;;
esac
# Nothing inspectable → stay silent.
[ -n "$CMD" ] || [ -n "$FILE" ] || exit 0

# Target string used for logging (the command for Bash, the path for Write).
TARGET="${CMD:-$FILE}"

GUARD_LOG=".genius/guard.log"
TS=$(date "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "?")

# redact_secrets — mask secret/token/credential shapes before they hit the log.
# Policy: docs/TELEMETRY-PRIVACY.md §1 (no secret ever reaches a log) — the guard
# logs the command it acted on, which can carry an embedded credential. Patterns
# mirror Revius' SECRET_PATTERNS. POSIX/BSD-and-GNU-sed safe (no \s, no \d).
redact_secrets() {
  printf '%s' "$1" | sed -E \
    -e 's/(sk|pk)_(live|test)_[A-Za-z0-9]{6,}/[REDACTED]/g' \
    -e 's/[Bb][Ee][Aa][Rr][Ee][Rr][[:space:]]+[A-Za-z0-9._~+/-]+=*/Bearer [REDACTED]/g' \
    -e 's/([Aa][Pp][Ii][-_]?([Kk][Ee][Yy]|[Ss][Ee][Cc][Rr][Ee][Tt]))([=:])[[:space:]]*["'"'"']?[A-Za-z0-9._~+/-]{6,}["'"'"']?/\1\3[REDACTED]/g' \
    -e 's/([Pp][Aa][Ss][Ss][Ww]?[Oo]?[Rr]?[Dd]?)([=:])[[:space:]]*["'"'"']?[^[:space:]"'"'"']{4,}["'"'"']?/\1\2[REDACTED]/g' \
    -e 's#(://[^/@:[:space:]]+):[^@/[:space:]]+@#\1:[REDACTED]@#g'
}

log_guard() {
  # Never silent: every override / allow / deny leaves a trace. Redacted first —
  # the audit trail must record WHAT was guarded, never the secret inside it.
  mkdir -p .genius 2>/dev/null || true
  printf '[%s] BOUNDARY %s\n' "$TS" "$(redact_secrets "$1")" >> "$GUARD_LOG" 2>/dev/null || true
}

emit_deny() {
  # $1 = human-readable, actionable reason. jq handles JSON escaping.
  jq -cn --arg r "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
}

# --- Boundary detection ------------------------------------------------------

# Command position: start of a line, or right after a shell separator
# (; & | ( { backtick). grep scans per line, so ^ also covers newlines. This
# ensures a boundary keyword inside an echo/string/comment/arg does NOT fire.
CMDPOS='(^|[;&|(`{])[[:space:]]*'

# Real-world command forms that sit BETWEEN the command position and the boundary
# keyword. Each is anchored strictly after CMDPOS (so string/comment safety from
# §5.1 is preserved — a benign keyword still needs a separator immediately before
# it), but they close the gap where a genuine, irreversible push/publish escapes
# just because it carries a common prefix:
#   ENVPFX  leading env-var assignments — NODE_ENV=production npm publish,
#           GIT_SSH_COMMAND="ssh -i k" git push (quoted values may hold spaces).
#   BINPFX  a path on the binary — absolute (/usr/bin/git push) OR relative
#           (./git push, ../bin/git push, bin/git push). A path prefix is a run
#           of segments each ending in "/", directly glued to the binary name.
#   FLAGS   flags (with optional values) before the subcommand — git -C repo push,
#           yarn --cwd . publish. Never swallows the subcommand: a following
#           non-dash token (push/publish/…) ends the flag run.
ENVPFX='([A-Za-z_][A-Za-z0-9_]*=("[^"]*"|'\''[^'\'']*'\''|[^[:space:]])*[[:space:]]+)*'
BINPFX='(/?([^[:space:]/;&|]+/)*)?'
FLAGS='([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]]+)?)*'

# WRAP — known command WRAPPERS that sit between the command position and the
# real push/publish keyword: "env NODE_ENV=x npm publish", "sudo git push",
# "command git push", "nohup git push", "time git push", "nice -n N git push",
# "stdbuf -oL git push", "timeout N git push". Each wrapper carries its own args
# so the run ends exactly at the wrapped subcommand — never swallowing it:
#   env      [-i] and NAME=val assignments
#   sudo     any run of flags with optional values (FLAGS) — "-E", "-H", "-i",
#            "-E -H", "-u user" (NOT just "-u user": "sudo -E git push" is real).
#   command  [-p]
#   nice     any flags (FLAGS) — "-n 10", "-10", "--adjustment=10",
#            "--adjustment 10" (NOT just "-n N").
#   stdbuf   at least one flag
#   timeout  any run of flags with optional values (FLAGS) then a DURATION —
#            "-s KILL 30", "-k 5 30", "--kill-after 5 30" (NOT just valueless
#            flags before the duration).
# Each wrapper keyword also carries an optional absolute-path prefix (BINPFX), so
# "/usr/bin/sudo git push", "/bin/nice -n 10 git push", "/usr/bin/timeout 30 git
# push", "/usr/bin/env NODE_ENV=x npm publish" are caught too. Wrappers may nest
# ("sudo nohup git push"), hence the outer (…[[:space:]]+)*.
# Anchored strictly after CMDPOS/ENVPFX so string/comment safety (§5.1) holds:
# a wrapper keyword inside an echo/quote/comment has no separator before it and
# never fires ("echo 'sudo git push'", "# time git push" still PASS).
ASSIGN='[A-Za-z_][A-Za-z0-9_]*=("[^"]*"|'\''[^'\'']*'\''|[^[:space:]])*'
WRAP_ONE="${BINPFX}(env([[:space:]]+-i)?([[:space:]]+${ASSIGN})*|sudo${FLAGS}|command([[:space:]]+-p)?|nohup|time|nice${FLAGS}|stdbuf([[:space:]]+-[^[:space:]]+)+|timeout${FLAGS}[[:space:]]+[0-9]+([.][0-9]+)?[a-z]?)"
WRAP="(${WRAP_ONE}[[:space:]]+)*"

PUSHPUB_INNER="(${BINPFX}git${FLAGS}[[:space:]]+push|${BINPFX}(npm|pnpm|yarn)${FLAGS}[[:space:]]+publish|${BINPFX}npx[[:space:]]+[^&|;]*publish|${BINPFX}vercel${FLAGS}[[:space:]]+(deploy|.*--prod)|${BINPFX}netlify${FLAGS}[[:space:]]+deploy|${BINPFX}railway${FLAGS}[[:space:]]+(up|deploy)|${BINPFX}wrangler${FLAGS}[[:space:]]+deploy|${BINPFX}flyctl${FLAGS}[[:space:]]+deploy|${BINPFX}gh${FLAGS}[[:space:]]+release[[:space:]]+create|${BINPFX}docker${FLAGS}[[:space:]]+push|${BINPFX}supabase${FLAGS}[[:space:]]+db[[:space:]]+push|${BINPFX}eas${FLAGS}[[:space:]]+submit)"
# ENVPFX may recur after WRAP too ("sudo HUSKY=0 git push"); it matches empty in
# the common case, so no false positive is introduced.
PUSHPUB_RX="${CMDPOS}${ENVPFX}${WRAP}${ENVPFX}${PUSHPUB_INNER}"

# SSH remote command that carries a push (best-effort, documented): "ssh host
# git push". Fires only when ssh sits at command position and "git push" appears
# in the remote command run (bounded by ;&| so it stays on the same command).
# "echo 'ssh host git push'" / "# ssh host git push" have no separator before
# ssh and still PASS.
SSH_PUSH_RX="${CMDPOS}ssh[[:space:]]+[^;&|]*git[[:space:]]+push"

# Shell -c wrapper that carries a push/publish (best-effort, documented). Fires
# ONLY when bash/sh/zsh is ITSELF at command position (optionally path-prefixed),
# followed by a "-c"-family flag and a quoted command string whose FIRST command
# is git push / npm|pnpm|yarn publish: "bash -c \"git push\"", "sh -c 'npm
# publish'", "/bin/zsh -lc \"yarn publish\"". Scope note (like SSH above): only
# the leading command inside the -c string is inspected; a push buried after a
# separator ("bash -c 'cd r && git push'") is NOT caught here — that is an
# accepted best-effort limitation (GUARD-POLICY §5.1). Because the shell keyword
# must sit at command position, a shell name inside another command's quoted
# argument never fires: "echo 'bash -c \"git push\"'" (echo is the command, bash
# is inside its quote — no separator before it) still PASSES.
SHELLC_RX="${CMDPOS}${BINPFX}(bash|sh|zsh)[[:space:]]+([^\"']*[[:space:]])?-[A-Za-z]*c[[:space:]]+[\"']?[[:space:]]*(git[[:space:]]+push|(npm|pnpm|yarn)[[:space:]]+publish)"

# Unvetted install from the network (also anchored at command position).
INSTALL_INNER='(curl[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh|wget[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh|claude[[:space:]]+plugin[[:space:]]+install|cortex[[:space:]]+skill[[:space:]]+add)'
INSTALL_RX="${CMDPOS}${INSTALL_INNER}"

# A clear skills-directory path (§4 frontière INSTALL): .claude/skills/... or any
# **/skills/<name>/SKILL.md. Kept deliberately narrow so we only fire on clear
# skills targets (GUARD-POLICY §5.1 — when in doubt, do not block).
SKILLS_PATH_RX='(\.claude/skills/|(^|/)skills/[^/]+/SKILL\.md)'
# A Bash command that writes a skill into a skills path via cp/mv/rsync/install/
# ln/git clone/tee or a redirect.
# curl -o / --output, wget -O / --output-document, and dd of= are just as capable
# of dropping a SKILL.md into a skills path as cp/mv/tee/redirect — the output
# flag is required so a plain download (path only in a URL, no write) still PASSES.
# Directory-target download flags land a skill just as well as file-target ones:
# wget -P / --directory-prefix and curl --output-dir take a DIRECTORY, so a skills
# dir given there is a write too. "git clone" may carry flags before the verb
# (e.g. "git -C .claude/skills/evil clone URL", where the skills dir is the -C
# value BEFORE "clone") — GIT_C_CLONE_RX below covers that path-before-verb shape.
SKILLS_WRITE_RX='((cp|mv|rsync|install|ln)[[:space:]]|git[[:space:]]+clone[[:space:]]|tee[[:space:]]|curl[^;&|]*[[:space:]](-o|--output[[:space:]=]|--output-dir[[:space:]=])|wget[^;&|]*[[:space:]](-O|--output-document[[:space:]=]|-P|--directory-prefix[[:space:]=])|dd[^;&|]*[[:space:]]of=|>[^;&|]*)[^;&|]*(\.claude/skills/|(^|/)skills/[^/]+/SKILL\.md)'
# "git -C <skills-dir> clone URL": the skills target is the -C value that sits
# BEFORE "clone", so SKILLS_WRITE_RX (which needs the path AFTER the write verb)
# cannot reach it. Match git -> optional flags -> -C -> a skills path -> then
# "clone" as the git VERB: the -C value ends at whitespace, then only optional
# dash-flags may sit before "clone". This does NOT fire when "clone" is merely a
# LATER token — "git -C .claude/skills/x commit -m 'add clone feature'",
# "… add clone", "… grep clone", "… log --grep clone", "… branch clone" all PASS
# (the earlier [^;&|]*[[:space:]]clone tail wrongly matched "clone" as any word).
GIT_C_CLONE_RX="${CMDPOS}${BINPFX}git[[:space:]]+([^;&|]*[[:space:]])?-C[[:space:]]+[\"']?(\.claude/skills/|(^|/)skills/[^/]+/SKILL\.md)[^[:space:];&|]*[\"']?([[:space:]]+-[^[:space:]]+)*[[:space:]]+clone([[:space:]]|\$)"

IS_PUSHPUB=false
IS_INSTALL=false

# Push/publish/deploy is a shell-only boundary (Bash).
if [ "$TOOL" = "Bash" ] && [ -n "$CMD" ]; then
  printf '%s' "$CMD" | grep -qE "$PUSHPUB_RX"     && IS_PUSHPUB=true
  printf '%s' "$CMD" | grep -qE "$SSH_PUSH_RX"     && IS_PUSHPUB=true
  printf '%s' "$CMD" | grep -qE "$SHELLC_RX"       && IS_PUSHPUB=true
  printf '%s' "$CMD" | grep -qE "$INSTALL_RX"      && IS_INSTALL=true
  printf '%s' "$CMD" | grep -qE "$SKILLS_WRITE_RX"  && IS_INSTALL=true
  printf '%s' "$CMD" | grep -qE "$GIT_C_CLONE_RX"   && IS_INSTALL=true
fi

# Write tool: deny creating/replacing a skill file inside a skills directory.
if [ "$TOOL" = "Write" ] && [ -n "$FILE" ]; then
  printf '%s' "$FILE" | grep -qE "$SKILLS_PATH_RX" && IS_INSTALL=true
fi

# Nominal case: not a boundary action → stay silent (GUARD-POLICY §5.1/5.3).
if [ "$IS_PUSHPUB" = false ] && [ "$IS_INSTALL" = false ]; then
  exit 0
fi

# --- Escape hatch (traceable, per-action, never silent) ----------------------
if [ "${GENIUS_GUARD_OVERRIDE:-}" = "1" ]; then
  log_guard "OVERRIDE GENIUS_GUARD_OVERRIDE=1 bypassed guard for: ${TARGET:0:200}"
  exit 0
fi

# --- Boundary 2: unvetted install -------------------------------------------
if [ "$IS_INSTALL" = true ]; then
  if [ -f .genius/allow-install ]; then
    log_guard "ALLOW install (.genius/allow-install present) for: ${TARGET:0:200}"
    exit 0
  fi
  log_guard "DENY install (no .genius/allow-install) for: ${TARGET:0:200}"
  emit_deny "Genius Guard — INSTALL boundary blocked. This action installs/activates a skill from an unvetted source: curl|sh / wget|sh / plugin install / cortex skill add, or a write into a skills directory (.claude/skills/<name>/SKILL.md, **/skills/<name>/SKILL.md) via cp/mv/git clone/redirect or the Write tool. Audit the source first. When you have reviewed it and trust it: 'touch .genius/allow-install' to allow installs in this project, or set GENIUS_GUARD_OVERRIDE=1 for a single logged bypass (recorded in .genius/guard.log)."
  exit 0
fi

# --- Boundary 1: push / publish / deploy ------------------------------------
if [ "$IS_PUSHPUB" = true ]; then
  PHASE=$(jq -r '.phase // ""' .genius/state.json 2>/dev/null || echo "")

  # Condition A — pre-deploy checklist must have passed.
  if [ "$PHASE" != "deploy-approved" ]; then
    log_guard "DENY push/publish (phase='$PHASE' != deploy-approved) for: ${CMD:0:200}"
    emit_deny "Genius Guard — PUSH/PUBLISH boundary blocked: pre-deploy checklist not passed (state.json phase='$PHASE', expected 'deploy-approved'). Run genius-qa + genius-security, clear the human deploy checkpoint, and set .genius/state.json phase to 'deploy-approved' before pushing/publishing/deploying. One-off logged bypass: GENIUS_GUARD_OVERRIDE=1 (recorded in .genius/guard.log)."
    exit 0
  fi

  # Condition B — an action initiated by a loop needs autonomy_level L4 (earned,
  # with an active audit log). Detect an in-progress loop and read its contract.
  LOOP_DIR=""
  if [ -n "${GENIUS_LOOP_SLUG:-}" ] && [ -d ".genius/loops/$GENIUS_LOOP_SLUG" ]; then
    LOOP_DIR=".genius/loops/$GENIUS_LOOP_SLUG"
  else
    for st in .genius/loops/*/STATE.md; do
      [ -f "$st" ] || continue
      if grep -qE '^- status: in-progress' "$st" 2>/dev/null; then
        LOOP_DIR=$(dirname "$st")
        break
      fi
    done
  fi

  if [ -n "$LOOP_DIR" ]; then
    LEVEL=$(grep -E '^- *autonomy_level: *L[1-4]' "$LOOP_DIR/CONTRACT.md" 2>/dev/null \
      | head -1 | sed -E 's/^- *autonomy_level: *(L[1-4]).*/\1/' || echo "")
    LNUM=$(printf '%s' "$LEVEL" | tr -d 'Ll')
    # Unknown / missing level → treat as lowest (safe): a boundary is never a
    # blank cheque. "Level four is earned, not assumed" (GUARD-POLICY §6).
    case "$LNUM" in 1|2|3|4) : ;; *) LNUM=1 ;; esac

    NEEDS_AUDIT=false
    if [ "$LNUM" -eq 4 ]; then
      # Even L4 must show an active audit log for this run (STATE.md present).
      [ -f "$LOOP_DIR/STATE.md" ] || NEEDS_AUDIT=true
    fi

    if [ "$LNUM" -lt 4 ] || [ "$NEEDS_AUDIT" = true ]; then
      log_guard "DENY push/publish (loop '$(basename "$LOOP_DIR")' autonomy=${LEVEL:-none}, audit_ok=$([ "$NEEDS_AUDIT" = true ] && echo no || echo yes)) for: ${CMD:0:200}"
      emit_deny "Genius Guard — PUSH/PUBLISH boundary blocked: this action is initiated by loop '$(basename "$LOOP_DIR")' with autonomy_level=${LEVEL:-unknown} (needs L4 full-auto-with-audit-logs, and an active audit log). A loop below L4 may not cross the push/publish/deploy boundary without explicit per-action human approval. Approve this run manually, or run it outside the loop. One-off logged bypass: GENIUS_GUARD_OVERRIDE=1 (recorded in .genius/guard.log)."
      exit 0
    fi
  fi
fi

# Nominal: boundary command but all conditions satisfied → allow, stay silent.
exit 0
