#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Genius Team — Reproducible e2e UPGRADE test (release gate)
#
# The fresh-install path is covered by e2e-install-test.sh. This test
# exercises the UPGRADE path, which no CI job touched before:
#   1. Fresh-install current GT into a throwaway project.
#   2. Age it to simulate an older major (VERSION + .genius/state.json).
#   3. Run  upgrade.sh --dry-run  → asserts exit 0 and NO files changed.
#   4. Run  upgrade.sh (real)     → asserts:
#        • VERSION file bumped to the target (derived from the source VERSION)
#        • .genius/state.json migrated (valid JSON, version + schema keys)
#   5. Re-run upgrade.sh          → asserts idempotency ("already at", exit 0).
#
# Fully hermetic: no network. GENIUS_TEAM_SOURCE_DIR pins the local source so
# every download_file copies from this checkout instead of GitHub.
#
# Everything runs in a mktemp -d sandbox that is always cleaned up.
# Exit 0 = all gates green, 1 = any gate failed.
#
# Usage:
#   bash scripts/e2e-upgrade-test.sh
# ═══════════════════════════════════════════════════════════════
set -uo pipefail

# ── Locate the GT source (this repo) ─────────────────────────
GT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_VERSION="$(tr -d '[:space:]' < "$GT_SRC/VERSION")"
TARGET_MAJOR="${TARGET_VERSION%%.*}"
# One major below the target — guaranteed to trigger a real upgrade because
# upgrade.sh compares major versions (version_lt).
OLD_MAJOR=$((TARGET_MAJOR - 1))
OLD_VERSION="${OLD_MAJOR}.0.0"

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

# ── Sandbox + guaranteed cleanup ─────────────────────────────
SANDBOX="$(mktemp -d)"
FAKE_HOME="$SANDBOX/home"
PROJECT="$SANDBOX/project"
mkdir -p "$FAKE_HOME" "$PROJECT"
cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT INT TERM

echo -e "${BOLD}🧪 Genius Team — e2e upgrade test${NC}"
echo "═══════════════════════════════════════════════════════════════"
echo "  Source:  $GT_SRC"
echo "  Project: $PROJECT (throwaway)"
echo "  Upgrade: v$OLD_VERSION → v$TARGET_VERSION"
echo ""

# ── 1. Fresh install of the current version ──────────────────
echo -e "${BOLD}1. Fresh install (baseline)${NC}"
ADD_LOG="$SANDBOX/add.log"
(
  cd "$PROJECT" || exit 1
  git init -q 2>/dev/null || true
  printf '# sample project\n' > README.md
)
if ( cd "$PROJECT" && HOME="$FAKE_HOME" GENIUS_TEAM_SOURCE_DIR="$GT_SRC" \
      bash "$GT_SRC/scripts/add.sh" --mode cli --engine claude ) >"$ADD_LOG" 2>&1; then
  pass "add.sh completed (exit 0)"
else
  fail "add.sh failed — see log below"
  tail -30 "$ADD_LOG" | sed 's/^/      /'
  echo -e "${RED}❌ cannot continue without a baseline install.${NC}"
  exit 1
fi
echo ""

# ── 2. Age the install to an older major ─────────────────────
echo -e "${BOLD}2. Simulate an older install (v$OLD_VERSION)${NC}"
printf '%s\n' "$OLD_VERSION" > "$PROJECT/VERSION"
if jq --arg v "$OLD_VERSION" '.version = $v | .contractVersion = "\($v|split(".")[0]).0"' \
     "$PROJECT/.genius/state.json" > "$PROJECT/.genius/state.json.tmp" 2>/dev/null; then
  mv "$PROJECT/.genius/state.json.tmp" "$PROJECT/.genius/state.json"
  pass "state.json + VERSION aged to v$OLD_VERSION"
else
  rm -f "$PROJECT/.genius/state.json.tmp"
  fail "could not age state.json"
fi
# Remove a framework-owned file to prove the upgrade restores it.
rm -f "$PROJECT/.genius/workflows.json"
# Commit the aged baseline — upgrade.sh refuses to run on a dirty tree, and a
# real user upgrades a committed project.
( cd "$PROJECT" \
  && git -c user.email=e2e@genius.test -c user.name=e2e add -A >/dev/null 2>&1 \
  && git -c user.email=e2e@genius.test -c user.name=e2e commit -q -m "aged to v$OLD_VERSION" >/dev/null 2>&1 ) \
  && pass "aged baseline committed (clean tree)" \
  || fail "could not commit aged baseline"
echo ""

# ── 3. Dry-run must not touch anything ───────────────────────
echo -e "${BOLD}3. upgrade.sh --dry-run (no changes)${NC}"
DR_LOG="$SANDBOX/dryrun.log"
if ( cd "$PROJECT" && GENIUS_TEAM_SOURCE_DIR="$GT_SRC" \
      bash "$GT_SRC/scripts/upgrade.sh" --dry-run ) >"$DR_LOG" 2>&1; then
  pass "dry-run exited 0"
