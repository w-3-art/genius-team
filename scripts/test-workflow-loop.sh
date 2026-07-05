#!/usr/bin/env bash
# test-workflow-loop.sh — LP-09 dry-run simulation + tests for the workflow
# loop (product pipeline as ONE self-advancing loop on loop-kernel.sh).
#
# Verifies:
#   1. syntax: bash -n loop-kernel.sh
#   2. contract_validate accepts a ## Workflow table (and graceful degradation:
#      no cortex CLI -> warning on stderr, loop still runs — LP-06 reuse)
#   3. contract_validate REFUSES a bad workflow (checkpoint typo, placeholder gate)
#   4. auto step whose gate passes -> ADVANCE to the next step (L3)
#   5. step whose gate fails -> exit 1, loop stays on the step; fix -> ADVANCE
#   6. human checkpoint (L3 boundary, e.g. before deploy): gate passes -> HALT
#      exit 12, STATE blocked + awaiting checkpoint:<step>
#   7. workflow_approve (human) -> resume, ADVANCE past the checkpoint
#   8. final step + approval -> WORKFLOW DONE, STATE done, brakes_check exits 10
#   9. autonomy L1/L2: EVERY step is a human checkpoint (no silent auto-advance)
#
# Run: bash scripts/test-workflow-loop.sh
# Hermetic: everything happens in a temp dir; cortex is forced unreachable.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
KERNEL="$SCRIPT_DIR/loop-kernel.sh"

# Force graceful-degradation path: cortex CLI unreachable (LP-06).
export CORTEX_BIN="definitely-not-a-real-cortex-binary"

failures=0
check() { # check <name> <cond-exit-code> [detail]
  if [ "$2" -eq 0 ]; then
    echo "  PASS  $1"
  else
    failures=$((failures + 1))
    echo "  FAIL  $1${3:+ — $3}"
  fi
}

TMP=$(mktemp -d "${TMPDIR:-/tmp}/workflow-loop-test-XXXXXX")
trap 'rm -rf "$TMP"' EXIT

# --- fixture: an L3 pipeline contract (4 steps, human checkpoint = review) ----
PROJECT="$TMP/project"
LOOP_DIR="$PROJECT/.genius/loops/pipeline-demo"
mkdir -p "$LOOP_DIR"
cd "$PROJECT" || exit 1
git init -q . 2>/dev/null || true

