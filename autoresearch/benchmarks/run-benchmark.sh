#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Genius Team Autoresearch — Benchmark Runner
# Usage: ./run-benchmark.sh <track> [--quick|--endurance]
# ═══════════════════════════════════════════════════════════════
set -e

TRACK="${1:?Usage: run-benchmark.sh <track-number> [--quick|--endurance]}"
MODE="${2:---quick}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULTS_DIR="autoresearch/experiments/track-${TRACK}"
mkdir -p "$RESULTS_DIR"

# Colors
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'; BOLD='\033[1m'

echo ""
echo -e "${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  🔬 Genius Team Autoresearch — Benchmark Runner      ║${NC}"
echo -e "${BOLD}║  Track: ${TRACK} | Mode: ${MODE}                              ║${NC}"
echo -e "${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# ── Load tasks ─────────────────────────────────────────────────
TASKS_FILE="autoresearch/benchmarks/tasks.json"
if [ ! -f "$TASKS_FILE" ]; then
  echo -e "${RED}ERROR: $TASKS_FILE not found${NC}"
  exit 1
fi

if [ "$MODE" = "--quick" ]; then
  TASK_COUNT=$(jq '.quick_test_tasks | length' "$TASKS_FILE")
  TASK_KEY="quick_test_tasks"
  echo -e "${BLUE}Running ${TASK_COUNT} quick test tasks...${NC}"
else
  TASK_COUNT=$(jq '.tasks | length' "$TASKS_FILE")
  TASK_KEY="tasks"
  echo -e "${BLUE}Running ${TASK_COUNT} endurance tasks (30-task sequence)...${NC}"
fi

# ── Results tracking ───────────────────────────────────────────
CORRECT=0
WRONG=0
NO_SKILL=0
TOTAL=0
RESULTS_FILE="${RESULTS_DIR}/${TIMESTAMP}-results.json"

echo '{"track": '$TRACK', "mode": "'$MODE'", "timestamp": "'$TIMESTAMP'", "results": []}' > "$RESULTS_FILE"

# ── Run each task ──────────────────────────────────────────────
for i in $(seq 0 $((TASK_COUNT - 1))); do
  TASK_ID=$(jq -r ".${TASK_KEY}[$i].id" "$TASKS_FILE")
  PROMPT=$(jq -r ".${TASK_KEY}[$i].prompt" "$TASKS_FILE")
  EXPECTED=$(jq -r ".${TASK_KEY}[$i].expected_skill" "$TASKS_FILE")

  echo ""
  echo -e "${BOLD}Task ${TASK_ID}:${NC} $PROMPT"
  echo -e "  Expected: ${BLUE}${EXPECTED}${NC}"

  # ── This is where the actual skill detection happens ──
  # For now: manual evaluation mode
  # TODO: Automate via Claude API or Claude Code --print mode
  echo -e "  ${YELLOW}Which skill was triggered?${NC}"
  echo -e "  1) ${EXPECTED} (correct)"
  echo -e "  2) Different skill (wrong)"
  echo -e "  3) No skill used (Claude went solo)"
  echo -e "  4) Skip"
  read -r -p "  > " ANSWER

  case $ANSWER in
    1)
      echo -e "  ${GREEN}✓ Correct${NC}"
      CORRECT=$((CORRECT + 1))
      RESULT="correct"
      ;;
    2)
      read -r -p "  Which skill was used instead? > " ACTUAL_SKILL
      echo -e "  ${RED}✗ Wrong: ${ACTUAL_SKILL}${NC}"
      WRONG=$((WRONG + 1))
      RESULT="wrong"
      ;;
    3)
      echo -e "  ${RED}✗ No skill triggered${NC}"
      NO_SKILL=$((NO_SKILL + 1))
      RESULT="no_skill"
      ;;
    4)
      echo -e "  ${YELLOW}— Skipped${NC}"
      RESULT="skipped"
      ;;
  esac
  TOTAL=$((TOTAL + 1))

  # Append to results JSON
  jq --arg id "$TASK_ID" --arg expected "$EXPECTED" --arg result "$RESULT" \
    '.results += [{"task_id": $id, "expected": $expected, "result": $result}]' \
    "$RESULTS_FILE" > "${RESULTS_FILE}.tmp" && mv "${RESULTS_FILE}.tmp" "$RESULTS_FILE"

  # Checkpoint reporting
  IS_CHECKPOINT=$(jq -r ".${TASK_KEY}[$i].checkpoint // false" "$TASKS_FILE")
  if [ "$IS_CHECKPOINT" = "true" ]; then
    CHECKPOINT_LABEL=$(jq -r ".${TASK_KEY}[$i].checkpoint_label" "$TASKS_FILE")
    ACCURACY=$(echo "scale=1; $CORRECT * 100 / $TOTAL" | bc)
    echo ""
    echo -e "  ${BOLD}📊 CHECKPOINT: ${CHECKPOINT_LABEL}${NC}"
    echo -e "  Accuracy so far: ${ACCURACY}% ($CORRECT/$TOTAL)"
    echo ""
  fi
done

# ── Final Report ───────────────────────────────────────────────
echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Final Results — Track ${TRACK}${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"

if [ $TOTAL -gt 0 ]; then
  ACCURACY=$(echo "scale=1; $CORRECT * 100 / $TOTAL" | bc)
  echo -e "  ✅ Correct:    ${GREEN}${CORRECT}${NC}"
  echo -e "  ❌ Wrong skill: ${RED}${WRONG}${NC}"
  echo -e "  ⚠️  No skill:   ${YELLOW}${NO_SKILL}${NC}"
  echo -e "  📊 Accuracy:   ${BOLD}${ACCURACY}%${NC}"
else
  echo -e "  No tasks evaluated."
fi

# Save final metrics
jq --arg acc "$ACCURACY" --arg correct "$CORRECT" --arg wrong "$WRONG" \
   --arg no_skill "$NO_SKILL" --arg total "$TOTAL" \
  '. + {"accuracy": ($acc + "%"), "correct": ($correct|tonumber), "wrong": ($wrong|tonumber), "no_skill": ($no_skill|tonumber), "total": ($total|tonumber)}' \
  "$RESULTS_FILE" > "${RESULTS_FILE}.tmp" && mv "${RESULTS_FILE}.tmp" "$RESULTS_FILE"

echo ""
echo -e "  Results saved: ${BLUE}${RESULTS_FILE}${NC}"
echo ""
