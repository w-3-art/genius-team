#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/contract.sh"

STATE=".genius/state.json"
CONFIG=".genius/config.json"
OUTPUT_STATE=".genius/outputs/state.json"
SESSION_LOG=".genius/session-log.jsonl"
DASHBOARD=".genius/DASHBOARD.html"

[ -f "$STATE" ] || {
  echo "Missing .genius/state.json. Run setup or GT upgrade first." >&2
  exit 1
}

gt_ensure_memory_files

INSTALL_MODE="$(jq -r '.installMode // .mode // "cli"' "$CONFIG" 2>/dev/null || echo "cli")"
ENGINE="$(jq -r '.engine // "claude"' "$CONFIG" 2>/dev/null || echo "claude")"
EXPERIENCE_MODE="$(jq -r '.mode // "builder"' .genius/mode.json 2>/dev/null || echo "builder")"
PHASE="$(jq -r '.phase // "NOT_STARTED"' "$STATE" 2>/dev/null || echo "NOT_STARTED")"

[ -f "$OUTPUT_STATE" ] || gt_write_outputs_state_json "$OUTPUT_STATE" "$PHASE"
[ -f "$DASHBOARD" ] || gt_write_dashboard_html "$DASHBOARD" "$(basename "$ROOT_DIR")"
[ -f "$SESSION_LOG" ] || touch "$SESSION_LOG"
gt_install_local_commands "$ENGINE"

gt_append_session_event "$SESSION_LOG" "migration" "ok" "cortex-ready migration completed"

tmp_state="$(mktemp)"
jq \
  --arg version "$(gt_version)" \
  --arg contract "$(gt_contract_version)" \
  --arg installMode "$INSTALL_MODE" \
  --arg engine "$ENGINE" \
  --arg mode "$EXPERIENCE_MODE" \
  --arg phase "$PHASE" \
  --arg updatedAt "$(gt_now)" '
  .version = $version |
  .contractVersion = $contract |
  .installStatus = "installed" |
  .migrationStatus = "cortex-ready" |
  .mode = $mode |
  .installMode = $installMode |
  .engine = $engine |
  .phase = $phase |
  .outputs.statePath = ".genius/outputs/state.json" |
  .outputs.dashboardPath = ".genius/DASHBOARD.html" |
  .compatibility.cortexReady = true |
  .compatibility.lastCheckedAt = $updatedAt |
  .updated_at = $updatedAt' \
  "$STATE" > "$tmp_state"
mv "$tmp_state" "$STATE"

tmp_outputs="$(mktemp)"
jq --arg updatedAt "$(gt_now)" '
  .version = "'"$(gt_version)"'" |
  .contractVersion = "'"$(gt_contract_version)"'" |
  .currentPhase = (.currentPhase // "NOT_STARTED") |
  .dashboard.path = ".genius/DASHBOARD.html" |
  .dashboard.generated = true |
  .dashboard.generatedAt = $updatedAt |
  .updatedAt = $updatedAt' \
  "$OUTPUT_STATE" > "$tmp_outputs"
mv "$tmp_outputs" "$OUTPUT_STATE"

echo "Cortex-ready migration complete."
