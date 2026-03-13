#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Genius Team Autoresearch — AUTOMATED Benchmark Runner
# Tests skill routing by sending prompts to Claude Code --print
# and checking which skill gets triggered in the response.
#
# Usage: ./auto-benchmark.sh [--quick|--full]
# ═══════════════════════════════════════════════════════════════
set -e

MODE="${1:---quick}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULTS_DIR="autoresearch/experiments/benchmark-${TIMESTAMP}"
mkdir -p "$RESULTS_DIR"

TASKS_FILE="autoresearch/benchmarks/tasks.json"
if [ ! -f "$TASKS_FILE" ]; then
  echo "ERROR: $TASKS_FILE not found"
  exit 1
fi

if [ "$MODE" = "--quick" ]; then
  TASK_KEY="quick_test_tasks"
else
  TASK_KEY="tasks"
fi

TASK_COUNT=$(jq ".${TASK_KEY} | length" "$TASKS_FILE")
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  🔬 Automated Benchmark — ${TASK_COUNT} tasks (${MODE})        ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

CORRECT=0
WRONG=0
NO_SKILL=0
TOTAL=0

for i in $(seq 0 $((TASK_COUNT - 1))); do
  TASK_ID=$(jq -r ".${TASK_KEY}[$i].id" "$TASKS_FILE")
  PROMPT=$(jq -r ".${TASK_KEY}[$i].prompt" "$TASKS_FILE")
  EXPECTED=$(jq -r ".${TASK_KEY}[$i].expected_skill" "$TASKS_FILE")

  echo -n "[$TASK_ID] $(echo "$PROMPT" | head -c 60)... → expected: $EXPECTED "

  # Ask Claude which skill it would route to (dry-run, no execution)
  RESPONSE=$(cd /Users/benbot/genius-team && claude --print --permission-mode bypassPermissions \
    "You are the Genius Team router. Given this user request, which SINGLE skill would you route to? Reply with ONLY the skill name (e.g. genius-dev-frontend), nothing else.

User request: \"$PROMPT\"" 2>/dev/null | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

  # Normalize response
  RESPONSE=$(echo "$RESPONSE" | grep -oE 'genius-[a-z0-9][-a-z0-9]*[a-z0-9]' | head -1)

  # Accept genius-dev as valid dispatcher for any genius-dev-* sub-skill
  IS_DISPATCH=false
  if [ "$RESPONSE" = "genius-dev" ] && echo "$EXPECTED" | grep -qE '^genius-dev-(frontend|backend|mobile|database|api)$'; then
    IS_DISPATCH=true
  fi

  if [ "$RESPONSE" = "$EXPECTED" ] || [ "$IS_DISPATCH" = "true" ]; then
    if [ "$IS_DISPATCH" = "true" ]; then
      echo "✅ $RESPONSE (→ dispatches to $EXPECTED)"
    else
      echo "✅ $RESPONSE"
    fi
    CORRECT=$((CORRECT + 1))
    RESULT="correct"
  elif [ -z "$RESPONSE" ]; then
    echo "⚠️  no skill detected"
    NO_SKILL=$((NO_SKILL + 1))
    RESULT="no_skill"
    RESPONSE="none"
  else
    echo "❌ got: $RESPONSE"
    WRONG=$((WRONG + 1))
    RESULT="wrong"
  fi
  TOTAL=$((TOTAL + 1))

  # Log result
  echo "{\"task_id\":\"$TASK_ID\",\"expected\":\"$EXPECTED\",\"actual\":\"$RESPONSE\",\"result\":\"$RESULT\"}" >> "$RESULTS_DIR/raw.jsonl"
done

# Final report
echo ""
echo "═══════════════════════════════════════════════════════"
ACCURACY=$(echo "scale=1; $CORRECT * 100 / $TOTAL" | bc 2>/dev/null || echo "0")
echo "  ✅ Correct:    $CORRECT"
echo "  ❌ Wrong skill: $WRONG"
echo "  ⚠️  No skill:   $NO_SKILL"
echo "  📊 Accuracy:   ${ACCURACY}%"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Results: $RESULTS_DIR/raw.jsonl"

# Write summary
cat > "$RESULTS_DIR/summary.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "mode": "$MODE",
  "total": $TOTAL,
  "correct": $CORRECT,
  "wrong": $WRONG,
  "no_skill": $NO_SKILL,
  "accuracy": "$ACCURACY%"
}
EOF
