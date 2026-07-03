#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Genius Team v22.0 — Add to Existing Project
# Usage: cd your-project && bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/add.sh) [--mode cli|ide|omni|dual] [--engine claude|codex|dual]
# ═══════════════════════════════════════════════════════════════
set -e

# Colors (degrade gracefully)
if [ -t 1 ] && command -v tput &>/dev/null && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
  GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
  BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'
  DIM='\033[2m'; NC='\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; BLUE=''; CYAN=''; BOLD=''; DIM=''; NC=''
fi

# ── Helpers ──────────────────────────────────────────────────
info()  { echo -e "${BLUE}ℹ${NC}  $1"; }
ok()    { echo -e "${GREEN}✓${NC}  $1"; }
warn()  { echo -e "${YELLOW}⚠${NC}  $1"; }
fail()  { echo -e "${RED}✗${NC}  $1"; }
die()   { echo -e "\n${RED}ERROR:${NC} $1" >&2; exit 1; }

resolve_local_source() {
  if [ -n "${GENIUS_TEAM_SOURCE_DIR:-}" ] && [ -f "${GENIUS_TEAM_SOURCE_DIR}/VERSION" ] && [ -f "${GENIUS_TEAM_SOURCE_DIR}/scripts/setup.sh" ]; then
    printf '%s' "$GENIUS_TEAM_SOURCE_DIR"
    return 0
  fi

  case "${BASH_SOURCE[0]}" in
    /dev/fd/*|/proc/self/fd/*) return 1 ;;
  esac

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "${script_dir}/../VERSION" ] && [ -f "${script_dir}/setup.sh" ]; then
    (cd "${script_dir}/.." && pwd)
    return 0
  fi

  return 1
}

# ── Bootstrap manifest helpers ("installed with evidence, not hope") ──
_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" 2>/dev/null | awk '{print $1}';
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" 2>/dev/null | awk '{print $1}';
  else echo "UNKNOWN"; fi
}

# Normalized (no leading ./), sorted list of files, excluding VCS/deps.
_snapshot() {
  find . -type f \
    -not -path './.git/*' \
    -not -path './node_modules/*' \
    2>/dev/null | sed 's#^\./##' | sort
}

# Files that legitimately change after install — runtime state + user-owned
# docs/overlays. These are still recorded (with their install-time sha) but are
# not treated as tampering by `verify.sh --manifest`.
_is_mutable() {
  echo "$1" | grep -qE '^\.genius/(state\.json|session-log\.jsonl|DASHBOARD\.html|config\.json|mode\.json|workflows\.json|dual-engine-state\.json|install-manifest\.json)$|^\.genius/(outputs|memory|wiki)/|^(CLAUDE\.md|AGENTS\.md|\.gitignore)$|^\.claude/settings\.(local\.json|json\.previous)$'
}

# write_install_manifest <origin> <mode> <engine> <added_newline_list> <modified_newline_list>
write_install_manifest() {
  local origin="$1" m_mode="$2" m_engine="$3" added="$4" modified="$5"
  command -v jq >/dev/null 2>&1 || { warn "jq not found — skipping install manifest"; return 0; }
  mkdir -p .genius
  local now ver tsv mtsv files_json modified_json hooks_json
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  ver="$(cat VERSION 2>/dev/null || echo unknown)"
  tsv="$(mktemp)"; : > "$tsv"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ "$f" = ".genius/install-manifest.json" ] && continue
    [ -f "$f" ] || continue
    local mut=false
    _is_mutable "$f" && mut=true
    printf '%s\t%s\t%s\n' "$f" "$(_sha256 "$f")" "$mut" >> "$tsv"
  done <<< "$added"
  files_json="$(jq -R -s --arg origin "$origin" '
    split("\n") | map(select(length>0)) | map(split("\t")) |
    map({path:.[0], sha256:.[1], origin:$origin, mutable:(.[2]=="true")})' "$tsv")"
  rm -f "$tsv"
  mtsv="$(mktemp)"; : > "$mtsv"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    printf '%s\n' "$f" >> "$mtsv"
  done <<< "$modified"
  modified_json="$(jq -R -s --arg origin "$origin" '
    split("\n") | map(select(length>0)) | map({path:., origin:$origin})' "$mtsv")"
  rm -f "$mtsv"
  if [ -f .claude/settings.json ]; then
    hooks_json="$(jq -c '.hooks // {}' .claude/settings.json 2>/dev/null || echo '{}')"
  else
    hooks_json='{}'
  fi
  local webhook_url consent consented dests
  webhook_url="${GENIUS_WEBHOOK_URL:-}"
  consent="${GENIUS_WEBHOOK_CONSENT:-}"
  consented=false; dests='[]'
  if [ -n "$webhook_url" ] && { [ "$consent" = "1" ] || [ "$consent" = "true" ]; } && [ "${webhook_url#https://}" != "$webhook_url" ]; then
    consented=true
    dests="$(jq -cn --arg u "$webhook_url" '[$u]')"
  fi
  jq -n \
    --arg gtv "$ver" --arg now "$now" --arg origin "$origin" \
    --arg mode "$m_mode" --arg engine "$m_engine" --arg target "$(pwd)" \
    --argjson files "$files_json" --argjson modified "$modified_json" \
    --argjson hooks "$hooks_json" --argjson consented "$consented" --argjson dests "$dests" \
    '{
      manifestVersion: 1,
      gtVersion: $gtv,
      installedAt: $now,
      origin: $origin,
      mode: $mode,
      engine: $engine,
      targetDir: $target,
      files: $files,
      modified: $modified,
      hooks: $hooks,
      network: { webhookConsented: $consented, destinations: $dests }
    }' > .genius/install-manifest.json
}

# ── Parse Arguments ──────────────────────────────────────────
MODE="cli"
ENGINE="claude"
BRANCH="${GENIUS_TEAM_BRANCH:-main}"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --mode)   MODE="$2"; shift 2 ;;
    --mode=*) MODE="${1#*=}"; shift ;;
    --engine)   ENGINE="$2"; shift 2 ;;
    --engine=*) ENGINE="${1#*=}"; shift ;;
    --branch)   BRANCH="$2"; shift 2 ;;
    --branch=*) BRANCH="${1#*=}"; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help)
      echo "Usage: cd your-project && bash <(curl -fsSL URL) [--mode cli|ide|omni|dual] [--engine claude|codex|dual] [--branch BRANCH] [--dry-run]"
      echo ""
      echo "  --mode MODE      Setup mode: cli (default), ide, omni, dual"
      echo "  --engine ENGINE  AI engine: claude (default), codex, dual"
      echo "  --branch BRANCH  GT branch to install from (default: main)"
      echo "                   Also settable via GENIUS_TEAM_BRANCH env var"
      echo "  --dry-run        List every file that WOULD be written/modified, then exit"
      echo "                   (simulated in a throwaway sandbox — no changes made)"
      echo ""
      echo "Run this from INSIDE your existing project directory."
      exit 0
      ;;
    -*)  die "Unknown option: $1" ;;
    *)   die "Unexpected argument: $1\nRun this from inside your project directory: cd your-project && bash <(curl ...) --mode cli" ;;
  esac
done

# Validate mode
if [[ ! "$MODE" =~ ^(cli|ide|omni|dual)$ ]]; then
  die "Invalid mode: ${MODE}\nValid modes: cli, ide, omni, dual"
fi

# Validate engine
if [[ ! "$ENGINE" =~ ^(claude|codex|dual)$ ]]; then
  die "Invalid engine: ${ENGINE}\nValid engines: claude, codex, dual"
fi

# ── Banner ───────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  🧠 Genius Team v22.0 — Add to Existing Project  ║${NC}"
echo -e "${BOLD}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Target:  ${CYAN}$(pwd)${NC}"
echo -e "  Mode:    ${CYAN}${MODE}${NC}"
echo -e "  Engine:  ${CYAN}${ENGINE}${NC}"
echo -e "  Branch:  ${CYAN}${BRANCH}${NC}"
echo ""

# ── Pre-flight Checks ───────────────────────────────────────
command -v git &>/dev/null || die "Git is not installed. Please install git first.\n  macOS: xcode-select --install\n  Linux: sudo apt install git"

# Check we're in a project directory (not home or root)
if [ "$(pwd)" = "$HOME" ] || [ "$(pwd)" = "/" ]; then
  die "You appear to be in your home or root directory.\nPlease navigate to your project: cd your-project"
fi

# Soft check: warn if not in a git repo, but don't fail
if ! git rev-parse --git-dir &>/dev/null 2>&1; then
  warn "Current directory is not a git repository. Genius Team works best with git."
  echo -e "     Consider running: ${CYAN}git init${NC}"
  echo ""
fi

# ── Resolve Genius Team source ──────────────────────────────
GENIUS_SRC=""
TMPDIR_GT=""
if GENIUS_SRC="$(resolve_local_source)"; then
  info "Using local Genius Team source: ${GENIUS_SRC}"
  ok "Local source ready"
else
  # Quick connectivity check
  if ! git ls-remote https://github.com/w-3-art/genius-team.git HEAD &>/dev/null 2>&1; then
    die "Cannot reach GitHub. Check your internet connection."
  fi

  TMPDIR_GT=$(mktemp -d)
  trap 'rm -rf "${TMPDIR_GT}"' EXIT

  info "Downloading Genius Team files (branch: ${BRANCH})..."
  if ! git clone --quiet --branch "$BRANCH" --single-branch https://github.com/w-3-art/genius-team.git "${TMPDIR_GT}/genius" 2>/dev/null; then
    die "Git clone failed. Either branch '${BRANCH}' does not exist on the remote, or there is no internet connection."
  fi
  ok "Downloaded Genius Team (branch: ${BRANCH})"
  GENIUS_SRC="${TMPDIR_GT}/genius"
fi

# ── Dry-run: show EXACTLY what would be written/modified (no changes) ──
# Faithful, evidence-based plan: run the real install in a throwaway sandbox
# seeded with a copy of this project, diff before/after, then discard it.
if [ "$DRY_RUN" = true ]; then
  ADD_SELF="${BASH_SOURCE[0]}"
  case "$ADD_SELF" in
    /dev/fd/*|/proc/*) ADD_SELF="${GENIUS_SRC}/scripts/add.sh" ;;
  esac
  [ -f "$ADD_SELF" ] || ADD_SELF="${GENIUS_SRC}/scripts/add.sh"

  info "DRY RUN — simulating install in a throwaway sandbox (no changes to $(pwd))"
  SANDBOX="$(mktemp -d)"
  if ! tar cf - --exclude='./.git' --exclude='./node_modules' . 2>/dev/null | ( cd "$SANDBOX" && tar xf - ) 2>/dev/null; then
    cp -R ./. "$SANDBOX"/ 2>/dev/null || true
  fi
  DR_BEFORE="$(mktemp)"; ( cd "$SANDBOX" && _snapshot ) > "$DR_BEFORE"
  if ( cd "$SANDBOX" && GENIUS_TEAM_SOURCE_DIR="$GENIUS_SRC" bash "$ADD_SELF" --mode "$MODE" --engine "$ENGINE" ) >/dev/null 2>&1; then
    DR_OK=true
  else
    DR_OK=false
  fi
  DR_AFTER="$(mktemp)"; ( cd "$SANDBOX" && _snapshot ) > "$DR_AFTER"

  echo ""
  echo -e "${BOLD}Files that WOULD be added:${NC}"
  comm -13 "$DR_BEFORE" "$DR_AFTER" | sed 's/^/  + /' || true
  echo ""
  echo -e "${BOLD}Files that WOULD be modified in place:${NC}"
  comm -12 "$DR_BEFORE" "$DR_AFTER" | while IFS= read -r f; do
    [ -z "$f" ] && continue
    if ! cmp -s "$SANDBOX/$f" "./$f" 2>/dev/null; then
      echo "  ~ $f"
    fi
  done || true
  echo ""
  [ "$DR_OK" = true ] || warn "Sandbox install exited non-zero (dependency missing?); the list above may be partial."
  info "No changes were made to your project. Re-run without --dry-run to install."
  rm -rf "$SANDBOX" "$DR_BEFORE" "$DR_AFTER"
  exit 0
fi

# ── HARD EXCLUSION: Prevent product site HTML/docs leakage (Vercel bug fix) ──
if [ -d "${GENIUS_SRC}/docs" ]; then
  info "Excluding /docs/ (product site HTML + vercel.json) — prevents Vercel deploy pollution in target repo"
fi
if [ -d "${GENIUS_SRC}/site" ]; then
  info "Excluding /site/ (future product site)"
fi

# ── Snapshot BEFORE any writes (for the install manifest) ────
SNAP_BEFORE="$(mktemp)"
_snapshot > "$SNAP_BEFORE"

# ── Copy files (without overwriting) ────────────────────────
info "Copying Genius Team files to your project..."
COPIED=0
SKIPPED=0

copy_file() {
  local src="$1"
  local dst="$2"
  if [ -e "$dst" ]; then
    warn "Skipping $(basename "$dst") — already exists"
    ((SKIPPED++)) || true
  else
    cp -r "$src" "$dst"
    ok "Added $(basename "$dst")"
    ((COPIED++)) || true
  fi
}

copy_dir() {
  local src="$1"
  local dst="$2"
  if [ -d "$dst" ]; then
    # Merge: copy only files that don't exist yet
    find "$src" -type f | while read -r file; do
      # HARD EXCLUSION for product site (Vercel bug fix)
      if [[ "$file" == *"/docs/"* || "$file" == *"/site/"* || "$file" == *.html || "$file" == */vercel.json ]]; then
        continue
      fi
      local rel="${file#$src/}"
      local target="$dst/$rel"
      if [ ! -e "$target" ]; then
        mkdir -p "$(dirname "$target")"
        cp "$file" "$target"
        ((COPIED++)) || true
      else
        ((SKIPPED++)) || true
      fi
    done
    ok "Merged ${CYAN}$(basename "$dst")/${NC} (skipped existing files + docs/site/HTML)"
  else
    # For full dir copy, also exclude
    if [[ "$(basename "$src")" == "docs" || "$(basename "$src")" == "site" ]]; then
      ok "Skipped ${CYAN}$(basename "$src")/${NC} (product site — Vercel pollution prevention)"
      return
    fi
    cp -r "$src" "$dst"
    ok "Added ${CYAN}$(basename "$dst")/${NC}"
    ((COPIED++)) || true
  fi
}

