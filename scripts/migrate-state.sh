#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/contract.sh"

STATE=".genius/state.json"
OUTPUT_STATE=".genius/outputs/state.json"
MODE_FILE=".genius/mode.json"
CONFIG_FILE=".genius/config.json"
IMPORT_MODE=false
ORIGIN=""
INSTALL_MODE=""
ENGINE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --import|--imported)
      IMPORT_MODE=true
      ORIGIN="imported"
      shift
      ;;
    --native)
      ORIGIN="native"
      shift
      ;;
    --install-mode)
      INSTALL_MODE="$2"
      shift 2
      ;;
    --engine)
      ENGINE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

mkdir -p .genius/outputs .genius/memory

detect_install_mode() {
  if [ -n "$INSTALL_MODE" ]; then
    echo "$INSTALL_MODE"
  elif [ -f "$CONFIG_FILE" ]; then
    jq -r '.installMode // .mode // "cli"' "$CONFIG_FILE" 2>/dev/null || echo "cli"
  else
    echo "cli"
  fi
}

detect_engine() {
  if [ -n "$ENGINE" ]; then
    echo "$ENGINE"
  elif [ -f "$CONFIG_FILE" ]; then
    jq -r '.engine // "claude"' "$CONFIG_FILE" 2>/dev/null || echo "claude"
  else
    echo "claude"
  fi
}

detect_experience_mode() {
  if [ -f "$MODE_FILE" ]; then
    jq -r '.mode // "builder"' "$MODE_FILE" 2>/dev/null || echo "builder"
  else
    echo "builder"
  fi
}

detect_origin() {
  if [ -n "$ORIGIN" ]; then
    echo "$ORIGIN"
  elif [ -f "$STATE" ]; then
    jq -r '.origin // "upgraded"' "$STATE" 2>/dev/null || echo "upgraded"
  else
    echo "upgraded"
  fi
}

