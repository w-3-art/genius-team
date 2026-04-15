#!/usr/bin/env bash
set -euo pipefail

gt_now() {
  date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z'
}

gt_version() {
  echo "22.0.0"
}

gt_contract_version() {
  echo "22.0"
}

gt_default_install_mode() {
  echo "cli"
}

gt_default_experience_mode() {
  echo "builder"
}

gt_default_phase() {
  echo "NOT_STARTED"
}

gt_default_dashboard_title() {
  basename "${1:-$(pwd)}"
}

gt_write_mode_json() {
  local path="$1"
  local mode="${2:-$(gt_default_experience_mode)}"
  local set_by="${3:-setup}"
  cat > "$path" <<EOF
{
  "mode": "$mode",
  "contractVersion": "$(gt_contract_version)",
  "set_at": "$(gt_now)",
  "set_by": "$set_by"
}
EOF
}

gt_write_config_json() {
  local path="$1"
  local install_mode="${2:-$(gt_default_install_mode)}"
  local engine="${3:-claude}"
  cat > "$path" <<EOF
{
  "version": "$(gt_version)",
  "contractVersion": "$(gt_contract_version)",
  "mode": "$install_mode",
  "installMode": "$install_mode",
  "engine": "$engine",
  "models": {
    "default": "opus",
    "saveTokenMode": false,
    "roles": {
      "lead": "opus",
      "architect": "opus",
      "interviewer": "opus",
      "dev": "opus",
      "qa": "opus",
      "qa-micro": "opus",
      "debugger": "opus",
      "reviewer": "opus",
      "specs": "opus",
      "designer": "opus",
      "marketer": "opus",
      "copywriter": "opus",
      "security": "opus",
      "deployer": "opus"
    }
  },
  "saveTokenModeOverrides": {
    "dev": "sonnet",
    "qa-micro": "sonnet",
    "debugger": "sonnet",
    "reviewer": "sonnet"
  },
  "memory": {
    "briefingMaxLines": 150,
    "decayDays": {
      "progress": 7,
      "context": 30
    },
    "sessionLogRetention": 30
  },
  "updated_at": "$(gt_now)"
}
EOF
}

gt_write_outputs_state_json() {
  local path="$1"
  local phase="${2:-$(gt_default_phase)}"
  cat > "$path" <<EOF
{
  "version": "$(gt_version)",
  "contractVersion": "$(gt_contract_version)",
  "currentPhase": "$phase",
  "dashboard": {
    "path": ".genius/DASHBOARD.html",
    "generated": false,
    "generatedAt": null
  },
  "outputs": [],
  "updatedAt": "$(gt_now)"
}
EOF
}

gt_write_dashboard_html() {
  local path="$1"
  local project_name="${2:-$(gt_default_dashboard_title)}"
  cat > "$path" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${project_name} — Genius Team Dashboard</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #0a0a0f;
      color: #e2e8f0;
      display: grid;
      place-items: center;
      min-height: 100vh;
      padding: 24px;
    }
    .card {
      max-width: 720px;
      width: 100%;
      background: #13131a;
      border: 1px solid #232336;
      border-radius: 16px;
      padding: 28px;
      box-shadow: 0 20px 60px rgba(0,0,0,.35);
    }
    h1 {
      margin: 0 0 12px;
      font-size: 1.3rem;
    }
    p {
      margin: 0 0 12px;
      color: #94a3b8;
      line-height: 1.5;
    }
    code {
      background: #0d1117;
      border: 1px solid #232336;
      border-radius: 6px;
      padding: 2px 6px;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>🧠 ${project_name} — Genius Team Dashboard</h1>
    <p>This dashboard has not been generated yet.</p>
    <p>Run <code>genius-start</code> or the relevant GT workflow to bootstrap outputs, then refresh this file or regenerate the dashboard.</p>
    <p>Canonical output state: <code>.genius/outputs/state.json</code></p>
  </div>
</body>
</html>
EOF
}

