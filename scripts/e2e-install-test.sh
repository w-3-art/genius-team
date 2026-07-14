#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Genius Team — Reproducible e2e install test (release gate v23)
#
# Installs GT into a clean, throwaway project from a simulated HOME,
# then proves the installed contract is real and usable:
#   • .genius/ complete (state.json, config.json, install-manifest.json)
#   • .claude/skills present + validate-skills.sh green IN THE TARGET
#   • hooks in .claude/settings.json are jq-parsable
#   • verify.sh --manifest green (P4-06 manifest matches the tree)
#   • optional headless smoke: `claude -p` answers without error
#     (only when the `claude` CLI exists AND E2E_WITH_CLAUDE=1)
#
# Everything runs in mktemp -d sandboxes that are always cleaned up.
# Exit 0 = all gates green, 1 = any gate failed.
#
# Usage:
#   bash scripts/e2e-install-test.sh                 # no claude smoke
#   E2E_WITH_CLAUDE=1 bash scripts/e2e-install-test.sh   # + headless smoke
# ═══════════════════════════════════════════════════════════════
set -uo pipefail

# ── Locate the GT source (this repo) ─────────────────────────
GT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Colors (degrade gracefully) ──────────────────────────────
if [ -t 1 ]; then
  GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
else
  GREEN=''; RED=''; YELLOW=''; BOLD=''; NC=''
fi

FAILS=0
pass() { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; FAILS=$((FAILS + 1)); }
info() { echo -e "  ${YELLOW}ℹ${NC} $1"; }

# ── Sandboxes + guaranteed cleanup ───────────────────────────
ORIG_HOME="${HOME:-}"
SANDBOX="$(mktemp -d)"
FAKE_HOME="$SANDBOX/home"
PROJECT="$SANDBOX/project"
mkdir -p "$FAKE_HOME" "$PROJECT"
cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT INT TERM

echo -e "${BOLD}🧪 Genius Team — e2e install test${NC}"
echo "═══════════════════════════════════════════════════════════════"
echo "  Source:  $GT_SRC"
echo "  Project: $PROJECT (throwaway)"
echo "  HOME:    $FAKE_HOME (simulated)"
echo ""

# ── 1. Seed a pristine project + install non-interactively ───
echo -e "${BOLD}1. Install into a clean project${NC}"
(
  cd "$PROJECT" || exit 1
  git init -q 2>/dev/null || true
  printf '# sample project\n' > README.md
)
ADD_LOG="$SANDBOX/add.log"
if ( cd "$PROJECT" && HOME="$FAKE_HOME" GENIUS_TEAM_SOURCE_DIR="$GT_SRC" \
      bash "$GT_SRC/scripts/add.sh" --mode cli --engine claude ) >"$ADD_LOG" 2>&1; then
  pass "add.sh completed (exit 0)"
else
  fail "add.sh failed — see log below"
  tail -30 "$ADD_LOG" | sed 's/^/      /'
fi
echo ""

# ── 2. .genius/ contract is complete ─────────────────────────
echo -e "${BOLD}2. .genius/ contract${NC}"
check_json() {
  local rel="$1" f="$PROJECT/$1"
  if [ ! -f "$f" ]; then
    fail "$rel missing"
  elif jq empty "$f" >/dev/null 2>&1; then
    pass "$rel present and valid JSON"
  else
    fail "$rel is not valid JSON"
  fi
}
check_json ".genius/state.json"
check_json ".genius/config.json"
check_json ".genius/install-manifest.json"   # P4-06
check_json ".genius/workflows.json"          # README workflow registry (from templates/)
echo ""

# ── 3. .claude/skills present ────────────────────────────────
echo -e "${BOLD}3. .claude/skills${NC}"
SKILLS_DIR="$PROJECT/.claude/skills"
if [ -d "$SKILLS_DIR" ] && [ "$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" -gt 0 ]; then
  pass ".claude/skills present ($(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ') skills)"
else
  fail ".claude/skills missing or empty"
fi
echo ""

