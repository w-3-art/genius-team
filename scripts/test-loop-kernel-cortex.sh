#!/usr/bin/env bash
# test-loop-kernel-cortex.sh — LP-06 tests for the loop-kernel <-> Cortex
# control-plane integration, using a FAKE cortex CLI (mock).
#
# Verifies:
#   1. syntax: bash -n loop-kernel.sh
#   2. graceful degradation: cortex absent -> loop still runs, warning logged
#   3. registration: contract_validate calls `cortex loops --register` with JSON
#   4. heartbeat: brakes_check calls `cortex loops --heartbeat`; kill:false -> iterate
#   5. kill switch: heartbeat answering kill:true -> brakes_check exits 5,
#      STATE.md status becomes blocked, final report sent to cortex
#   6. loop_report sends the final verdict (`--report`)
#
# Run: bash scripts/test-loop-kernel-cortex.sh
# Hermetic: everything happens in a temp dir; the real cortex is never called.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
KERNEL="$SCRIPT_DIR/loop-kernel.sh"

failures=0
check() { # check <name> <cond-exit-code> [detail]
  if [ "$2" -eq 0 ]; then
    echo "  PASS  $1"
  else
    failures=$((failures + 1))
    echo "  FAIL  $1${3:+ — $3}"
  fi
}

TMP=$(mktemp -d "${TMPDIR:-/tmp}/loop-kernel-cortex-test-XXXXXX")
trap 'rm -rf "$TMP"' EXIT

# --- fixture: a valid loop contract ------------------------------------------
LOOP_DIR="$TMP/project/.genius/loops/demo-loop"
mkdir -p "$LOOP_DIR"
cat > "$LOOP_DIR/CONTRACT.md" <<'EOF'
# Loop Contract: demo loop

- slug: demo-loop
- created: 2026-07-03
- author: test
- autonomy_level: L2

## Goal (stopping condition)
The demo gate exits 0.

## Gate (objective pass/fail)
```bash
true
```
- Interpretation: PASS when exit code == 0.
- Timeout: 30s

## Proof of completion
Gate exit code 0.

