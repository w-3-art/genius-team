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
#      add) AND unvetted skill-directory writes: a Bash cp/mv/git clone/redirect
#      into a skills path, or a Write tool call whose target is a skills file
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

log_guard() {
  # Never silent: every override / allow / deny leaves a trace.
  mkdir -p .genius 2>/dev/null || true
  printf '[%s] BOUNDARY %s\n' "$TS" "$1" >> "$GUARD_LOG" 2>/dev/null || true
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

PUSHPUB_INNER='(git[[:space:]]+push|(npm|pnpm|yarn)[[:space:]]+publish|npx[[:space:]]+[^&|;]*publish|vercel[[:space:]]+(deploy|.*--prod)|netlify[[:space:]]+deploy|railway[[:space:]]+(up|deploy)|wrangler[[:space:]]+deploy|flyctl[[:space:]]+deploy|gh[[:space:]]+release[[:space:]]+create|docker[[:space:]]+push|supabase[[:space:]]+db[[:space:]]+push|eas[[:space:]]+submit)'
PUSHPUB_RX="${CMDPOS}${PUSHPUB_INNER}"

# Unvetted install from the network (also anchored at command position).
INSTALL_INNER='(curl[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh|wget[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh|claude[[:space:]]+plugin[[:space:]]+install|cortex[[:space:]]+skill[[:space:]]+add)'
INSTALL_RX="${CMDPOS}${INSTALL_INNER}"

# A clear skills-directory path (§4 frontière INSTALL): .claude/skills/... or any
# **/skills/<name>/SKILL.md. Kept deliberately narrow so we only fire on clear
# skills targets (GUARD-POLICY §5.1 — when in doubt, do not block).
SKILLS_PATH_RX='(\.claude/skills/|(^|/)skills/[^/]+/SKILL\.md)'
# A Bash command that writes a skill into a skills path via cp/mv/rsync/install/
# ln/git clone/tee or a redirect.
SKILLS_WRITE_RX='((cp|mv|rsync|install|ln)[[:space:]]|git[[:space:]]+clone[[:space:]]|tee[[:space:]]|>[^;&|]*)[^;&|]*(\.claude/skills/|(^|/)skills/[^/]+/SKILL\.md)'

IS_PUSHPUB=false
IS_INSTALL=false

# Push/publish/deploy is a shell-only boundary (Bash).
if [ "$TOOL" = "Bash" ] && [ -n "$CMD" ]; then
  printf '%s' "$CMD" | grep -qE "$PUSHPUB_RX"     && IS_PUSHPUB=true
  printf '%s' "$CMD" | grep -qE "$INSTALL_RX"      && IS_INSTALL=true
  printf '%s' "$CMD" | grep -qE "$SKILLS_WRITE_RX"  && IS_INSTALL=true
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