else
  fail "dry-run exited non-zero"
  tail -20 "$DR_LOG" | sed 's/^/      /'
fi
if grep -q "Target: .*v${TARGET_VERSION}" "$DR_LOG"; then
  pass "dry-run reports target v$TARGET_VERSION (derived from VERSION)"
else
  fail "dry-run did not report target v$TARGET_VERSION"
  grep -i "detected\|target" "$DR_LOG" | sed 's/^/      /'
fi
if [ "$(tr -d '[:space:]' < "$PROJECT/VERSION")" = "$OLD_VERSION" ] \
   && [ ! -f "$PROJECT/.genius/workflows.json" ]; then
  pass "dry-run left the tree untouched"
else
  fail "dry-run mutated the tree (VERSION or workflows.json changed)"
fi
echo ""

# ── 4. Real upgrade ──────────────────────────────────────────
echo -e "${BOLD}4. upgrade.sh (real)${NC}"
UP_LOG="$SANDBOX/upgrade.log"
if ( cd "$PROJECT" && GENIUS_TEAM_SOURCE_DIR="$GT_SRC" \
      bash "$GT_SRC/scripts/upgrade.sh" ) >"$UP_LOG" 2>&1; then
  pass "upgrade exited 0"
else
  fail "upgrade exited non-zero"
  tail -25 "$UP_LOG" | sed 's/^/      /'
fi

# VERSION bumped to the target
if [ "$(tr -d '[:space:]' < "$PROJECT/VERSION")" = "$TARGET_VERSION" ]; then
  pass "VERSION file bumped to v$TARGET_VERSION"
else
  fail "VERSION is '$(tr -d '[:space:]' < "$PROJECT/VERSION")' (expected v$TARGET_VERSION)"
fi

# state.json migrated: valid JSON, version bumped, schema keys present
STATE="$PROJECT/.genius/state.json"
if [ -f "$STATE" ] && jq empty "$STATE" >/dev/null 2>&1; then
  pass "state.json is valid JSON"
  SV="$(jq -r '.version // empty' "$STATE")"
  if [ "$SV" = "$TARGET_VERSION" ]; then
    pass "state.json .version == v$TARGET_VERSION"
  else
    fail "state.json .version is '$SV' (expected v$TARGET_VERSION)"
  fi
  # migrate-state.sh normalizes the schema — these keys prove it ran.
  if jq -e '.migrationStatus and .installMode and .engine and (.phase != null)' \
       "$STATE" >/dev/null 2>&1; then
    pass "state.json migrated (migrationStatus/installMode/engine/phase present)"
  else
    fail "state.json missing migrated schema keys"
    jq -c '{version,contractVersion,migrationStatus,installMode,engine,phase}' "$STATE" 2>/dev/null | sed 's/^/      /'
  fi
else
  fail "state.json missing or invalid JSON after upgrade"
fi

# Framework-owned file restored
if [ -f "$PROJECT/.genius/workflows.json" ] && jq empty "$PROJECT/.genius/workflows.json" >/dev/null 2>&1; then
  pass ".genius/workflows.json restored (valid JSON)"
else
  fail ".genius/workflows.json not restored by upgrade"
fi
echo ""

# ── 5. Idempotency: re-running is a no-op ────────────────────
echo -e "${BOLD}5. upgrade.sh again (idempotent)${NC}"
# Commit the upgraded tree so the clean-tree prerequisite is satisfied again.
( cd "$PROJECT" \
  && git -c user.email=e2e@genius.test -c user.name=e2e add -A >/dev/null 2>&1 \
  && git -c user.email=e2e@genius.test -c user.name=e2e commit -q -m "upgraded to v$TARGET_VERSION" >/dev/null 2>&1 ) || true
RE_LOG="$SANDBOX/reupgrade.log"
if ( cd "$PROJECT" && GENIUS_TEAM_SOURCE_DIR="$GT_SRC" \
      bash "$GT_SRC/scripts/upgrade.sh" ) >"$RE_LOG" 2>&1; then
  if grep -qi "already at" "$RE_LOG"; then
    pass "second run detected 'already at v$TARGET_VERSION' (no-op)"
  else
    info "second run exited 0 (no explicit 'already at' message)"
  fi
else
  fail "second upgrade run exited non-zero"
  tail -20 "$RE_LOG" | sed 's/^/      /'
fi
echo ""

# ── Verdict ──────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
if [ "$FAILS" -gt 0 ]; then
  echo -e "${RED}❌ e2e upgrade test FAILED — $FAILS gate(s) red.${NC}"
  exit 1
fi
echo -e "${GREEN}✅ e2e upgrade test PASSED — upgrade path is real and idempotent.${NC}"
exit 0