## Blast radius (do-not-touch boundary)
- allowed_files:
  - src/**
- allowed_commands:
  - true

## Brakes (hard caps)
- max_iterations: 10
- token_budget: 100k
- no_progress_after: 5

## Checker (separate from maker)
genius-reviewer.

## State
- path: .genius/loops/demo-loop/STATE.md
EOF

# --- fixture: fake cortex CLI --------------------------------------------------
MOCK_DIR="$TMP/mock"
mkdir -p "$MOCK_DIR"
MOCK_LOG="$MOCK_DIR/calls.log"
KILL_FLAG="$MOCK_DIR/kill.flag"
cat > "$MOCK_DIR/cortex" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$MOCK_LOG"
case "\$*" in
  *--register*)  echo '{"ok":true,"id":"project/demo-loop","status":"running"}' ;;
  *--heartbeat*)
    if [ -f "$KILL_FLAG" ]; then
      echo '{"ok":true,"kill":true,"reason":"killed by test"}'
    else
      echo '{"ok":true,"kill":false}'
    fi ;;
  *--report*)    echo '{"ok":true,"id":"project/demo-loop","status":"halted"}' ;;
  *)             echo '{"ok":false,"error":"unexpected call"}'; exit 1 ;;
esac
EOF
chmod +x "$MOCK_DIR/cortex"

cd "$TMP/project"

# --- 1. syntax -----------------------------------------------------------------
echo ""
echo "1. syntax"
bash -n "$KERNEL"; check "bash -n loop-kernel.sh" $?

# --- 2. graceful degradation (no cortex) ---------------------------------------
echo ""
echo "2. graceful degradation without cortex"
out=$(CORTEX_BIN="$TMP/no-such-cortex" bash "$KERNEL" contract_validate "$LOOP_DIR" 2>&1); rc=$?
check "contract_validate passes without cortex" $rc "$out"
echo "$out" | grep -q "WARNING.*cortex"; check "warning logged when cortex is absent" $?

out=$(CORTEX_BIN="$TMP/no-such-cortex" bash "$KERNEL" brakes_check "$LOOP_DIR" 2>&1); rc=$?
check "brakes_check iterates without cortex (loop runs anyway)" $rc "$out"
echo "$out" | grep -q "OK: ITERATE"; check "brakes verdict is ITERATE" $?

out=$(CORTEX_BIN="$TMP/no-such-cortex" bash "$KERNEL" cortex_heartbeat "$LOOP_DIR" 2>&1); rc=$?
check "explicit cortex_heartbeat degrades to exit 0" $rc "$out"

# reset state produced during degradation checks
rm -f "$LOOP_DIR/STATE.md"

# --- 3. registration through the mock ------------------------------------------
echo ""
echo "3. registration (contract_validate -> cortex loops --register)"
: > "$MOCK_LOG"
out=$(CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" contract_validate "$LOOP_DIR" 2>&1); rc=$?
check "contract_validate passes with cortex up" $rc "$out"
grep -q -- "--register" "$MOCK_LOG"; check "register call sent to cortex" $?
grep -- "--register" "$MOCK_LOG" | grep -q '"repo":"project"'; check "register JSON carries the repo" $?
grep -- "--register" "$MOCK_LOG" | grep -q '"id":"project/demo-loop"'; check "register JSON carries id <repo>/<slug>" $?
grep -- "--register" "$MOCK_LOG" | grep -q '"autonomyLevel":"L2"'; check "register JSON carries autonomy level" $?

# --- 4. heartbeat, no kill --------------------------------------------------------
echo ""
echo "4. heartbeat without kill (brakes_check -> cortex loops --heartbeat)"
: > "$MOCK_LOG"
CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" state_write "$LOOP_DIR" in-progress 1 "gate failed" > /dev/null
out=$(CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" brakes_check "$LOOP_DIR" 2>&1); rc=$?
check "brakes_check iterates when heartbeat says kill:false" $rc "$out"
grep -q -- "--heartbeat" "$MOCK_LOG"; check "heartbeat call sent to cortex" $?
grep -- "--heartbeat" "$MOCK_LOG" | grep -q '"iteration":1'; check "heartbeat JSON carries the iteration" $?
grep -- "--heartbeat" "$MOCK_LOG" | grep -q '"gateVerdict":"fail"'; check "heartbeat JSON carries the gate verdict" $?

# --- 5. kill switch ---------------------------------------------------------------
echo ""
echo "5. kill:true -> clean stop (STATE written, report sent, exit 5)"
: > "$MOCK_LOG"
touch "$KILL_FLAG"
out=$(CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" brakes_check "$LOOP_DIR" 2>&1); rc=$?
[ $rc -eq 5 ]; check "brakes_check exits 5 on kill:true" $? "exit=$rc out=$out"
echo "$out" | grep -q "HALT: KILLED"; check "verdict announces the kill" $? "$out"
echo "$out" | grep -q "killed by test"; check "kill reason is surfaced" $? "$out"
grep -q "^- status: blocked" "$LOOP_DIR/STATE.md"; check "STATE.md status set to blocked" $?
grep -q "^- iteration: 1" "$LOOP_DIR/STATE.md"; check "STATE.md iteration untouched by the kill" $?
grep -q -- "--report" "$MOCK_LOG"; check "final report sent to cortex on kill" $?
grep -- "--report" "$MOCK_LOG" | grep -q '"status":"halted"'; check "kill reports status halted" $?
rm -f "$KILL_FLAG"

# --- 6. loop_report sends the final verdict ---------------------------------------
echo ""
echo "6. loop_report -> cortex loops --report"
: > "$MOCK_LOG"
CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" state_write "$LOOP_DIR" done 0 "gate passed" > /dev/null
out=$(CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" loop_report "$LOOP_DIR" 2>&1); rc=$?
check "loop_report succeeds" $rc "$out"
grep -q -- "--report" "$MOCK_LOG"; check "report call sent to cortex" $?
grep -- "--report" "$MOCK_LOG" | grep -q '"status":"completed"'; check "done state reports status completed" $?
grep -- "--report" "$MOCK_LOG" | grep -q '"verdict":"pass"'; check "report carries the gate verdict" $?

# --- 7. LP-07: token budget kill switch is fed real data --------------------------
echo ""
echo "7. LP-07 token estimate + cost accounting reach cortex"
# 7a. brakes_check <dir> <tokens> forwards tokenEstimate on the heartbeat
# (the heartbeat fires before any brake verdict, so the estimate reaches cortex
#  regardless of what brakes_check ultimately returns).
: > "$MOCK_LOG"
CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" state_write "$LOOP_DIR" in-progress 1 "gate failed" > /dev/null
CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" brakes_check "$LOOP_DIR" 150000 > /dev/null 2>&1 || true
grep -q -- "--heartbeat" "$MOCK_LOG"; check "brakes_check with a token estimate heartbeats cortex" $?
grep -- "--heartbeat" "$MOCK_LOG" | grep -q '"tokenEstimate":150000'; check "heartbeat JSON carries tokenEstimate (LP-07 kill switch fed)" $?
# 7b. a heartbeat WITHOUT a token arg stays backward-compatible (no tokenEstimate)
: > "$MOCK_LOG"
CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" brakes_check "$LOOP_DIR" > /dev/null 2>&1
grep -- "--heartbeat" "$MOCK_LOG" | grep -q 'tokenEstimate'; rc=$?
[ "$rc" -ne 0 ]; check "heartbeat omits tokenEstimate when no estimate is passed" $?
# 7c. loop_report <dir> <accepted> <tokensUsed> forwards LP-07 cost accounting
: > "$MOCK_LOG"
CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" state_write "$LOOP_DIR" done 0 "gate passed" > /dev/null
out=$(CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" loop_report "$LOOP_DIR" 3 175000 2>&1); rc=$?
check "loop_report accepts accepted + tokens_used" $rc "$out"
grep -- "--report" "$MOCK_LOG" | grep -q '"accepted":3'; check "report JSON carries accepted (cost-per-accepted-change)" $?
grep -- "--report" "$MOCK_LOG" | grep -q '"tokensUsed":175000'; check "report JSON carries tokensUsed" $?

# --- 8. terminal iteration is heartbeated (LP-07 attempts not under-counted) -------
echo ""
echo "8. done loop heartbeats the terminal iteration exactly once"
# brakes_check returns early on status=done; without a final heartbeat the terminal
# iteration count never reaches Cortex, under-counting attempts by 1 (can flip the
# losingMoney verdict at 0.5). The done branch now sends one idempotent heartbeat.
# Reset STATE so the iteration count is deterministic (0 -> 1 -> 2) for this section.
rm -f "$LOOP_DIR/STATE.md"
: > "$MOCK_LOG"
CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" state_write "$LOOP_DIR" in-progress 1 "iter1 fail" > /dev/null
CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" brakes_check "$LOOP_DIR" > /dev/null 2>&1
CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" state_write "$LOOP_DIR" done 0 "iter2 pass" > /dev/null
out=$(CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" brakes_check "$LOOP_DIR" 2>&1); rc=$?
[ "$rc" -eq 10 ]; check "brakes_check on done returns HALT: DONE (exit 10)" $? "exit=$rc"
echo "$out" | grep -q "HALT: DONE"; check "done verdict announced" $? "$out"
grep -- "--heartbeat" "$MOCK_LOG" | grep -q '"iteration":2'; check "terminal iteration (2) is heartbeated" $?
before=$(grep -c -- "--heartbeat" "$MOCK_LOG")
CORTEX_BIN="$MOCK_DIR/cortex" bash "$KERNEL" brakes_check "$LOOP_DIR" > /dev/null 2>&1
after=$(grep -c -- "--heartbeat" "$MOCK_LOG")
[ "$before" -eq "$after" ]; check "terminal heartbeat is idempotent (no duplicate on re-poll)" $? "before=$before after=$after"
grep -q "^- final_heartbeat: yes" "$LOOP_DIR/STATE.md"; check "STATE records the one-shot final_heartbeat flag" $?

# --- 9. LP-07: token_budget must PARSE, not merely be present ---------------------
echo ""
echo "9. contract_validate rejects an unparsable/non-positive token_budget"
# A present-but-unparsable budget ("abc") used to PASS contract_validate while
# Cortex's parseTokenBudget returned undefined and REFUSED to register the loop —
# the operator saw a green contract while the loop ran with NO control plane.
# contract_validate now mirrors Cortex's front-anchored numeric parse (positive
# number, optional k/M suffix) so the two agree.
TB_DIR="$TMP/project/.genius/loops/tb-loop"
mkdir -p "$TB_DIR"
write_tb_contract() { # write_tb_contract <token_budget-value>
  cat > "$TB_DIR/CONTRACT.md" <<EOF
# Loop Contract: tb loop

- slug: tb-loop
- autonomy_level: L2

## Goal (stopping condition)
The gate exits 0.

## Gate (objective pass/fail)
\`\`\`bash
true
\`\`\`

## Proof of completion
Gate exit code 0.

## Blast radius (do-not-touch boundary)
- allowed_files:
  - src/**

## Brakes (hard caps)
- max_iterations: 10
- token_budget: $1
- no_progress_after: 5

## Checker (separate from maker)
genius-reviewer.

## State
- path: .genius/loops/tb-loop/STATE.md
EOF
}
tb_expect() { # tb_expect <value> <PASS|FAIL>
  local want="$2" out rc
  write_tb_contract "$1"
  out=$(CORTEX_BIN="$TMP/no-such-cortex" bash "$KERNEL" contract_validate "$TB_DIR" 2>/dev/null); rc=$?
  if [ "$want" = "FAIL" ]; then
    { [ "$rc" -ne 0 ] && echo "$out" | grep -q "token_budget"; }
    check "token_budget '$1' -> FAIL (Cortex would refuse)" $? "rc=$rc out=$out"
  else
    [ "$rc" -eq 0 ]
    check "token_budget '$1' -> PASS" $? "rc=$rc out=$out"
  fi
}
# non-numeric (Cortex parseTokenBudget -> undefined -> registration refused)
tb_expect "abc" FAIL
tb_expect "-5" FAIL
tb_expect "." FAIL
tb_expect "abc # 200k" FAIL
# non-positive (zero budget the loop can never run under)
tb_expect "0" FAIL
tb_expect "0k" FAIL
# valid budgets (plain int, k/M suffix, decimal, with trailing inline comment)
tb_expect "100k" PASS
tb_expect "200000" PASS
tb_expect "1.5k" PASS
tb_expect "1M" PASS
tb_expect "500k   # REQUIRED — Cortex refuses a loop without it" PASS
rm -rf "$TB_DIR"

# --- result ------------------------------------------------------------------------
echo ""
if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) FAILED"
  exit 1
fi
echo "All loop-kernel <-> Cortex control-plane checks passed."
