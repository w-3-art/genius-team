#!/usr/bin/env bash
#
# generate-doctrine.sh — Regenerate doctrinal files from the single source.
#
# DOCTRINE SINGLE-SOURCE (P5-04):
#   - The GT version lives in ONE place: the VERSION file. It is injected
#     everywhere (package.json + every doctrinal Markdown header).
#   - The canonical doctrine fragments live in templates/doctrine/*.md.
#     .genius/GT-WORKFLOW.md (the file shipped verbatim into every project by
#     scripts/add.sh) is GENERATED from templates/doctrine/, never hand-edited.
#
# Usage:
#   scripts/generate-doctrine.sh            # regenerate targets in place
#   scripts/generate-doctrine.sh --check    # fail (exit 1) if regen would change anything
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCTRINE_DIR="${REPO_ROOT}/templates/doctrine"

CHECK_MODE=0
[ "${1:-}" = "--check" ] && CHECK_MODE=1

# ── Single source of the version ────────────────────────────────────────────
VERSION_FULL="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"
if ! printf '%s' "$VERSION_FULL" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "❌ VERSION must be semver (major.minor.patch); got: '${VERSION_FULL}'" >&2
  exit 1
fi
VERSION_MAJOR="${VERSION_FULL%%.*}"
VERSION_REST="${VERSION_FULL#*.}"
VERSION_MINOR="${VERSION_REST%%.*}"
VERSION_DISPLAY="v${VERSION_MAJOR}.${VERSION_MINOR}"

# ── Fragment renderer: expand {{INCLUDE:file}} and {{VERSION_*}} tokens ──────
# Reads a template file on stdin arg $1, prints the rendered result to stdout.
render() {
  local file="$1" line inc
  while IFS='' read -r line || [ -n "$line" ]; do
    case "$line" in
      '{{INCLUDE:'*'}}')
        inc="${line#'{{INCLUDE:'}"
        inc="${inc%'}}'}"
        if [ ! -f "${DOCTRINE_DIR}/${inc}" ]; then
          echo "❌ Missing doctrine fragment: templates/doctrine/${inc}" >&2
          exit 1
        fi
        render "${DOCTRINE_DIR}/${inc}"
        ;;
      *)
        line="${line//'{{VERSION_DISPLAY}}'/$VERSION_DISPLAY}"
        line="${line//'{{VERSION_FULL}}'/$VERSION_FULL}"
        printf '%s\n' "$line"
        ;;
    esac
  done < "$file"
}

GEN_HEADER=$(cat <<EOF
<!-- ============================================================
     GENERATED — edit templates/doctrine/, not this file.
     Source:      templates/doctrine/GT-WORKFLOW.template.md
     Fragments:   templates/doctrine/*.md
     Regenerate:  scripts/generate-doctrine.sh
     Version:     VERSION (single source of truth) → ${VERSION_DISPLAY}
     ============================================================ -->
EOF
)

# ── Build the desired content for GT-WORKFLOW.md ────────────────────────────
render_gt_workflow() {
  printf '%s\n\n' "$GEN_HEADER"
  render "${DOCTRINE_DIR}/GT-WORKFLOW.template.md"
}

# ── Version normalization for the other doctrinal Markdown headers ──────────
# Only the version token changes; all other content is preserved byte-for-byte.
# The VERSION file is the single source, so every "Genius Team vX.Y" reference
# is rewritten to match it (this closes drifts like GENIUS_GUARD.md's v18.0).
VERSION_TARGETS=(
  "CLAUDE.md"
  "configs/cli/CLAUDE.md"
  "configs/ide/CLAUDE.md"
  "configs/dual/CLAUDE.md"
  "configs/omni/CLAUDE.md"
  "AGENTS.md"
  "README.md"
  "GENIUS_GUARD.md"
)

normalize_version_stdout() {
  # $1 = file path; prints normalized content to stdout
  sed -E "s/Genius Team v[0-9]+\.[0-9]+/Genius Team ${VERSION_DISPLAY}/g" "$1"
}

sync_package_json_stdout() {
  sed -E "s/(\"version\"[[:space:]]*:[[:space:]]*\")[0-9]+\.[0-9]+\.[0-9]+(\")/\1${VERSION_FULL}\2/" "${REPO_ROOT}/package.json"
}

# ── Apply or check ──────────────────────────────────────────────────────────
DRIFT=0

emit() {
  # $1 = target path (relative to repo root); reads desired content from stdin
  local rel="$1" abs="${REPO_ROOT}/$1" desired
  desired="$(cat)"
  if [ ! -f "$abs" ] || [ "$desired" != "$(cat "$abs")" ]; then
    if [ "$CHECK_MODE" -eq 1 ]; then
      echo "⚠️  drift: $rel would change"
      DRIFT=1
    else
      printf '%s\n' "$desired" > "$abs"
      echo "↻ regenerated $rel"
    fi
  else
    echo "✓ up to date: $rel"
  fi
}

# NOTE: emit reads stdin via process substitution (not a pipe) so it runs in
# THIS shell — a pipe would fork a subshell and lose the DRIFT flag.
emit ".genius/GT-WORKFLOW.md" < <(render_gt_workflow)
emit "package.json"          < <(sync_package_json_stdout)
for t in "${VERSION_TARGETS[@]}"; do
  emit "$t" < <(normalize_version_stdout "${REPO_ROOT}/${t}")
done

if [ "$CHECK_MODE" -eq 1 ] && [ "$DRIFT" -eq 1 ]; then
  echo ""
  echo "❌ doctrine drift detected — run scripts/generate-doctrine.sh and commit the result." >&2
  exit 1
fi

echo ""
echo "✅ doctrine in sync (version ${VERSION_FULL} / ${VERSION_DISPLAY})"
