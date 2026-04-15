#!/bin/bash
#
# guard-validate.sh - Validate Genius Team v22 checkpoints and runtime artifacts
# Compatible with bash 3.2+ (macOS default)
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

find_project_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/.genius" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

PROJECT_ROOT=$(find_project_root) || {
  echo -e "${RED}ERROR: No .genius directory found. Run from a Genius Team project.${NC}" >&2
  exit 1
}

STATE_FILE="$PROJECT_ROOT/.genius/state.json"
OUTPUT_STATE="$PROJECT_ROOT/.genius/outputs/state.json"
SESSION_LOG="$PROJECT_ROOT/.genius/session-log.jsonl"
DASHBOARD_FILE="$PROJECT_ROOT/.genius/DASHBOARD.html"

if ! command -v jq >/dev/null 2>&1; then
  echo -e "${RED}ERROR: jq is required but not installed.${NC}" >&2
  exit 1
fi

if [[ ! -f "$STATE_FILE" ]]; then
  echo -e "${RED}ERROR: state.json not found at $STATE_FILE${NC}" >&2
  exit 1
fi

artifact_for_checkpoint() {
  case "$1" in
    discovery) echo "$PROJECT_ROOT/.genius/discovery/DISCOVERY.xml" ;;
    market_analysis) echo "$PROJECT_ROOT/.genius/discovery/MARKET-ANALYSIS.xml" ;;
    specs_approved) echo "$PROJECT_ROOT/.genius/discovery/SPECIFICATIONS.xml" ;;
    design_chosen) echo "$PROJECT_ROOT/.genius/outputs/design-playground.html" ;;
    marketing_done) echo "$PROJECT_ROOT/.genius/discovery/MARKETING-PLAN.xml" ;;
    integrations_done) echo "$PROJECT_ROOT/.genius/discovery/INTEGRATIONS.xml" ;;
    architecture_approved)
      if [[ -f "$PROJECT_ROOT/ARCHITECTURE.md" ]]; then
        echo "$PROJECT_ROOT/ARCHITECTURE.md"
      else
        echo "$PROJECT_ROOT/.genius/ARCHITECTURE.md"
      fi
      ;;
    execution_started)
      if [[ -f "$PROJECT_ROOT/.claude/plan.md" ]]; then
        echo "$PROJECT_ROOT/.claude/plan.md"
      else
        echo "$PROJECT_ROOT/.agents/plan.md"
      fi
      ;;
    qa_passed) echo "$PROJECT_ROOT/.genius/QA-REPORT.xml" ;;
    security_passed) echo "$PROJECT_ROOT/.genius/SECURITY-AUDIT.xml" ;;
    deployed) echo "$PROJECT_ROOT/.genius/DEPLOYMENT.md" ;;
    *) echo "" ;;
  esac
}

skill_for_checkpoint() {
  case "$1" in
    discovery) echo "genius-interviewer" ;;
    market_analysis) echo "genius-product-market-analyst" ;;
    specs_approved) echo "genius-specs" ;;
    design_chosen) echo "genius-designer" ;;
    marketing_done) echo "genius-marketer" ;;
    integrations_done) echo "genius-integration-guide" ;;
    architecture_approved) echo "genius-architect" ;;
    execution_started) echo "genius-orchestrator" ;;
    qa_passed) echo "genius-qa" ;;
    security_passed) echo "genius-security" ;;
    deployed) echo "genius-deployer" ;;
    *) echo "" ;;
  esac
}

CHECKPOINTS="discovery market_analysis specs_approved design_chosen marketing_done integrations_done architecture_approved execution_started qa_passed security_passed deployed"

PHASE=$(jq -r '.phase // "NOT_STARTED"' "$STATE_FILE")
CURRENT_SKILL=$(jq -r '.currentSkill // "null"' "$STATE_FILE")
[[ "$CURRENT_SKILL" == "null" ]] && CURRENT_SKILL=""

ERRORS=""
WARNINGS=""
CHECKPOINT_STATUS=""
ARTIFACT_STATUS=""