gt_write_state_json() {
  local path="$1"
  local experience_mode="${2:-$(gt_default_experience_mode)}"
  local install_mode="${3:-$(gt_default_install_mode)}"
  local engine="${4:-claude}"
  local origin="${5:-native}"
  local migration_status="${6:-native-v22}"
  local bootstrap_status="${7:-not_run}"
  local phase="${8:-$(gt_default_phase)}"
  local current_skill="${9:-null}"
  local current_workflow="${10:-null}"
  local current_task_id="${11:-null}"
  local cortex_ready="${12:-false}"
  local timestamp
  timestamp="$(gt_now)"
  cat > "$path" <<EOF
{
  "version": "$(gt_version)",
  "contractVersion": "$(gt_contract_version)",
  "installStatus": "installed",
  "migrationStatus": "$migration_status",
  "bootstrapStatus": "$bootstrap_status",
  "phase": "$phase",
  "mode": "$experience_mode",
  "installMode": "$install_mode",
  "engine": "$engine",
  "origin": "$origin",
  "currentSkill": $current_skill,
  "currentWorkflow": $current_workflow,
  "skillHistory": [],
  "checkpoints": {
    "discovery": false,
    "market_analysis": false,
    "specs_approved": false,
    "design_chosen": false,
    "marketing_done": false,
    "integrations_done": false,
    "architecture_approved": false,
    "execution_started": false,
    "qa_passed": false,
    "security_passed": false,
    "deployed": false
  },
  "tasks": {
    "total": 0,
    "completed": 0,
    "failed": 0,
    "skipped": 0,
    "current_task_id": $current_task_id
  },
  "artifacts": {},
  "outputs": {
    "statePath": ".genius/outputs/state.json",
    "dashboardPath": ".genius/DASHBOARD.html",
    "available": []
  },
  "compatibility": {
    "cortexReady": $cortex_ready,
    "lastCheckedAt": null
  },
  "agentTeams": {
    "active": false,
    "leadSessionId": null,
    "teammates": []
  },
  "created_at": "$timestamp",
  "updated_at": "$timestamp"
}
EOF
}

gt_append_session_event() {
  local path="$1"
  local type="${2:-info}"
  local status="${3:-ok}"
  local message="${4:-event}"
  mkdir -p "$(dirname "$path")"
  touch "$path"
  printf '{"timestamp":"%s","type":"%s","status":"%s","message":"%s"}\n' \
    "$(gt_now)" "$type" "$status" "$(printf '%s' "$message" | sed 's/"/\\"/g')" >> "$path"
}

gt_ensure_memory_files() {
  mkdir -p .genius/memory/session-logs .genius/backups .genius/bin .genius/outputs .genius/discovery .genius/wiki
  for file in decisions.json patterns.json progress.json errors.json; do
    [ -f ".genius/memory/$file" ] || echo '[]' > ".genius/memory/$file"
  done
  [ -f ".genius/memory/BRIEFING.md" ] || cat > .genius/memory/BRIEFING.md <<'EOF'
# Briefing

- No project briefing generated yet.
- Run `genius-start` to refresh project memory and bootstrap the repo state.
EOF
}

gt_briefing_excerpt() {
  if [ ! -f ".genius/memory/BRIEFING.md" ]; then
    echo ""
    return
  fi

  awk '
    /^#/ { next }
    NF {
      printf("%s ", $0)
      count++
      if (count >= 5) exit
    }
  ' .genius/memory/BRIEFING.md | sed 's/[[:space:]]\+/ /g; s/[[:space:]]*$//' | cut -c1-280
}

gt_write_wiki_meta_concepts_json() {
  local path="$1"
  local repo_name="${2:-$(basename "$(pwd)")}"
  local mode="${3:-$(gt_default_experience_mode)}"
  local install_mode="${4:-$(gt_default_install_mode)}"
  local engine="${5:-claude}"
  local phase="${6:-$(gt_default_phase)}"

  jq -n \
    --arg version "$(gt_version)" \
    --arg contractVersion "$(gt_contract_version)" \
    --arg repo "$repo_name" \
    --arg generatedAt "$(gt_now)" \
    --arg mode "$mode" \
    --arg installMode "$install_mode" \
    --arg engine "$engine" \
    --arg phase "$phase" \
    '{
      version: $version,
      contractVersion: $contractVersion,
      repo: $repo,
      generatedAt: $generatedAt,
      items: [
        {
          id: "repo-mode",
          type: "memory",
          name: "repo-mode",
          summary: ($repo + " currently runs in " + $mode + " experience mode."),
          scope: "repo",
          status: "candidate",
          confidence: 0.55,
          provenance: [".genius/mode.json"],
          action: "Surface this as a repo-scoped Memory Bit in Cortex."
        },
        {
          id: "repo-engine",
          type: "memory",
          name: "repo-engine",
          summary: ($repo + " is configured for " + $engine + " with install mode " + $installMode + "."),
          scope: "repo",
          status: "candidate",
          confidence: 0.58,
          provenance: [".genius/config.json"],
          action: "Keep engine/runtime posture visible in the Cortex Wiki."
        },
        {
          id: "repo-phase",
          type: "memory",
          name: "repo-phase",
          summary: ($repo + " is currently in phase " + $phase + "."),
          scope: "repo",
          status: "candidate",
          confidence: 0.52,
          provenance: [".genius/state.json"],
          action: "Expose this as execution context before diffusing repo guidance."
        }
      ]
    }' > "$path"
}

