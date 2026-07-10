#!/usr/bin/env bash
# test-guard-boundary.sh — PUSH/PUBLISH boundary detection regression test.
# -----------------------------------------------------------------------------
# Policy source: decisions/GUARD-POLICY.md §4 (frontière push/publish) + §5.1
# (command-position anchoring — a boundary keyword inside a string/comment/arg
# must NOT fire). Companion to test-guard-no-leak.sh (which covers redaction).
#
# It exercises the REAL hook (scripts/genius-guard-boundary.sh) with phase
# NOT_STARTED and asserts three things at once:
#   1. Canonical push/publish/deploy forms are DENIED (unchanged coverage).
#   2. Real-world prefixed forms are DENIED, not bypassed — env-var assignments,
#      an absolute path on the binary, and flags before the subcommand. These are
#      genuine irreversible pushes; a prefix must not smuggle one past the guard.
#   3. Benign lookalikes still PASS — the same keyword inside an echo/string/
#      comment/other-subcommand must not be over-blocked (zero false positives).
#
# Run: bash scripts/test-guard-boundary.sh
# Hermetic: a temp project dir with phase=NOT_STARTED; the real .genius is untouched.
# -----------------------------------------------------------------------------
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
HOOK="$SCRIPT_DIR/genius-guard-boundary.sh"

command -v jq >/dev/null 2>&1 || { echo "SKIP: jq not installed"; exit 0; }
[ -f "$HOOK" ] || { echo "FAIL: hook not found at $HOOK"; exit 1; }

TMP=$(mktemp -d "${TMPDIR:-/tmp}/guard-boundary-test-XXXXXX")
trap 'rm -rf "$TMP"' EXIT
cd "$TMP" || exit 1
mkdir -p .genius
printf '{"phase":"NOT_STARTED"}\n' > .genius/state.json

failures=0

run_hook() { # run_hook <command-string> -> prints hook stdout
  printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$(jq -Rn --arg c "$1" '$c')" \
    | bash "$HOOK" 2>/dev/null
}

expect_deny() { # expect_deny <command>
  if run_hook "$1" | grep -q '"permissionDecision":"deny"'; then
    echo "  PASS  DENY  $1"
  else
    failures=$((failures + 1))
    echo "  FAIL  expected DENY, got PASS  →  $1"
  fi
}

expect_pass() { # expect_pass <command>
  if run_hook "$1" | grep -q '"permissionDecision":"deny"'; then
    failures=$((failures + 1))
    echo "  FAIL  expected PASS, got DENY  →  $1"
  else
    echo "  PASS  PASS  $1"
  fi
}

echo ""
echo "1. Canonical push/publish/deploy forms are denied"
expect_deny "git push"
expect_deny "git push origin main"
expect_deny "npm publish"
expect_deny "pnpm publish"
expect_deny "yarn publish"
expect_deny "npx some-tool publish"
expect_deny "vercel deploy"
expect_deny "railway up"
expect_deny "gh release create v1.0.0"
expect_deny "docker push registry/img:tag"
expect_deny "supabase db push"
expect_deny "eas submit"

echo ""
echo "2. Real, prefixed push/publish forms are denied (no bypass)"
expect_deny 'GIT_SSH_COMMAND="ssh -i k" git push origin main'
expect_deny "HUSKY=0 git push"
expect_deny "FOO=1 BAR=2 git push"
expect_deny "NODE_ENV=production npm publish"
expect_deny "git -C repo push origin main"
expect_deny "/usr/bin/git push"
expect_deny "/opt/homebrew/bin/npm publish"
expect_deny "yarn --cwd . publish"
expect_deny "npm --registry https://r.example.com publish"

echo ""
echo "3. Benign lookalikes still pass (zero over-blocking)"
expect_pass "git status"
expect_pass "git log --oneline"
expect_pass "git commit -m 'ready to push'"
expect_pass "git commit -am 'push feature'"
expect_pass "npm install"
expect_pass "npm run build"
expect_pass "docker build ."
expect_pass "echo git push"
expect_pass "echo 'run: git push origin main to deploy'"
expect_pass "# git push later"

echo ""
if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) FAILED"
  exit 1
fi
echo "All guard-boundary checks passed."
