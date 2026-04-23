#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/contract.sh"

MODE="cli"
ENGINE="claude"
ERRORS=0

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC}  $*"; }
ok() { echo -e "${GREEN}✓${NC}  $*"; }
warn() { echo -e "${YELLOW}⚠${NC}  $*"; }
fail() { echo -e "${RED}✗${NC}  $*"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --mode=*) MODE="${1#*=}"; shift ;;
    --engine) ENGINE="$2"; shift 2 ;;
    --engine=*) ENGINE="${1#*=}"; shift ;;
    -h|--help)
      echo "Usage: ./scripts/setup.sh [--mode cli|ide|omni|dual] [--engine claude|codex|dual]"
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      exit 1
      ;;
  esac
done

[[ "$MODE" =~ ^(cli|ide|omni|dual)$ ]] || { fail "Invalid mode: $MODE"; exit 1; }
[[ "$ENGINE" =~ ^(claude|codex|dual)$ ]] || { fail "Invalid engine: $ENGINE"; exit 1; }

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🧠 Genius Team v22.0 — Setup                              ║"
printf '║  Mode: %-6s | Engine: %-35s║\n' "$MODE" "$ENGINE"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

check_cmd() {
  local cmd="$1"
  local label="$2"
  local required="${3:-true}"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$label"
  else
    if [ "$required" = true ]; then
      fail "$label missing"
      ERRORS=$((ERRORS + 1))
    else
      warn "$label missing"
    fi
  fi
}

info "Checking prerequisites..."
check_cmd git "Git"
check_cmd jq "jq"
check_cmd node "Node.js" false
if [[ "$ENGINE" == "claude" || "$ENGINE" == "dual" ]]; then
  check_cmd claude "Claude Code"
fi
if [[ "$ENGINE" == "codex" || "$ENGINE" == "dual" ]]; then
  check_cmd codex "Codex CLI"
fi
echo ""

if [ "$ERRORS" -gt 0 ]; then
  fail "Setup aborted because required dependencies are missing."
  exit 1
fi

info "Creating directory structure..."
gt_ensure_memory_files
ok ".genius/ structure ready"

if [[ "$ENGINE" == "claude" || "$ENGINE" == "dual" ]]; then
  mkdir -p .claude/commands .claude/agents .claude/skills
  ok ".claude/ structure ready"
fi

if [[ "$ENGINE" == "codex" || "$ENGINE" == "dual" ]]; then
  mkdir -p .agents
  if [[ "$ENGINE" == "dual" && -d ".claude/skills" ]]; then
    ln -sfn ../.claude/skills .agents/skills
  else
    mkdir -p .agents/skills
  fi
  ok ".agents/ structure ready"
fi
echo ""

info "Installing configs and commands..."

if [[ "$ENGINE" == "claude" || "$ENGINE" == "dual" ]]; then
  # settings.json is framework-owned — safe to overwrite; user overrides live in settings.local.json
  if [ -f "configs/${MODE}/settings.json" ]; then
    # Preserve previous for user diffing, if any
    if [ -f .claude/settings.json ] && [ ! -f .claude/settings.json.previous ]; then
      cp .claude/settings.json .claude/settings.json.previous
    fi
    cp "configs/${MODE}/settings.json" .claude/settings.json
    ok ".claude/settings.json installed (previous saved as .claude/settings.json.previous)"
  else
    warn "configs/${MODE}/settings.json missing"
  fi

  # Ensure user overlay exists (gitignored, never overwritten)
  if [ ! -f .claude/settings.local.json ]; then
    mkdir -p .claude
    cat > .claude/settings.local.json <<'LOCAL_JSON'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": { "allow": [], "deny": [] },
  "hooks": {},
  "env": {}
}
LOCAL_JSON
    ok ".claude/settings.local.json created (your overlay, gitignored)"
  fi
  if [ -f .gitignore ] && ! grep -qE "^\\.claude/settings\\.local\\.json$" .gitignore 2>/dev/null; then
    printf "\n# Genius Team user overlay\n.claude/settings.local.json\n.claude/settings.json.previous\n" >> .gitignore
  fi

  # CLAUDE.md: NEVER overwrite. Install framework doctrine as .genius/GT-WORKFLOW.md
  # (CLAUDE.md should have `@.genius/GT-WORKFLOW.md` at top — handled by add.sh / create.sh).
  mkdir -p .genius
  if [ -f ".genius/GT-WORKFLOW.md" ]; then
    ok ".genius/GT-WORKFLOW.md already present (framework doctrine)"
  elif [ -f "configs/${MODE}/CLAUDE.md" ]; then
    cp "configs/${MODE}/CLAUDE.md" .genius/GT-WORKFLOW.md
    ok ".genius/GT-WORKFLOW.md installed from configs/${MODE}/CLAUDE.md"
  else
    warn ".genius/GT-WORKFLOW.md missing — neither prior file nor configs/${MODE}/CLAUDE.md available"
  fi

  # Install the project-facing template ONLY if user has no CLAUDE.md yet
  if [ ! -f CLAUDE.md ]; then
    if [ -f "templates/CLAUDE.project.md" ]; then
      cp templates/CLAUDE.project.md CLAUDE.md
      ok "CLAUDE.md installed from project template"
    elif [ -f "configs/${MODE}/CLAUDE.md" ]; then
      # Legacy fallback: prepend the import line so the new model still works
      {
        printf "@.genius/GT-WORKFLOW.md\n\n# Project\n\n"
      } > CLAUDE.md
      ok "CLAUDE.md created with @.genius/GT-WORKFLOW.md import (legacy fallback)"
    fi
  else
    if ! grep -q "^@\\.genius/GT-WORKFLOW\\.md" CLAUDE.md 2>/dev/null; then
      tmp=$(mktemp)
      printf "@.genius/GT-WORKFLOW.md\n\n" > "$tmp"
      cat CLAUDE.md >> "$tmp"
      mv "$tmp" CLAUDE.md
      ok "CLAUDE.md preserved — prepended @.genius/GT-WORKFLOW.md import"
    else
      ok "CLAUDE.md already imports GT-WORKFLOW — left untouched"
    fi
  fi