write_contract() { # write_contract <level>
  cat > "$LOOP_DIR/CONTRACT.md" <<EOF
# Loop Contract: pipeline demo

- slug: pipeline-demo
- created: 2026-07-05
- author: test
- autonomy_level: $1

## Goal (stopping condition)
All workflow steps pass their gates with human checkpoints approved.

## Gate (objective pass/fail)
\`\`\`bash
true
\`\`\`
- Interpretation: PASS when exit code == 0.
- Timeout: 30s

## Workflow (step gates)
| step | gate | checkpoint |
|---|---|---|
| interview | true | auto |
| dev | test -f dev-done.marker | auto |
| review | true | human |
| deploy | true | human |

## Proof of completion
STATE.md status done, approvals recorded.

## Blast radius (do-not-touch boundary)
- allowed_files:
  - dev-done.marker
  - .genius/loops/pipeline-demo/**
- allowed_commands:
  - true
  - test

## Brakes (hard caps)
- max_iterations: 20
- token_budget: 100k
- no_progress_after: 5
- flip_flop: HALT on oscillation

## Checker (separate from maker)
Read-only reviewer, never the maker.

## State
- path: .genius/loops/pipeline-demo/STATE.md
- protocol: read at start, write at end

## Budget
- max_wall_time: 10m
- max_iterations: 20
EOF
}

echo "== 1. kernel syntax =="
bash -n "$KERNEL"; check "bash -n loop-kernel.sh" $?

echo "== 2. contract_validate + graceful degradation (no cortex) =="
write_contract L3
OUT=$(bash "$KERNEL" contract_validate "$LOOP_DIR" 2>&1); rc=$?
check "contract_validate PASS on workflow contract" $rc "$OUT"
echo "$OUT" | grep -q "WARNING: cortex CLI not reachable"
check "graceful degradation warning logged (LP-06)" $?

echo "== 3. contract_validate refuses a bad workflow =="
BAD_DIR="$TMP/project/.genius/loops/bad-pipeline"
mkdir -p "$BAD_DIR"
sed -e 's/| review | true | human |/| review | true | sometimes |/' \
    -e 's/| deploy | true | human |/| deploy | <fill-me> | human |/' \
    "$LOOP_DIR/CONTRACT.md" > "$BAD_DIR/CONTRACT.md"
OUT=$(bash "$KERNEL" contract_validate "$BAD_DIR" 2>&1); rc=$?
[ $rc -ne 0 ]; check "bad workflow contract refused" $?
echo "$OUT" | grep -q "checkpoint must be auto|human"
check "bad checkpoint value reported" $?
echo "$OUT" | grep -q "unfilled placeholder"
check "placeholder gate reported" $?

echo ""
echo "== DRY-RUN SIMULATION (autonomy L3) =="
echo "-- transition 1: interview (auto, gate passes) --"
OUT=$(bash "$KERNEL" workflow_advance "$LOOP_DIR" 2>/dev/null); rc=$?
echo "   $OUT"
[ $rc -eq 0 ] && echo "$OUT" | grep -q "ADVANCE: interview → dev"
check "interview auto-advances to dev" $?

echo "-- transition 2: dev gate FAILS (marker missing) --"
OUT=$(bash "$KERNEL" workflow_advance "$LOOP_DIR" 2>/dev/null); rc=$?
echo "   $OUT"
[ $rc -eq 1 ] && echo "$OUT" | grep -q "STEP GATE FAIL: step 'dev'"
check "failing dev gate -> exit 1, stay on step" $?
[ "$(bash "$KERNEL" state_get "$LOOP_DIR" step)" = "dev" ]
check "STATE still on step dev" $?

echo "-- transition 3: dev fixed (marker created) -> gate passes --"
touch dev-done.marker
OUT=$(bash "$KERNEL" workflow_advance "$LOOP_DIR" 2>/dev/null); rc=$?
echo "   $OUT"
[ $rc -eq 0 ] && echo "$OUT" | grep -q "ADVANCE: dev → review"
check "fixed dev gate -> ADVANCE to review" $?

echo "-- transition 4: review passes -> HALT at L3 human checkpoint (before deploy) --"
OUT=$(bash "$KERNEL" workflow_advance "$LOOP_DIR" 2>/dev/null); rc=$?
echo "   $OUT"
[ $rc -eq 12 ]; check "human checkpoint -> clean HALT (exit 12)" $?
[ "$(bash "$KERNEL" state_get "$LOOP_DIR" status)" = "blocked" ]
check "STATE status blocked at checkpoint" $?
[ "$(bash "$KERNEL" state_get "$LOOP_DIR" awaiting)" = "checkpoint:review" ]
check "STATE awaiting checkpoint:review" $?

echo "-- re-advance WITHOUT approval: still halted --"
OUT=$(bash "$KERNEL" workflow_advance "$LOOP_DIR" 2>/dev/null); rc=$?
echo "   $OUT"
[ $rc -eq 12 ]; check "checkpoint not bypassable without approval" $?

echo "-- human approves review -> resume --"
bash "$KERNEL" workflow_approve "$LOOP_DIR" review >/dev/null
[ -f "$LOOP_DIR/approvals/review" ]
check "traceable approval file recorded" $?
OUT=$(bash "$KERNEL" workflow_advance "$LOOP_DIR" 2>/dev/null); rc=$?
echo "   $OUT"
[ $rc -eq 0 ] && echo "$OUT" | grep -q "CHECKPOINT APPROVED: review → step deploy"
check "approved checkpoint -> ADVANCE to deploy" $?

echo "-- transition 5: deploy passes -> HALT at final human checkpoint (before push) --"
OUT=$(bash "$KERNEL" workflow_advance "$LOOP_DIR" 2>/dev/null); rc=$?
echo "   $OUT"
[ $rc -eq 12 ]; check "final human checkpoint HALTs (before push)" $?
bash "$KERNEL" workflow_approve "$LOOP_DIR" deploy >/dev/null
OUT=$(bash "$KERNEL" workflow_advance "$LOOP_DIR" 2>/dev/null); rc=$?
echo "   $OUT"
[ $rc -eq 0 ] && echo "$OUT" | grep -q "WORKFLOW DONE"
check "approved final step -> WORKFLOW DONE" $?
[ "$(bash "$KERNEL" state_get "$LOOP_DIR" status)" = "done" ]
check "STATE status done" $?
bash "$KERNEL" brakes_check "$LOOP_DIR" >/dev/null 2>&1; rc=$?
[ $rc -eq 10 ]; check "brakes_check reports DONE (exit 10)" $?

echo ""
echo "== 9. autonomy L1/L2: every step is a human checkpoint =="
L2_DIR="$PROJECT/.genius/loops/pipeline-l2"
mkdir -p "$L2_DIR"
sed 's/autonomy_level: L3/autonomy_level: L2/' "$LOOP_DIR/CONTRACT.md" > "$L2_DIR/CONTRACT.md"
OUT=$(bash "$KERNEL" workflow_advance "$L2_DIR" 2>/dev/null); rc=$?
echo "   $OUT"
[ $rc -eq 12 ] && echo "$OUT" | grep -q "step 'interview'"
check "at L2 even an auto step HALTs for approval" $?

echo ""
echo "== 10. gate timeout fallback (no timeout/gtimeout binary) returns promptly =="
# Regression guard for the _exec_gate fallback branch: on hosts without GNU
# timeout/gtimeout (stock macOS), a passing gate captured via $(...) command
# substitution — the kernel's documented calling convention — MUST return as
# soon as the gate finishes, NOT block for the full contract Timeout. To exercise
# this branch on ANY host (CI ubuntu ships GNU timeout), a BASH_ENV shim shadows
# the `command -v timeout/gtimeout` probe so the fallback path is always taken.
FB_ENV="$TMP/force-fallback.bashenv"
cat > "$FB_ENV" <<'SHIM'
command() {
  if [ "${1:-}" = "-v" ]; then
    case "${2:-}" in timeout|gtimeout) return 1 ;; esac
  fi
  builtin command "$@"
}
SHIM
FB_DIR="$PROJECT/.genius/loops/fallback-demo"
mkdir -p "$FB_DIR"
# Small (5s) Timeout so a regression stalls for 5s, not 30s, before the assert trips.
cat > "$FB_DIR/CONTRACT.md" <<'EOF'
# Loop Contract: fallback demo
- slug: fallback-demo
## Gate (objective pass/fail)
```bash
true
```
- Interpretation: PASS when exit code == 0.
- Timeout: 5s
EOF
# sanity: the shim really hides timeout/gtimeout (else the assert is vacuous)
BASH_ENV="$FB_ENV" bash -c 'command -v timeout >/dev/null 2>&1' && hid=1 || hid=0
[ "$hid" -eq 0 ]; check "BASH_ENV shim hides timeout (fallback branch is forced)" $?
fb_start=$(date +%s)
OUT=$(BASH_ENV="$FB_ENV" bash "$KERNEL" gate_run "$FB_DIR" 2>&1); rc=$?
fb_elapsed=$(( $(date +%s) - fb_start ))
[ $rc -eq 0 ]; check "passing gate exits 0 via no-timeout fallback" $? "rc=$rc out=$OUT"
[ "$fb_elapsed" -lt 2 ]; check "fallback returns in <2s (not the 5s Timeout)" $? "elapsed=${fb_elapsed}s"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$failures" -eq 0 ]; then
  echo "✅ workflow-loop: ALL TESTS PASSED"
  exit 0
else
  echo "❌ workflow-loop: $failures test(s) FAILED"
  exit 1
fi
