#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

QUIET=false
CORTEX_READY=false
MANIFEST_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet) QUIET=true; shift ;;
    --cortex-ready) CORTEX_READY=true; shift ;;
    --manifest) MANIFEST_MODE=true; shift ;;
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

# ── --manifest: compare the install manifest against the real tree ──
if [ "$MANIFEST_MODE" = true ]; then
  _sha256() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" 2>/dev/null | awk '{print $1}';
    elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" 2>/dev/null | awk '{print $1}';
    else echo "UNKNOWN"; fi
  }

  MANIFEST=".genius/install-manifest.json"
  say "🧾 Genius Team — Install manifest verification"
  say "═══════════════════════════════════════════════════════════════"

  if [ ! -f "$MANIFEST" ]; then
    say -e "  ${RED}✗${NC} $MANIFEST not found — install via add.sh/create.sh to generate it"
    exit 1
  fi
  if ! jq . "$MANIFEST" >/dev/null 2>&1; then
    say -e "  ${RED}✗${NC} $MANIFEST is not valid JSON"
    exit 1
  fi

  M_MISSING=0
  M_MODIFIED=0
  M_TOTAL=0
  while IFS=$'\t' read -r path sha mutable; do
    [ -z "$path" ] && continue
    M_TOTAL=$((M_TOTAL + 1))
    if [ ! -f "$path" ]; then
      say -e "  ${RED}✗${NC} missing: $path"
      M_MISSING=$((M_MISSING + 1))
      continue
    fi
    actual="$(_sha256 "$path")"
    if [ "$actual" != "$sha" ]; then
      if [ "$mutable" = "true" ]; then
        say -e "  ${YELLOW}~${NC} changed (runtime state, expected): $path"
      else
        say -e "  ${RED}✗${NC} modified: $path"
        M_MODIFIED=$((M_MODIFIED + 1))
      fi
    else
      say -e "  ${GREEN}✓${NC} $path"
    fi
  done < <(jq -r '.files[] | [.path, .sha256, (.mutable // false | tostring)] | @tsv' "$MANIFEST")

  say ""
  GTV="$(jq -r '.gtVersion // "?"' "$MANIFEST")"
  INST="$(jq -r '.installedAt // "?"' "$MANIFEST")"
  ORI="$(jq -r '.origin // "?"' "$MANIFEST")"
  say "  Manifest: GT v${GTV} — installed ${INST} by ${ORI} — ${M_TOTAL} files tracked"
  say "═══════════════════════════════════════════════════════════════"
  if [ $((M_MISSING + M_MODIFIED)) -gt 0 ]; then
    say -e "${RED}❌ Manifest check failed: ${M_MISSING} missing, ${M_MODIFIED} modified (immutable).${NC}"
    exit 1
  fi
  say -e "${GREEN}✅ Manifest check passed — all tracked files present and unmodified.${NC}"
  exit 0
fi

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

# v23.0 Plugin mode check
say "🧩 Plugin mode (v23.0)..."
if [ -f ".genius/plugin-mode.json" ]; then
  say -e "  ${GREEN}✓${NC} .genius/plugin-mode.json present"
  if grep -q '"auto_trigger": true' .genius/plugin-mode.json 2>/dev/null; then
    say -e "  ${GREEN}✓${NC} auto_trigger enabled"
  fi
else
  say -e "  ${YELLOW}ℹ${NC} No plugin-mode.json (pre-v23 or legacy)"
fi