find_artifact_path() {
  local name="$1"
  for candidate in \
    "$name" \
    ".genius/discovery/$name" \
    ".genius/outputs/$name" \
    ".genius/$name"
  do
    if [ -f "$candidate" ]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

artifact_value_or_null() {
  local artifact
  artifact="$(find_artifact_path "$1" || true)"
  if [ -n "$artifact" ]; then
    printf '%s' "$artifact"
  else
    printf ''
  fi
}

EXPERIENCE_MODE="$(detect_experience_mode)"
INSTALL_MODE="$(detect_install_mode)"
ENGINE="$(detect_engine)"
ORIGIN="$(detect_origin)"

PHASE="NOT_STARTED"
CURRENT_SKILL="null"
CURRENT_WORKFLOW="null"
BOOTSTRAP_STATUS="not_run"
MIGRATION_STATUS="native-v22"
CORTEX_READY="false"

if [ "$IMPORT_MODE" = true ]; then
  MIGRATION_STATUS="pending-cortex-ready"
fi

DISCOVERY_PATH="$(artifact_value_or_null "DISCOVERY.xml")"
MARKET_PATH="$(artifact_value_or_null "MARKET-ANALYSIS.xml")"
SPECS_PATH="$(artifact_value_or_null "SPECIFICATIONS.xml")"
DESIGN_HTML_PATH="$(artifact_value_or_null "DESIGN-SYSTEM.html")"
DESIGN_JSON_PATH="$(artifact_value_or_null "design-config.json")"
ARCH_PATH="$(artifact_value_or_null "ARCHITECTURE.md")"

DISCOVERY=false
MARKET=false
SPECS=false
DESIGN=false
ARCH=false
EXECUTION=false

if [ -n "$DISCOVERY_PATH" ]; then
  DISCOVERY=true
  PHASE="DISCOVERY"
  CURRENT_SKILL='"genius-product-market-analyst"'
  CURRENT_WORKFLOW='"discovery"'
fi

if [ -n "$MARKET_PATH" ]; then
  MARKET=true
  PHASE="IDEATION"
  CURRENT_SKILL='"genius-specs"'
  CURRENT_WORKFLOW='"market-analysis"'
fi

if [ -n "$SPECS_PATH" ]; then
  SPECS=true
  PHASE="IDEATION"
  CURRENT_SKILL='"genius-designer"'
  CURRENT_WORKFLOW='"specs"'
fi

if [ -n "$DESIGN_HTML_PATH" ] || [ -n "$DESIGN_JSON_PATH" ]; then
  DESIGN=true
  PHASE="DESIGN"
  CURRENT_SKILL='"genius-architect"'
  CURRENT_WORKFLOW='"design"'
fi

if [ -n "$ARCH_PATH" ]; then
  ARCH=true
  PHASE="ARCHITECTURE"
  CURRENT_SKILL='"genius-orchestrator"'
  CURRENT_WORKFLOW='"architecture"'
fi

TOTAL_TASKS=0
COMPLETED_TASKS=0
if [ -f ".claude/plan.md" ]; then
  TOTAL_TASKS=$(grep -c "^- \[" .claude/plan.md 2>/dev/null || echo 0)
  COMPLETED_TASKS=$(grep -c "^- \[x\]" .claude/plan.md 2>/dev/null || echo 0)
elif [ -f ".agents/plan.md" ]; then
  TOTAL_TASKS=$(grep -c "^- \[" .agents/plan.md 2>/dev/null || echo 0)
  COMPLETED_TASKS=$(grep -c "^- \[x\]" .agents/plan.md 2>/dev/null || echo 0)
fi

if [ "$TOTAL_TASKS" -gt 0 ]; then
  EXECUTION=true
  PHASE="EXECUTION"
  CURRENT_SKILL='"genius-orchestrator"'
  CURRENT_WORKFLOW='"execution"'
fi

if [ -f ".genius/session-log.jsonl" ]; then
  BOOTSTRAP_STATUS="completed"
fi

if [ -f "$STATE" ]; then
  EXISTING_BOOTSTRAP="$(jq -r '.bootstrapStatus // empty' "$STATE" 2>/dev/null || true)"
  EXISTING_MIGRATION="$(jq -r '.migrationStatus // empty' "$STATE" 2>/dev/null || true)"
  EXISTING_READY="$(jq -r '.compatibility.cortexReady // empty' "$STATE" 2>/dev/null || true)"
  [ -n "$EXISTING_BOOTSTRAP" ] && BOOTSTRAP_STATUS="$EXISTING_BOOTSTRAP"
  [ -n "$EXISTING_MIGRATION" ] && MIGRATION_STATUS="$EXISTING_MIGRATION"
  [ -n "$EXISTING_READY" ] && CORTEX_READY="$EXISTING_READY"
fi

gt_write_state_json "$STATE" \
  "$EXPERIENCE_MODE" \
  "$INSTALL_MODE" \
  "$ENGINE" \
  "$ORIGIN" \
  "$MIGRATION_STATUS" \
  "$BOOTSTRAP_STATUS" \
  "$PHASE" \
  "$CURRENT_SKILL" \
  "$CURRENT_WORKFLOW" \
  "null" \
  "$CORTEX_READY"

tmp_state="$(mktemp)"
jq \
  --argjson discovery "$DISCOVERY" \
  --argjson market "$MARKET" \
  --argjson specs "$SPECS" \
  --argjson design "$DESIGN" \
  --argjson arch "$ARCH" \
  --argjson execution "$EXECUTION" \
  --arg discoveryPath "$DISCOVERY_PATH" \
  --arg marketPath "$MARKET_PATH" \
  --arg specsPath "$SPECS_PATH" \
  --arg designPath "${DESIGN_HTML_PATH:-$DESIGN_JSON_PATH}" \
  --arg archPath "$ARCH_PATH" \
  --argjson total "$TOTAL_TASKS" \
  --argjson completed "$COMPLETED_TASKS" \
  --arg updatedAt "$(gt_now)" '
  .checkpoints.discovery = $discovery |
  .checkpoints.market_analysis = $market |
  .checkpoints.specs_approved = $specs |
  .checkpoints.design_chosen = $design |
  .checkpoints.architecture_approved = $arch |
  .checkpoints.execution_started = $execution |
  .tasks.total = $total |
  .tasks.completed = $completed |
  .artifacts = (
    {}
    + (if $discoveryPath != "" then {"DISCOVERY.xml": $discoveryPath} else {} end)
    + (if $marketPath != "" then {"MARKET-ANALYSIS.xml": $marketPath} else {} end)
    + (if $specsPath != "" then {"SPECIFICATIONS.xml": $specsPath} else {} end)
    + (if $designPath != "" then {"DESIGN-SYSTEM.html": $designPath} else {} end)
    + (if $archPath != "" then {"ARCHITECTURE.md": $archPath} else {} end)
  ) |
  .updated_at = $updatedAt' \
  "$STATE" > "$tmp_state"
mv "$tmp_state" "$STATE"

if [ ! -f "$OUTPUT_STATE" ]; then
  gt_write_outputs_state_json "$OUTPUT_STATE" "$PHASE"
fi

echo "State migrated: phase=$PHASE origin=$ORIGIN installMode=$INSTALL_MODE engine=$ENGINE"
