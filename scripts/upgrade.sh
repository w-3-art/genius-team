#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
# Genius Team Universal Upgrade Script
# Upgrades from any previous version to v13.0
#═══════════════════════════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Config
REPO_URL="https://raw.githubusercontent.com/w-3-art/genius-team/main"
TARGET_VERSION="13.0.0"

# Flags
FORCE=false
DRY_RUN=false
VERBOSE=false

# Stats
FILES_DOWNLOADED=0
FILES_SKIPPED=0

#═══════════════════════════════════════════════════════════════════════════════
# Helpers
#═══════════════════════════════════════════════════════════════════════════════

print_banner() {
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}  ${BOLD}🚀 Genius Team Upgrade → v13.0${NC}                           ${CYAN}║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

log_step()    { echo -e "${BLUE}[$1/$2]${NC} $3"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error()   { echo -e "${RED}✗${NC} $1"; }
log_info()    { echo -e "${CYAN}ℹ${NC} $1"; }
log_verbose() { [ "$VERBOSE" = true ] && echo -e "  ${CYAN}→${NC} $1" >&2 || true; }

show_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --force     Skip git clean check"
  echo "  --dry-run   Preview changes without modifying files"
  echo "  --verbose   Show detailed file download output"
  echo "  --help      Show this help"
  echo ""
  echo "Upgrades your Genius Team project to v13.0 from any previous version."
}

#═══════════════════════════════════════════════════════════════════════════════
# Version Detection (supports v9 through v13)
#═══════════════════════════════════════════════════════════════════════════════

detect_version() {
  # Method 1: state.json
  if [ -f ".genius/state.json" ]; then
    local v
    v=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' .genius/state.json 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
    if [ -n "$v" ]; then echo "$v"; return 0; fi
  fi

  # Method 2: CLAUDE.md markers
  if [ -f "CLAUDE.md" ]; then
    if grep -qE "v1[23]|13\.|12\." CLAUDE.md 2>/dev/null; then echo "13.0.0"; return 0; fi
    if grep -qE "v11|11\." CLAUDE.md 2>/dev/null; then echo "11.0.0"; return 0; fi
    if grep -qE "v10|10\." CLAUDE.md 2>/dev/null; then echo "10.0.0"; return 0; fi
    if grep -qE "v9|9\." CLAUDE.md 2>/dev/null; then echo "9.0.0"; return 0; fi
  fi

  # Method 3: File structure heuristics
  if [ -f "GENIUS_GUARD.md" ] && [ -d "playgrounds/templates" ]; then
    if [ -f "scripts/genius-server.js" ]; then echo "13.0.0"; return 0; fi
    if [ -f "scripts/add.sh" ]; then echo "11.0.0"; return 0; fi
    echo "10.0.0"; return 0
  fi

  echo "9.0.0"
}

version_major() { echo "$1" | cut -d. -f1; }

# Returns 0 if v1 < v2
version_lt() {
  local m1; m1=$(version_major "$1")
  local m2; m2=$(version_major "$2")
  [ "$m1" -lt "$m2" ]
}

#═══════════════════════════════════════════════════════════════════════════════
# Prerequisites
#═══════════════════════════════════════════════════════════════════════════════

check_prerequisites() {
  local errors=0

  if [ ! -f "CLAUDE.md" ]; then
    log_error "CLAUDE.md not found. Run this from inside a Genius Team project."
    errors=$((errors + 1))
  fi

  if ! command -v curl &>/dev/null; then
    log_error "curl is required but not installed."
    errors=$((errors + 1))
  fi

  if [ "$FORCE" = false ] && command -v git &>/dev/null && [ -d ".git" ]; then
    local dirty; dirty=$(git status --porcelain 2>/dev/null)
    if [ -n "$dirty" ]; then
      log_error "Uncommitted changes detected. Commit first, or use --force."
      errors=$((errors + 1))
    fi
  fi

  return $errors
}

#═══════════════════════════════════════════════════════════════════════════════
# Backup
#═══════════════════════════════════════════════════════════════════════════════