# ── GT-WORKFLOW.md (framework doctrine — GT-owned, always overwritten) ──
mkdir -p .genius
if [ -f "${GENIUS_SRC}/.genius/GT-WORKFLOW.md" ]; then
  cp "${GENIUS_SRC}/.genius/GT-WORKFLOW.md" ".genius/GT-WORKFLOW.md"
  ok "Installed ${CYAN}.genius/GT-WORKFLOW.md${NC} (framework doctrine, auto-updated)"
  ((COPIED++)) || true
fi

# ── CLAUDE.md (project-owned — NEVER overwritten after first install) ──
if [ -f "./CLAUDE.md" ]; then
  if grep -q "^@\\.genius/GT-WORKFLOW\\.md" CLAUDE.md; then
    ok "CLAUDE.md already imports GT-WORKFLOW — left untouched"
    ((SKIPPED++)) || true
  else
    # Non-destructive: inject the import line at the very top.
    tmp=$(mktemp)
    printf "@.genius/GT-WORKFLOW.md\n\n" > "$tmp"
    cat CLAUDE.md >> "$tmp"
    mv "$tmp" CLAUDE.md
    ok "CLAUDE.md preserved — prepended ${CYAN}@.genius/GT-WORKFLOW.md${NC} import"
    ((COPIED++)) || true
  fi