gt_write_wiki_manifest_json() {
  local path="$1"
  local repo_name="${2:-$(basename "$(pwd)")}"
  local phase="${3:-$(gt_default_phase)}"
  local mode="${4:-$(gt_default_experience_mode)}"
  local install_mode="${5:-$(gt_default_install_mode)}"
  local engine="${6:-claude}"
  local migration_status="${7:-native-v22}"
  local bootstrap_status="${8:-not_run}"
  local cortex_ready="${9:-false}"
  local briefing_excerpt="${10:-}"
  local tasks_total="${11:-0}"
  local tasks_completed="${12:-0}"
  local outputs_count="${13:-0}"
  local briefing_exists session_exists decisions_exists patterns_exists progress_exists errors_exists state_exists outputs_exists meta_exists

  briefing_exists=$([ -f ".genius/memory/BRIEFING.md" ] && echo true || echo false)
  session_exists=$([ -f ".genius/session-log.jsonl" ] && echo true || echo false)
  decisions_exists=$([ -f ".genius/memory/decisions.json" ] && echo true || echo false)
  patterns_exists=$([ -f ".genius/memory/patterns.json" ] && echo true || echo false)
  progress_exists=$([ -f ".genius/memory/progress.json" ] && echo true || echo false)
  errors_exists=$([ -f ".genius/memory/errors.json" ] && echo true || echo false)
  state_exists=$([ -f ".genius/state.json" ] && echo true || echo false)
  outputs_exists=$([ -f ".genius/outputs/state.json" ] && echo true || echo false)
  meta_exists=$([ -f ".genius/wiki/meta-concepts.json" ] && echo true || echo false)

  jq -n \
    --arg version "$(gt_version)" \
    --arg contractVersion "$(gt_contract_version)" \
    --arg repo "$repo_name" \
    --arg generatedAt "$(gt_now)" \
    --arg phase "$phase" \
    --arg mode "$mode" \
    --arg installMode "$install_mode" \
    --arg engine "$engine" \
    --arg migrationStatus "$migration_status" \
    --arg bootstrapStatus "$bootstrap_status" \
    --arg briefingExcerpt "$briefing_excerpt" \
    --argjson cortexReady "$cortex_ready" \
    --argjson tasksTotal "$tasks_total" \
    --argjson tasksCompleted "$tasks_completed" \
    --argjson outputsCount "$outputs_count" \
    --argjson briefingExists "$briefing_exists" \
    --argjson sessionExists "$session_exists" \
    --argjson decisionsExists "$decisions_exists" \
    --argjson patternsExists "$patterns_exists" \
    --argjson progressExists "$progress_exists" \
    --argjson errorsExists "$errors_exists" \
    --argjson stateExists "$state_exists" \
    --argjson outputsExists "$outputs_exists" \
    --argjson metaExists "$meta_exists" \
    '{
      version: $version,
      contractVersion: $contractVersion,
      repo: $repo,
      generatedAt: $generatedAt,
      role: "gt-orchestrated-repo",
      state: {
        phase: $phase,
        mode: $mode,
        installMode: $installMode,
        engine: $engine,
        migrationStatus: $migrationStatus,
        bootstrapStatus: $bootstrapStatus,
        cortexReady: $cortexReady
      },
      summary: {
        briefingExcerpt: $briefingExcerpt,
        tasks: {
          total: $tasksTotal,
          completed: $tasksCompleted
        },
        outputsCount: $outputsCount
      },
      sources: [
        { id: "briefing", kind: "briefing", path: ".genius/memory/BRIEFING.md", exists: $briefingExists },
        { id: "session-log", kind: "session-log", path: ".genius/session-log.jsonl", exists: $sessionExists },
        { id: "decisions", kind: "decisions", path: ".genius/memory/decisions.json", exists: $decisionsExists },
        { id: "patterns", kind: "patterns", path: ".genius/memory/patterns.json", exists: $patternsExists },
        { id: "progress", kind: "progress", path: ".genius/memory/progress.json", exists: $progressExists },
        { id: "errors", kind: "errors", path: ".genius/memory/errors.json", exists: $errorsExists },
        { id: "state", kind: "state", path: ".genius/state.json", exists: $stateExists },
        { id: "outputs-state", kind: "outputs-state", path: ".genius/outputs/state.json", exists: $outputsExists },
        { id: "meta-concepts", kind: "meta-concepts", path: ".genius/wiki/meta-concepts.json", exists: $metaExists }
      ],
      metaConceptsPath: ".genius/wiki/meta-concepts.json",
      actions: [
        {
          id: "align-contract",
          type: "align",
          status: (if $migrationStatus == "cortex-ready" and $cortexReady then "done" else "open" end),
          title: "Keep the repo on the Cortex-ready GT contract",
          detail: ("migrationStatus=" + $migrationStatus + ", cortexReady=" + ($cortexReady | tostring))
        },
        {
          id: "bootstrap-runtime",
          type: "bootstrap",
          status: (if $bootstrapStatus == "completed" then "done" else "open" end),
          title: "Keep the repo bootstrapped for Cortex orchestration",
          detail: ("bootstrapStatus=" + $bootstrapStatus)
        },
        {
          id: "refresh-briefing",
          type: "memory",
          status: (if $briefingExists then "done" else "open" end),
          title: "Refresh BRIEFING.md so Cortex Wiki has usable repo memory",
          detail: ".genius/memory/BRIEFING.md"
        },
        {
          id: "review-meta-concepts",
          type: "meta-concepts",
          status: (if $metaExists then "done" else "open" end),
          title: "Review repo-scoped candidate Meta-Concepts",
          detail: ".genius/wiki/meta-concepts.json"
        }
      ]
    }' > "$path"
}