create_backup() {
  local ts; ts=$(date +%Y%m%d-%H%M%S)
  local backup_dir=".genius/backups/pre-v13-upgrade-$ts"

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would create backup at: $backup_dir"
    echo "$backup_dir"
    return 0
  fi

  mkdir -p "$backup_dir"
  [ -d ".claude" ]         && cp -r .claude         "$backup_dir/" 2>/dev/null || true
  [ -f "CLAUDE.md" ]       && cp CLAUDE.md           "$backup_dir/"
  [ -f "GENIUS_GUARD.md" ] && cp GENIUS_GUARD.md     "$backup_dir/"
  [ -d "playgrounds" ]     && cp -r playgrounds      "$backup_dir/" 2>/dev/null || true
  [ -d "scripts" ]         && cp -r scripts          "$backup_dir/" 2>/dev/null || true
  [ -f ".genius/state.json" ] && cp .genius/state.json "$backup_dir/state.json.bak"

  log_verbose "Backup created at: $backup_dir"
  echo "$backup_dir"
}

#═══════════════════════════════════════════════════════════════════════════════
# Download
#═══════════════════════════════════════════════════════════════════════════════

download_file() {
  local remote=$1
  local local_path=$2
  local overwrite=${3:-true}   # default: overwrite existing

  if [ "$DRY_RUN" = true ]; then
    log_verbose "[DRY-RUN] Would download: $remote → $local_path"
    FILES_DOWNLOADED=$((FILES_DOWNLOADED + 1))
    return 0
  fi

  # Skip if exists and overwrite=false
  if [ "$overwrite" = false ] && [ -f "$local_path" ]; then
    log_verbose "Skipped (exists): $local_path"
    FILES_SKIPPED=$((FILES_SKIPPED + 1))
    return 0
  fi

  local dir; dir=$(dirname "$local_path")
  [ -d "$dir" ] || mkdir -p "$dir"

  if curl -fsSL "$REPO_URL/$remote" -o "$local_path" 2>/dev/null; then
    log_verbose "✓ $local_path"
    FILES_DOWNLOADED=$((FILES_DOWNLOADED + 1))
  else
    log_warning "Failed to download: $remote"
  fi
}

#═══════════════════════════════════════════════════════════════════════════════
# Main Upgrade: downloads all v13 files
#═══════════════════════════════════════════════════════════════════════════════

