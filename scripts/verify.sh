#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

QUIET=false
CORTEX_READY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet) QUIET=true; shift ;;
    --cortex-ready) CORTEX_READY=true; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

say() {
  if [ "$QUIET" = false ]; then
    echo "$@"
  fi
}

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

check_file() {
  if [ -f "$1" ]; then
    say -e "  ${GREEN}✓${NC} $1"
  else
    say -e "  ${RED}✗${NC} $1 (missing)"
    ERRORS=$((ERRORS + 1))
  fi
}

check_dir() {
  if [ -d "$1" ]; then
    say -e "  ${GREEN}✓${NC} $1"
  else
    say -e "  ${RED}✗${NC} $1 (missing)"
    ERRORS=$((ERRORS + 1))
  fi
}

check_json() {
  if [ ! -f "$1" ]; then
    say -e "  ${RED}✗${NC} $1 (missing)"
    ERRORS=$((ERRORS + 1))
    return
  fi

  if jq . "$1" >/dev/null 2>&1; then
    say -e "  ${GREEN}✓${NC} $1"
  else
    say -e "  ${RED}✗${NC} $1 (invalid JSON)"
    ERRORS=$((ERRORS + 1))
  fi
}

warn_if_missing() {
  if [ -f "$1" ]; then
    say -e "  ${GREEN}✓${NC} $1"
  else
    say -e "  ${YELLOW}○${NC} $1 (missing)"
    WARNINGS=$((WARNINGS + 1))
  fi
}

say "🔍 Genius Team v22.0 — Verification"
say "═══════════════════════════════════════════════════════════════"
say ""

say "📁 Contract structure..."
check_dir ".genius"
check_dir ".genius/memory"
check_dir ".genius/outputs"
check_dir ".genius/wiki"
check_dir "scripts"
check_json ".genius/state.json"
check_json ".genius/config.json"
check_json ".genius/mode.json"
check_json ".genius/outputs/state.json"
check_json ".genius/wiki/manifest.json"
check_json ".genius/wiki/meta-concepts.json"
check_json ".genius/workflows.json"
check_file ".genius/DASHBOARD.html"
check_file ".genius/session-log.jsonl"
check_file ".genius/memory/BRIEFING.md"
check_file ".genius/wiki/README.md"
say ""

ENGINE="claude"
if [ -f ".genius/config.json" ]; then
  ENGINE=$(jq -r '.engine // "claude"' .genius/config.json 2>/dev/null || echo "claude")
fi

say "🧠 Engine-specific files..."
if [[ "$ENGINE" == "claude" || "$ENGINE" == "dual" ]]; then
  check_file "CLAUDE.md"
  check_dir ".claude"
  check_file ".claude/settings.json"
fi
if [[ "$ENGINE" == "codex" || "$ENGINE" == "dual" ]]; then
  check_file "AGENTS.md"
  check_dir ".agents"
fi
say ""

say "🧾 Memory files..."
check_json ".genius/memory/decisions.json"
check_json ".genius/memory/patterns.json"
check_json ".genius/memory/progress.json"
check_json ".genius/memory/errors.json"
warn_if_missing ".claude/plan.md"
warn_if_missing ".agents/plan.md"
say ""

say "📜 Scripts..."
check_file "scripts/create.sh"
check_file "scripts/add.sh"
check_file "scripts/setup.sh"
check_file "scripts/upgrade.sh"
check_file "scripts/migrate-state.sh"
check_file "scripts/migrate-cortex-ready.sh"
check_file "scripts/verify.sh"
check_file "scripts/bin/genius-command"
say ""

say "📊 State semantics..."
if [ -f ".genius/state.json" ]; then
  for key in version contractVersion installStatus migrationStatus bootstrapStatus phase mode installMode engine origin currentSkill currentWorkflow checkpoints tasks artifacts compatibility; do
    if jq -e --arg key "$key" 'has($key)' .genius/state.json >/dev/null 2>&1; then
      say -e "  ${GREEN}✓${NC} state.${key}"
    else
      say -e "  ${RED}✗${NC} state.${key} missing"
      ERRORS=$((ERRORS + 1))
    fi
  done
fi
say ""

if [ "$CORTEX_READY" = true ] && [ -f ".genius/state.json" ]; then
  say "🧭 Cortex-ready checks..."
  READY="$(jq -r '.compatibility.cortexReady // false' .genius/state.json 2>/dev/null || echo false)"
  MIGRATION="$(jq -r '.migrationStatus // ""' .genius/state.json 2>/dev/null || true)"
  BOOTSTRAP="$(jq -r '.bootstrapStatus // ""' .genius/state.json 2>/dev/null || true)"
  if [ "$READY" != "true" ] || [ "$MIGRATION" != "cortex-ready" ] || [ "$BOOTSTRAP" != "completed" ]; then
    say -e "  ${RED}✗${NC} repo is not fully Cortex-ready"
    ERRORS=$((ERRORS + 1))
  else
    say -e "  ${GREEN}✓${NC} repo is fully Cortex-ready"
  fi
  say ""
fi

say "═══════════════════════════════════════════════════════════════"
if [ "$ERRORS" -gt 0 ]; then
  say -e "${RED}❌ ${ERRORS} error(s) detected.${NC}"
  exit 1
fi

if [ "$WARNINGS" -gt 0 ]; then
  say -e "${YELLOW}⚠️ ${WARNINGS} warning(s), but verification passed.${NC}"
else
  say -e "${GREEN}✅ Verification passed.${NC}"
fi