else
  # Fresh project: install the project-facing template
  if [ -f "${GENIUS_SRC}/templates/CLAUDE.project.md" ]; then
    cp "${GENIUS_SRC}/templates/CLAUDE.project.md" "./CLAUDE.md"
    ok "Installed ${CYAN}CLAUDE.md${NC} (project template with GT-WORKFLOW import)"
    ((COPIED++)) || true
  else
    # Legacy fallback (should not happen in v22+)
    cp "${GENIUS_SRC}/CLAUDE.md" "./CLAUDE.md"
    ok "Installed legacy CLAUDE.md (framework + project merged)"
    ((COPIED++)) || true
  fi
fi

# ── .claude (skills, rules, agents — GT-owned files + user overlay) ──
copy_dir  "${GENIUS_SRC}/.claude"         "./.claude"

# ── .claude/settings.local.json (user overlay — GITIGNORED, never touched) ──
if [ ! -f ".claude/settings.local.json" ]; then
  mkdir -p .claude
  cat > .claude/settings.local.json <<'LOCAL_JSON'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [],
    "deny": []
  },
  "hooks": {},
  "env": {}
}
LOCAL_JSON
  ok "Created ${CYAN}.claude/settings.local.json${NC} (your overlay, gitignored)"
  ((COPIED++)) || true