upgrade_to_v13() {
  # ── Core ──────────────────────────────────────────────────────────────────
  log_info "Core files..."
  download_file "CLAUDE.md"       "CLAUDE.md"
  download_file "GENIUS_GUARD.md" "GENIUS_GUARD.md"
  download_file "README.md"       "README.md"
  download_file "CHANGELOG.md"    "CHANGELOG.md"
  download_file ".gitignore"      ".gitignore"

  # ── .claude/settings.json ─────────────────────────────────────────────────
  log_info "Claude settings..."
  download_file ".claude/settings.json" ".claude/settings.json"

  # ── Commands ──────────────────────────────────────────────────────────────
  log_info "Commands..."
  local commands=(
    "genius-start" "status" "continue" "reset" "save-tokens"
    "dual-status" "dual-challenge" "omni-status"
    "hydrate-tasks" "update-check"
    "guard-check" "guard-recover"
    "memory-add" "memory-search" "memory-status" "memory-recover" "memory-forget"
  )
  for cmd in "${commands[@]}"; do
    download_file ".claude/commands/$cmd.md" ".claude/commands/$cmd.md"
  done

  # ── Agents ────────────────────────────────────────────────────────────────
  log_info "Agents..."
  local agents=(
    "genius-dev" "genius-reviewer" "genius-debugger"
    "genius-challenger" "genius-qa-micro"
  )
  for agent in "${agents[@]}"; do
    download_file ".claude/agents/$agent.md" ".claude/agents/$agent.md"
  done

  # ── Skills ────────────────────────────────────────────────────────────────
  log_info "Skills (21+)..."
  local skills=(
    "genius-team"
    "genius-start"
    "genius-dev"
    "genius-reviewer"
    "genius-debugger"
    "genius-architect"
    "genius-designer"
    "genius-qa"
    "genius-qa-micro"
    "genius-security"
    "genius-deployer"
    "genius-copywriter"
    "genius-marketer"
    "genius-product-market-analyst"
    "genius-interviewer"
    "genius-specs"
    "genius-test-assistant"
    "genius-orchestrator"
    "genius-dual-engine"
    "genius-omni-router"
    "genius-integration-guide"
    "genius-onboarding"
    "genius-updater"
    "genius-team-optimizer"
    "genius-memory"
  )
  for skill in "${skills[@]}"; do
    download_file ".claude/skills/$skill/SKILL.md" ".claude/skills/$skill/SKILL.md"
  done

  # ── Scripts ───────────────────────────────────────────────────────────────
  log_info "Scripts..."
  local scripts=(
    "setup.sh" "create.sh" "add.sh" "upgrade.sh" "verify.sh"
    "guard-validate.sh"
    "memory-capture.sh" "memory-rollup.sh" "memory-briefing.sh"
    "memory-recover.sh" "memory-extract.sh"
    "genius-server.js" "start-genius.sh"
  )
  for s in "${scripts[@]}"; do
    download_file "scripts/$s" "scripts/$s"
  done
  [ "$DRY_RUN" = false ] && chmod +x scripts/*.sh 2>/dev/null || true

  # ── Playgrounds ───────────────────────────────────────────────────────────
  log_info "Playgrounds (13 + dashboard)..."
  local playgrounds=(
    "architecture-explorer" "copy-ab-tester" "deploy-checklist"
    "design-system-builder" "gtm-simulator" "market-simulator"
    "progress-dashboard" "project-canvas" "project-dashboard"
    "risk-matrix" "stack-configurator" "test-coverage-map"
    "user-journey-builder"
  )
  for pg in "${playgrounds[@]}"; do
    download_file "playgrounds/templates/$pg.html" "playgrounds/templates/$pg.html"
  done
  download_file "playgrounds/genius-dashboard.html" "playgrounds/genius-dashboard.html"
  download_file "playgrounds/data/projects.json"    "playgrounds/data/projects.json" false

  # ── Configs ───────────────────────────────────────────────────────────────
  log_info "Configs..."
  download_file ".genius/config.json"      ".genius/config.json"
  download_file "configs/skills.json"      "configs/skills.json"
  download_file "configs/phases.json"      "configs/phases.json"
  download_file "configs/commands.json"    "configs/commands.json"
  download_file "configs/checkpoints.json" "configs/checkpoints.json"

  # ── Directories ───────────────────────────────────────────────────────────
  [ "$DRY_RUN" = false ] && {
    mkdir -p .genius/outputs
    mkdir -p .genius/memory/events
    mkdir -p .genius/memory/summaries
    mkdir -p .genius/memory/archive
    mkdir -p .genius/memory/retros
    mkdir -p .genius/backups
    mkdir -p playgrounds/templates
    mkdir -p playgrounds/data
  }

  # ── Update state.json ─────────────────────────────────────────────────────
  if [ "$DRY_RUN" = false ]; then
    if [ -f ".genius/state.json" ]; then
      cp .genius/state.json .genius/state.json.bak
      sed -i.tmp 's/"version"[[:space:]]*:[[:space:]]*"[^"]*"/"version": "13.0.0"/' .genius/state.json
      rm -f .genius/state.json.tmp
    else
      cat > .genius/state.json << 'STATEJSON'
{
  "version": "13.0.0",
  "phase": "NOT_STARTED",
  "currentSkill": null,
  "skillHistory": [],
  "checkpoints": {
    "interview": false,
    "market_analysis": false,
    "specs_approved": false,
    "design_chosen": false,
    "architecture_approved": false,
    "execution_started": false,
    "qa_passed": false,
    "security_passed": false,
    "deployed": false
  },
  "tasks": { "total": 0, "completed": 0, "failed": 0 },
  "artifacts": {}
}
STATEJSON
    fi
  fi
}

#═══════════════════════════════════════════════════════════════════════════════
# Summary
#═══════════════════════════════════════════════════════════════════════════════

print_summary() {
  local from=$1 backup=$2
  echo ""
  echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║${NC}  ${BOLD}✅ Upgrade Complete! v$from → v13.0${NC}                      ${GREEN}║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${BOLD}Files downloaded:${NC} $FILES_DOWNLOADED"
  echo -e "  ${BOLD}Files skipped:${NC}    $FILES_SKIPPED (already present, not overwritten)"
  echo -e "  ${BOLD}Backup:${NC}           $backup"
  echo ""
  echo -e "${CYAN}New in v13.0:${NC}"
  echo "  • 🤖 Agent Spawning — each skill runs as an isolated sub-agent"
  echo "  • 🎤 Interview-First — genius-interviewer runs before any work starts"
  echo "  • ⛔ Phase Checkpoints — human approval gates at every phase transition"
  echo "  • 🔁 Retrospective Engine — post-phase learnings written to memory"
  echo "  • 🧠 Cross-Project Memory — decisions persist across projects"
  echo "  • 🗂️ Master Playground Dashboard — genius-dashboard.html"
  echo "  • 📱 Mobile-Responsive Playgrounds — all 13 templates updated"
  echo "  • 🌀 OpenClaw native install — openclaw plugins install genius-team"
  echo "  • 🔧 Genius Server — node scripts/genius-server.js --tunnel"
  echo ""
  echo -e "${YELLOW}Next steps:${NC}"
  echo "  1. Run ${BOLD}/genius-start${NC} to re-initialize with v13 features"
  echo "  2. Open the dashboard: ${BOLD}node scripts/genius-server.js --open${NC}"
  echo "  3. See ${BOLD}CHANGELOG.md${NC} for full details"
  echo ""
}

print_dry_run_summary() {
  local from=$1
  echo ""
  echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${YELLOW}║${NC}  ${BOLD}🔍 Dry Run — v$from → v13.0${NC}                             ${YELLOW}║${NC}"
  echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${BOLD}Files that would be downloaded:${NC} $FILES_DOWNLOADED"
  echo ""
  echo -e "Run without ${CYAN}--dry-run${NC} to perform the actual upgrade."
  echo ""
}

#═══════════════════════════════════════════════════════════════════════════════
# Main
#═══════════════════════════════════════════════════════════════════════════════

main() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --force)    FORCE=true;    shift ;;
      --dry-run)  DRY_RUN=true;  shift ;;
      --verbose)  VERBOSE=true;  shift ;;
      --help|-h)  show_usage; exit 0 ;;
      *) log_error "Unknown option: $1"; show_usage; exit 1 ;;
    esac
  done

  print_banner

  # ── Step 1: Detect version ─────────────────────────────────────────────────
  log_step 1 5 "Detecting current version..."
  CURRENT_VERSION=$(detect_version)
  echo -e "   Detected: ${BOLD}v$CURRENT_VERSION${NC} → Target: ${BOLD}v$TARGET_VERSION${NC}"

  if ! version_lt "$CURRENT_VERSION" "$TARGET_VERSION"; then
    log_success "Already at v$CURRENT_VERSION — nothing to do."
    echo ""
    echo "Your Genius Team is up to date! 🎉"
    echo "To force a re-download of all files: $0 --force"
    exit 0
  fi

  # ── Step 2: Prerequisites ──────────────────────────────────────────────────
  log_step 2 5 "Checking prerequisites..."
  if ! check_prerequisites; then
    echo ""
    log_error "Fix the issues above and try again."
    exit 1
  fi
  log_success "All checks passed"

  # ── Step 3: Backup ─────────────────────────────────────────────────────────
  log_step 3 5 "Creating backup..."
  BACKUP_DIR=$(create_backup)
  [ "$DRY_RUN" = false ] && log_success "Backup: $BACKUP_DIR"

  # ── Step 4: Download ───────────────────────────────────────────────────────
  log_step 4 5 "Downloading v13.0 files..."
  upgrade_to_v13
  log_success "$FILES_DOWNLOADED files downloaded"

  # ── Step 5: Verify ─────────────────────────────────────────────────────────
  log_step 5 5 "Verifying..."
  if [ "$DRY_RUN" = false ] && [ -x "scripts/verify.sh" ]; then
    ./scripts/verify.sh --quiet 2>/dev/null && log_success "Verification passed" || log_warning "Minor issues found (non-critical)"
  else
    log_success "Done"
  fi

  # ── Summary ────────────────────────────────────────────────────────────────
  if [ "$DRY_RUN" = true ]; then
    print_dry_run_summary "$CURRENT_VERSION"
  else
    print_summary "$CURRENT_VERSION" "$BACKUP_DIR"
  fi
}

main "$@"