for checkpoint in $CHECKPOINTS; do
  validated=$(jq -r ".checkpoints.$checkpoint // false" "$STATE_FILE")
  artifact_path=$(artifact_for_checkpoint "$checkpoint")

  if [[ "$validated" == "true" ]]; then
    if [[ -n "$artifact_path" && -f "$artifact_path" ]]; then
      CHECKPOINT_STATUS="$CHECKPOINT_STATUS ${checkpoint}✓"
      ARTIFACT_STATUS="$ARTIFACT_STATUS
  ✓ ${artifact_path#$PROJECT_ROOT/}"
    else
      CHECKPOINT_STATUS="$CHECKPOINT_STATUS ${checkpoint}✗"
      ARTIFACT_STATUS="$ARTIFACT_STATUS
  ✗ ${artifact_path#$PROJECT_ROOT/} (missing)"
      ERRORS="$ERRORS
  ERROR: checkpoint '$checkpoint' is validated but its runtime artifact is missing"
    fi
  else
    if [[ -n "$artifact_path" && -f "$artifact_path" ]]; then
      CHECKPOINT_STATUS="$CHECKPOINT_STATUS ${checkpoint}⚠"
      ARTIFACT_STATUS="$ARTIFACT_STATUS
  ⚠ ${artifact_path#$PROJECT_ROOT/} (exists before checkpoint validation)"
      WARNINGS="$WARNINGS
  WARNING: artifact for '$checkpoint' exists but checkpoint is not validated"
    else
      CHECKPOINT_STATUS="$CHECKPOINT_STATUS ${checkpoint}⏳"
      ARTIFACT_STATUS="$ARTIFACT_STATUS
  ⏳ ${artifact_path#$PROJECT_ROOT/}"
    fi
  fi
done

if [[ ! -f "$OUTPUT_STATE" ]]; then
  WARNINGS="$WARNINGS
  WARNING: missing .genius/outputs/state.json"
fi

if [[ ! -f "$DASHBOARD_FILE" ]]; then
  WARNINGS="$WARNINGS
  WARNING: missing .genius/DASHBOARD.html"
fi

if [[ ! -f "$SESSION_LOG" ]]; then
  WARNINGS="$WARNINGS
  WARNING: missing .genius/session-log.jsonl"
fi

determine_next_action() {
  if [[ -n "$ERRORS" ]]; then
    echo "Fix missing runtime artifacts before continuing."
    return
  fi

  for checkpoint in $CHECKPOINTS; do
    validated=$(jq -r ".checkpoints.$checkpoint // false" "$STATE_FILE")
    if [[ "$validated" != "true" ]]; then
      echo "Continue with $(skill_for_checkpoint "$checkpoint") → generate $(artifact_for_checkpoint "$checkpoint" | sed "s|$PROJECT_ROOT/||")"
      return
    fi
  done

  echo "All checkpoints complete."
}

NEXT_ACTION=$(determine_next_action)

echo "<guard_status>"
echo "PHASE: $PHASE"
echo "CURRENT_SKILL: ${CURRENT_SKILL:-none}"
echo ""
echo "CHECKPOINTS:$CHECKPOINT_STATUS"
echo ""
echo "ARTIFACTS:$ARTIFACT_STATUS"
echo ""

if [[ -z "$ERRORS" && -z "$WARNINGS" ]]; then
  echo "ISSUES: none"
else
  echo "ISSUES:$ERRORS$WARNINGS"
fi

echo ""
echo "NEXT_ACTION: $NEXT_ACTION"
echo "</guard_status>"

if [[ -n "$ERRORS" || -n "$WARNINGS" ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${BLUE}RECOVERY SUGGESTIONS:${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  for checkpoint in $CHECKPOINTS; do
    validated=$(jq -r ".checkpoints.$checkpoint // false" "$STATE_FILE")
    artifact_path=$(artifact_for_checkpoint "$checkpoint")

    if [[ "$validated" == "true" && ! -f "$artifact_path" ]]; then
      echo ""
      echo -e "${YELLOW}Issue:${NC} Checkpoint '$checkpoint' is validated but its artifact is missing"
      echo -e "${GREEN}Fix:${NC} Re-run $(skill_for_checkpoint "$checkpoint") or clear the checkpoint in state.json"
    fi

    if [[ "$validated" != "true" && -f "$artifact_path" ]]; then
      echo ""
      echo -e "${YELLOW}Issue:${NC} Artifact exists before checkpoint '$checkpoint' is validated"
      echo -e "${GREEN}Fix:${NC} Validate the checkpoint if the artifact is correct, or regenerate the phase cleanly"
    fi
  done
fi

if [[ -n "$ERRORS" ]]; then
  exit 1
fi

exit 0