fi

# Ensure settings.local.json is gitignored
if [ -f ".gitignore" ]; then
  if ! grep -qE "^\\.claude/settings\\.local\\.json$" .gitignore 2>/dev/null; then
    printf "\n# Genius Team user overlay (personal customizations)\n.claude/settings.local.json\n" >> .gitignore
    ok "Added ${CYAN}.claude/settings.local.json${NC} to .gitignore"
  fi
else
  cat > .gitignore <<'GITIGN'
# Genius Team user overlay (personal customizations)
.claude/settings.local.json
GITIGN
  ok "Created .gitignore with ${CYAN}.claude/settings.local.json${NC} entry"
fi
# Scripts: ALWAYS overwrite (critical for upgrades to work)
if [ -d "./scripts" ]; then
  cp -r "${GENIUS_SRC}/scripts/"* "./scripts/"
  ok "Updated ${CYAN}scripts/${NC} (force-overwrite)"
  ((COPIED++)) || true
else
  cp -r "${GENIUS_SRC}/scripts" "./scripts"
  ok "Added ${CYAN}scripts/${NC}"
  ((COPIED++)) || true
fi

# Configs: ALWAYS overwrite (mode settings must match latest version)
if [ -d "./configs" ]; then
  cp -r "${GENIUS_SRC}/configs/"* "./configs/"
  ok "Updated ${CYAN}configs/${NC} (force-overwrite)"
  ((COPIED++)) || true