# ── 4. validate-skills.sh green IN THE TARGET ────────────────
echo -e "${BOLD}4. validate-skills.sh (in target)${NC}"
VS_LOG="$SANDBOX/validate-skills.log"
if ( cd "$PROJECT" && bash scripts/validate-skills.sh ) >"$VS_LOG" 2>&1; then
  pass "validate-skills.sh green ($(grep -c '⚠️' "$VS_LOG" 2>/dev/null || echo 0) warnings)"
else
  fail "validate-skills.sh red"
  tail -15 "$VS_LOG" | sed 's/^/      /'
fi
echo ""

# ── 5. Hooks are jq-parsable ─────────────────────────────────
echo -e "${BOLD}5. Hooks parsable (jq)${NC}"
SETTINGS="$PROJECT/.claude/settings.json"
if [ ! -f "$SETTINGS" ]; then
  fail ".claude/settings.json missing"
elif ! jq empty "$SETTINGS" >/dev/null 2>&1; then
  fail ".claude/settings.json is not valid JSON"
elif jq -e '.hooks' "$SETTINGS" >/dev/null 2>&1; then
  # Every hook command must be a non-empty string
  BAD=$(jq -r '[.hooks // {} | to_entries[] | .value[]? | .hooks[]? | select(.type=="command") | .command | select(. == null or . == "")] | length' "$SETTINGS" 2>/dev/null || echo 1)
  if [ "$BAD" = "0" ]; then
    pass ".claude/settings.json hooks parse cleanly ($(jq -r '[.hooks // {} | to_entries[] | .value[]? | .hooks[]?] | length' "$SETTINGS") hook commands)"
  else
    fail "$BAD hook command(s) are empty/null"
  fi
else
  fail ".claude/settings.json has no .hooks object"
fi
echo ""

# ── 6. verify.sh --manifest green (P4-06) ────────────────────
echo -e "${BOLD}6. verify.sh --manifest${NC}"
VM_LOG="$SANDBOX/verify-manifest.log"
if ( cd "$PROJECT" && bash scripts/verify.sh --manifest ) >"$VM_LOG" 2>&1; then
  pass "verify.sh --manifest green"
else
  fail "verify.sh --manifest red"
  tail -15 "$VM_LOG" | sed 's/^/      /'
fi
echo ""

# ── 7. Optional headless smoke (claude CLI) ──────────────────
echo -e "${BOLD}7. Headless smoke (claude -p)${NC}"
if [ "${E2E_WITH_CLAUDE:-0}" != "1" ]; then
  info "skipped (set E2E_WITH_CLAUDE=1 to enable)"
elif ! command -v claude >/dev/null 2>&1; then
  info "skipped (claude CLI not found)"
else
  # Portable timeout: use timeout/gtimeout when available, else run directly.
  TIMEOUT_BIN=""
  if command -v timeout >/dev/null 2>&1; then TIMEOUT_BIN="timeout 180";
  elif command -v gtimeout >/dev/null 2>&1; then TIMEOUT_BIN="gtimeout 180"; fi
  SMOKE_LOG="$SANDBOX/smoke.log"
  info "running: claude -p \"quel est le statut du projet ?\" (HOME preserved for auth)"
  # Use the real HOME so the CLI can find credentials; cwd is the installed project.
  if ( cd "$PROJECT" && HOME="$ORIG_HOME" $TIMEOUT_BIN claude -p "quel est le statut du projet ?" ) >"$SMOKE_LOG" 2>&1; then
    RC=0
  else
    RC=$?
  fi
  if [ "$RC" = "0" ]; then
    pass "claude -p answered without error (rc=0)"
    head -3 "$SMOKE_LOG" | sed 's/^/      /'
  else
    fail "claude -p returned rc=$RC"
    tail -15 "$SMOKE_LOG" | sed 's/^/      /'
  fi
fi
echo ""

# ── Verdict ──────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
if [ "$FAILS" -gt 0 ]; then
  echo -e "${RED}❌ e2e install test FAILED — $FAILS gate(s) red.${NC}"
  exit 1
fi
echo -e "${GREEN}✅ e2e install test PASSED — install is complete and usable.${NC}"
exit 0