gt_ensure_wiki_files() {
  local repo_name="${1:-$(basename "$(pwd)")}"
  local mode install_mode engine phase migration_status bootstrap_status cortex_ready tasks_total tasks_completed outputs_count briefing_excerpt

  mkdir -p .genius/wiki
  [ -f ".genius/wiki/README.md" ] || cat > .genius/wiki/README.md <<'EOF'
# Cortex Wiki Export

- `manifest.json` is the repo dossier that Cortex compiles into the portfolio wiki.
- `meta-concepts.json` contains repo-scoped candidate Meta-Concepts that Cortex can turn into suggestions/actions.
- This folder is generated by Genius Team and refreshed by `genius-start`.
EOF

  mode="$(jq -r '.mode // "builder"' .genius/mode.json 2>/dev/null || echo "builder")"
  install_mode="$(jq -r '.installMode // .mode // "cli"' .genius/config.json 2>/dev/null || echo "cli")"
  engine="$(jq -r '.engine // "claude"' .genius/config.json 2>/dev/null || echo "claude")"
  phase="$(jq -r '.phase // "NOT_STARTED"' .genius/state.json 2>/dev/null || echo "NOT_STARTED")"
  migration_status="$(jq -r '.migrationStatus // "native-v22"' .genius/state.json 2>/dev/null || echo "native-v22")"
  bootstrap_status="$(jq -r '.bootstrapStatus // "not_run"' .genius/state.json 2>/dev/null || echo "not_run")"
  cortex_ready="$(jq -r '.compatibility.cortexReady // false' .genius/state.json 2>/dev/null || echo false)"
  tasks_total="$(jq -r '.tasks.total // 0' .genius/state.json 2>/dev/null || echo 0)"
  tasks_completed="$(jq -r '.tasks.completed // 0' .genius/state.json 2>/dev/null || echo 0)"
  outputs_count="$(jq -r '(.outputs // []) | length' .genius/outputs/state.json 2>/dev/null || echo 0)"
  briefing_excerpt="$(gt_briefing_excerpt)"

  gt_write_wiki_meta_concepts_json ".genius/wiki/meta-concepts.json" "$repo_name" "$mode" "$install_mode" "$engine" "$phase"
  gt_write_wiki_manifest_json ".genius/wiki/manifest.json" "$repo_name" "$phase" "$mode" "$install_mode" "$engine" "$migration_status" "$bootstrap_status" "$cortex_ready" "$briefing_excerpt" "$tasks_total" "$tasks_completed" "$outputs_count"
}

gt_install_local_commands() {
  local engine="${1:-claude}"
  local commands=(
    genius-start genius-dashboard genius-upgrade dual-status dual-challenge
    status continue reset save-tokens update-check genius-mode
    genius-switch-engine genius-import playground-update
  )

  mkdir -p .genius/bin
  cp "scripts/bin/genius-command" ".genius/bin/genius-command"
  chmod +x ".genius/bin/genius-command"

  for cmd in "${commands[@]}"; do
    ln -sfn "genius-command" ".genius/bin/${cmd}"
  done

  if [[ "$engine" == "codex" || "$engine" == "dual" ]]; then
    mkdir -p .agents
    ln -sfn ../.genius/bin .agents/bin
  fi
}
