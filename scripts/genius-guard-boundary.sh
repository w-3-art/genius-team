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
#      is initiated by an active loop whose autonomy_level < L4.
#   2. UNVETTED INSTALL  (curl|sh, wget|sh, claude plugin install, cortex skill
#      add). Denied unless .genius/allow-install exists (explicit human vetting).
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

# Only the Bash tool carries a shell command; anything else is out of scope.
[ "$TOOL" = "Bash" ] || exit 0
[ -n "$CMD" ] || exit 0

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

PUSHPUB_RX='(git[[:space:]]+push|(npm|pnpm|yarn)[[:space:]]+publish|npx[[:space:]]+[^&|;]*publish|vercel[[:space:]]+(deploy|.*--prod)|netlify[[:space:]]+deploy|railway[[:space:]]+(up|deploy)|wrangler[[:space:]]+deploy|flyctl[[:space:]]+deploy|gh[[:space:]]+release[[:space:]]+create|docker[[:space:]]+push|supabase[[:space:]]+db[[:space:]]+push|eas[[:space:]]+submit)'

INSTALL_RX='(curl[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh|wget[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh|claude[[:space:]]+plugin[[:space:]]+install|cortex[[:space:]]+skill[[:space:]]+add)'

IS_PUSHPUB=false
IS_INSTALL=false
printf '%s' "$CMD" | grep -qE "$PUSHPUB_RX" && IS_PUSHPUB=true
printf '%s' "$CMD" | grep -qE "$INSTALL_RX" && IS_INSTALL=true

# Nominal case: not a boundary command → stay silent (GUARD-POLICY §5.1/5.3).
if [ "$IS_PUSHPUB" = false ] && [ "$IS_INSTALL" = false ]; then
  exit 0
fi

# --- Escape hatch (traceable, per-action, never silent) ----------------------
if [ "${GENIUS_GUARD_OVERRIDE:-}" = "1" ]; then
  log_guard "OVERRIDE GENIUS_GUARD_OVERRIDE=1 bypassed guard for: ${CMD:0:200}"
  exit 0
fi

# --- Boundary 2: unvetted install -------------------------------------------
if [ "$IS_INSTALL" = true ]; then
  if [ -f .genius/allow-install ]; then
    log_guard "ALLOW install (.genius/allow-install present) for: ${CMD:0:200}"
    exit 0
  fi
  log_guard "DENY install (no .genius/allow-install) for: ${CMD:0:200}"
  emit_deny "Genius Guard — INSTALL boundary blocked. This command installs code from an unvetted source (curl|sh / plugin install / skill add). Audit the source first. When you have reviewed it and trust it: 'touch .genius/allow-install' to allow installs in this project, or set GENIUS_GUARD_OVERRIDE=1 for a single logged bypass (recorded in .genius/guard.log)."
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