else
  cp -r "${GENIUS_SRC}/configs" "./configs"
  ok "Added ${CYAN}configs/${NC}"
  ((COPIED++)) || true
fi
copy_file "${GENIUS_SRC}/GENIUS_GUARD.md" "./GENIUS_GUARD.md"
copy_file "${GENIUS_SRC}/VERSION"         "./VERSION"

# Templates (needed for dual-bridge etc.)
[ -d "${GENIUS_SRC}/templates" ] && copy_dir "${GENIUS_SRC}/templates" "./templates"

# Optional but useful
[ -f "${GENIUS_SRC}/MEMORY-SYSTEM.md" ] && copy_file "${GENIUS_SRC}/MEMORY-SYSTEM.md" "./MEMORY-SYSTEM.md"

echo ""
echo -e "  ${DIM}Copied: ${COPIED} files | Skipped (already exist): ${SKIPPED} files${NC}"
echo ""

# ── Run Setup ────────────────────────────────────────────────
info "Running setup (${MODE} mode, ${ENGINE} engine)..."
echo ""
chmod +x scripts/setup.sh
./scripts/setup.sh --mode "$MODE" --engine "$ENGINE"
echo ""

# ── Install manifest ("installed with evidence, not hope") ───
SNAP_AFTER="$(mktemp)"
_snapshot > "$SNAP_AFTER"
ADDED_LIST="$(comm -13 "$SNAP_BEFORE" "$SNAP_AFTER")"
MODIFIED_LIST=""
for f in CLAUDE.md .gitignore .claude/settings.json; do
  if grep -qxF "$f" "$SNAP_BEFORE" 2>/dev/null; then
    MODIFIED_LIST+="$f"$'\n'
  fi
