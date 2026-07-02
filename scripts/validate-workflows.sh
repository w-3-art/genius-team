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

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ERRORS" -gt 0 ]; then
  echo "❌ FAIL: $ERRORS problem(s)"
  exit 1
else
  echo "✅ PASS — exactly one workflow entry per skill directory"
  exit 0
fi
