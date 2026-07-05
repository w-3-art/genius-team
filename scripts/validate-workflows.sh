#!/usr/bin/env bash
# validate-workflows.sh — Check templates/workflows.json has exactly one entry
# per .claude/skills/ directory (no duplicates, no missing, no orphans).
# Part of Genius Team Phase 4 cleanup (P4-C1).

set -euo pipefail

SKILLS_DIR=".claude/skills"
WORKFLOWS_JSON="templates/workflows.json"
ERRORS=0

echo "🔍 Validating templates/workflows.json against ${SKILLS_DIR}..."
echo ""

if [ ! -f "$WORKFLOWS_JSON" ]; then
  echo "❌ ${WORKFLOWS_JSON} not found"
  exit 1
fi

if ! jq empty "$WORKFLOWS_JSON" >/dev/null 2>&1; then
  echo "❌ ${WORKFLOWS_JSON} is not valid JSON"
  exit 1
fi

SKILL_DIRS_SORTED=$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -u)
WF_NAMES_RAW=$(jq -r '.workflows[][].name' "$WORKFLOWS_JSON")
WF_NAMES_SORTED=$(printf '%s\n' "$WF_NAMES_RAW" | sort -u)

n_dirs=$(printf '%s\n' "$SKILL_DIRS_SORTED" | grep -c .)
n_entries=$(printf '%s\n' "$WF_NAMES_RAW" | grep -c .)

echo "skills directories: ${n_dirs}"
echo "workflow entries:    ${n_entries}"
echo ""

# Duplicates: any name appearing more than once
dupes=$(printf '%s\n' "$WF_NAMES_RAW" | sort | uniq -d)
if [ -n "$dupes" ]; then
  echo "❌ duplicate workflow entries:"
  echo "$dupes" | sed 's/^/   - /'
  ERRORS=$((ERRORS + 1))
fi

# Directories with no workflow entry
missing=$(comm -23 <(printf '%s\n' "$SKILL_DIRS_SORTED") <(printf '%s\n' "$WF_NAMES_SORTED"))
if [ -n "$missing" ]; then
  echo "❌ skill directories missing a workflow entry:"
  echo "$missing" | sed 's/^/   - /'
  ERRORS=$((ERRORS + 1))
fi

# Workflow entries with no matching directory (orphans)
orphans=$(comm -13 <(printf '%s\n' "$SKILL_DIRS_SORTED") <(printf '%s\n' "$WF_NAMES_SORTED"))
if [ -n "$orphans" ]; then
  echo "❌ workflow entries with no matching skill directory:"
  echo "$orphans" | sed 's/^/   - /'
  ERRORS=$((ERRORS + 1))
fi

# ── Prose skill-count drift guard ───────────────────────────────────────────
# Current-state "N skills" claims in these canonical docs must equal n_dirs.
# Historical mentions (CHANGELOG, analysis docs) are intentionally NOT checked —
# only these authoritative current-state strings, so old counts never trip this.
check_prose_count() {
  # $1=label  $2=file  $3=ERE matching the count phrase (with the number)
  local label="$1" file="$2" re="$3" got
  got=$(grep -oiE "$re" "$file" 2>/dev/null | grep -oE '[0-9]+' | head -1 || true)
  if [ -z "$got" ]; then
    echo "❌ ${label}: expected skill-count phrase not found in ${file}"
    ERRORS=$((ERRORS + 1))
  elif [ "$got" != "$n_dirs" ]; then
    echo "❌ ${label}: says ${got} skills but ${n_dirs} skill dirs exist (${file})"
    ERRORS=$((ERRORS + 1))
  fi
}

check_prose_count "README header"   "README.md"                          '## [0-9]+ Specialized Skills'
check_prose_count "README registry" "README.md"                          'for all [0-9]+ skills'
check_prose_count "SKILLS.md"        "docs/SKILLS.md"                     'consists of [0-9]+ specialized skills'
check_prose_count "genius-tips"      ".claude/skills/genius-tips/SKILL.md" 'are [0-9]+ specialized skills'

readme_rows=$(grep -cE '^\| genius-' README.md || true)
if [ "$readme_rows" != "$n_dirs" ]; then
  echo "❌ README skill table has ${readme_rows} rows but ${n_dirs} skill dirs exist"
  ERRORS=$((ERRORS + 1))
fi

# SessionStart banner drift: every mode config prints "Version: … | N skills | …"
# live at each session start. That N must equal n_dirs too (this string is not
# covered by check_prose_count above, and CI never boots a session).
for cfg in configs/*/settings.json; do
  [ -f "$cfg" ] || continue
  got=$(grep -oE '[0-9]+ skills' "$cfg" 2>/dev/null | grep -oE '[0-9]+' | head -1 || true)
  if [ -z "$got" ]; then
    echo "❌ ${cfg}: no 'N skills' banner found in SessionStart hook"
    ERRORS=$((ERRORS + 1))
  elif [ "$got" != "$n_dirs" ]; then
    echo "❌ ${cfg}: banner says ${got} skills but ${n_dirs} skill dirs exist"
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ERRORS" -gt 0 ]; then
  echo "❌ FAIL: $ERRORS problem(s)"
  exit 1
else
  echo "✅ PASS — workflow/skill 1:1 match and prose skill-counts in sync"
  exit 0
fi