done
write_install_manifest "add.sh" "$MODE" "$ENGINE" "$ADDED_LIST" "$MODIFIED_LIST"
ok "Wrote ${CYAN}.genius/install-manifest.json${NC} ($(printf '%s\n' "$ADDED_LIST" | grep -c . || true) files recorded)"
rm -f "$SNAP_BEFORE" "$SNAP_AFTER"
echo ""

# ── Done ─────────────────────────────────────────────────────
echo -e "${BOLD}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  🧠 Genius Team v22.0 — Ready!                   ║${NC}"
echo -e "${BOLD}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Genius Team has been added to your existing project."
echo ""

# Engine-specific next steps
if [[ "$ENGINE" == "codex" ]]; then
  echo -e "  ${BOLD}Next steps:${NC}"
  echo -e "  1. Run ${CYAN}codex${NC}"
  echo -e "  2. Codex reads AGENTS.md automatically"
  echo -e "  3. Tell it what you want to build! 🚀"
elif [[ "$ENGINE" == "dual" ]]; then
  echo -e "  ${BOLD}Next steps:${NC}"
  echo -e "  1. Add commands to PATH: ${CYAN}export PATH=\"$PWD/.genius/bin:\$PATH\"${NC}"
  echo -e "  2. For Claude: Run ${CYAN}claude${NC} → ${CYAN}/genius-start${NC}"
  echo -e "  3. For Codex:  Run ${CYAN}codex${NC} (reads AGENTS.md)"
  echo -e "  4. Tell it what you want to build! 🚀"
else
  case "$MODE" in
    cli|omni|dual)
      echo -e "  ${BOLD}Next steps:${NC}"
      echo -e "  1. Run ${CYAN}claude${NC}"
      echo -e "  2. Or from the shell: ${CYAN}genius-start${NC}"
      echo -e "  3. Tell it what you want to build! 🚀"
      ;;
    ide)
      echo -e "  ${BOLD}Next steps:${NC}"
      echo -e "  1. Open this folder in ${CYAN}VS Code${NC} or ${CYAN}Cursor${NC}"
      echo -e "  2. Start Claude Code ${DIM}(Cmd+Shift+P → \"Claude Code: Open\")${NC}"
      echo -e "  3. Type ${CYAN}/genius-start${NC} or run ${CYAN}genius-start${NC} from the shell"
      echo -e "  4. Tell it what you want to build! 🚀"
      ;;
  esac
fi

echo ""
echo -e "${DIM}─────────────────────────────────────────────────────${NC}"
echo -e "  📁 Project: ${CYAN}$(pwd)${NC}"
echo -e "  📖 Docs:    ${CYAN}docs/GETTING-STARTED.md${NC}"
echo -e "  🌐 GitHub:  ${CYAN}https://github.com/w-3-art/genius-team${NC}"
echo -e "${DIM}─────────────────────────────────────────────────────${NC}"
echo ""
echo -e "  ${GREEN}Happy building! 🧠✨${NC}"
echo ""