fi

if [[ "$ENGINE" == "codex" || "$ENGINE" == "dual" ]]; then
  # AGENTS.md mirrors the framework doctrine for Codex — derive from GT-WORKFLOW.md
  if [ -f ".genius/GT-WORKFLOW.md" ]; then
    sed 's/Claude Code/Codex CLI/g; s/\.claude\//.agents\//g' .genius/GT-WORKFLOW.md > AGENTS.md
  elif [ -f "configs/${MODE}/CLAUDE.md" ]; then
    sed 's/Claude Code/Codex CLI/g; s/\.claude\//.agents\//g' "configs/${MODE}/CLAUDE.md" > AGENTS.md
  else
    cat > AGENTS.md <<'EOF'
# Genius Team v22.0 — Codex Mode

Run `genius-start` from the shell after adding `.genius/bin` to your PATH.
EOF
  fi
  ok "AGENTS.md installed"
fi

gt_install_local_commands "$ENGINE"
ok "Local Genius commands installed"
echo ""

info "Initializing contract files..."

if [ ! -f ".genius/mode.json" ]; then
  gt_write_mode_json ".genius/mode.json" "$(gt_default_experience_mode)" "setup"
  ok ".genius/mode.json created"
fi

gt_write_config_json ".genius/config.json" "$MODE" "$ENGINE"
ok ".genius/config.json written"

if [ ! -f ".genius/state.json" ]; then
  gt_write_state_json ".genius/state.json" "$(gt_default_experience_mode)" "$MODE" "$ENGINE" "native" "native-v22" "not_run" "$(gt_default_phase)" "null" "null" "null" "false"
else
  bash scripts/migrate-state.sh --native --install-mode "$MODE" --engine "$ENGINE" >/dev/null
fi
ok ".genius/state.json ready"

if [ ! -f ".genius/workflows.json" ]; then
  if [ -f "templates/workflows.json" ]; then
    cp "templates/workflows.json" ".genius/workflows.json"
    ok ".genius/workflows.json installed from template"
  elif [ -f ".genius/workflows.template.json" ]; then
    cp ".genius/workflows.template.json" ".genius/workflows.json"
    ok ".genius/workflows.json installed from local template"
  else
    warn ".genius/workflows.json template missing"
  fi
fi

if [ ! -f ".genius/outputs/state.json" ]; then
  gt_write_outputs_state_json ".genius/outputs/state.json" "$(jq -r '.phase // "NOT_STARTED"' .genius/state.json 2>/dev/null || echo "NOT_STARTED")"
  ok ".genius/outputs/state.json created"
fi

[ -f ".genius/session-log.jsonl" ] || touch ".genius/session-log.jsonl"
gt_append_session_event ".genius/session-log.jsonl" "setup" "ok" "setup completed for mode=${MODE} engine=${ENGINE}"
ok ".genius/session-log.jsonl ready"

gt_ensure_wiki_files "$(basename "$ROOT_DIR")"
ok ".genius/wiki export ready"

[ -f ".genius/DASHBOARD.html" ] || gt_write_dashboard_html ".genius/DASHBOARD.html" "$(basename "$ROOT_DIR")"
ok ".genius/DASHBOARD.html ready"

if [[ "$ENGINE" == "dual" && ! -f ".genius/dual-engine-state.json" ]]; then
  cat > .genius/dual-engine-state.json <<EOF
{
  "engine": "dual",
  "primary": "claude",
  "secondary": "codex",
  "sync_enabled": true,
  "last_sync": null,
  "claude_sessions": 0,
  "codex_sessions": 0,
  "shared_artifacts": [],
  "updated_at": "$(gt_now)"
}
EOF
  ok ".genius/dual-engine-state.json created"
fi
echo ""

info "Running verification..."
bash scripts/verify.sh || {
  fail "Verification failed after setup."
  exit 1
}
echo ""

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ Setup Complete                                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Genius Team $(gt_version) is installed."
echo "  Install mode: $MODE"
echo "  Engine:       $ENGINE"
echo ""
echo "Next steps:"
echo "  1. Add local commands to PATH: export PATH=\"\$PWD/.genius/bin:\$PATH\""
echo "  2. Run: genius-start"
echo "  3. For full Cortex compatibility later: run migration if prompted, then bootstrap"
echo ""
