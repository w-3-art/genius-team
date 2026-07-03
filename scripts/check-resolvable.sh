#!/usr/bin/env bash
# check-resolvable.sh — Every skill reference resolves.
#
# Fails (exit 1) if any of these invariants break:
#   1. Each .claude/skills/<dir>/ has a SKILL.md whose frontmatter carries a
#      parseable name + description, and name == <dir>.
#   2. templates/workflows.json is valid JSON, every entry .name maps to an
#      existing skill dir, and every skill dir has exactly one entry (both ways).
#   3. Every `references/<file>.md` linked from a SKILL.md exists on disk
#      (this includes the reference files split out by P4-03).
# Orphan reference files (present but unlinked) are reported as warnings only,
# so P4-03 output is validated, never broken.
#
# Part of Genius Team Phase 4 (P4-04).

set -euo pipefail

cd "$(dirname "$0")/.."

SKILLS_DIR=".claude/skills" WORKFLOWS_JSON="templates/workflows.json" python3 - <<'PY'
import os, re, json, sys

SKILLS_DIR = os.environ["SKILLS_DIR"]
WORKFLOWS_JSON = os.environ["WORKFLOWS_JSON"]

errors = []
warnings = []

def parse_frontmatter(path):
    t = open(path, encoding="utf-8").read()
    m = re.match(r'^---\n(.*?)\n---', t, re.S)
    if not m:
        return None, None, t
    fm = m.group(1)
    name = re.search(r'^name:\s*(.+?)\s*$', fm, re.M)
    dm = re.search(r'^description:\s*(?:>[-]?|\|[-]?)?\s*\n((?:[ \t]+.*\n?)+)', fm, re.M)
    if dm:
        desc = " ".join(l.strip() for l in dm.group(1).splitlines()).strip()
    else:
        dm2 = re.search(r'^description:\s*(.+?)\s*$', fm, re.M)
        desc = dm2.group(1).strip() if dm2 else ""
    return (name.group(1).strip() if name else None), (desc or None), t

# --- 1. Frontmatter parseable + name matches dir --------------------------
skill_dirs = sorted(
    d for d in os.listdir(SKILLS_DIR)
    if os.path.isdir(os.path.join(SKILLS_DIR, d))
)
skill_bodies = {}
for d in skill_dirs:
    path = os.path.join(SKILLS_DIR, d, "SKILL.md")
    if not os.path.isfile(path):
        errors.append(f"[frontmatter] {d}: SKILL.md missing")
        continue
    name, desc, body = parse_frontmatter(path)
    skill_bodies[d] = body
    if name is None:
        errors.append(f"[frontmatter] {d}: no parseable name in frontmatter")
    elif name != d:
        errors.append(f"[frontmatter] {d}: name '{name}' does not match directory")
    if desc is None:
        errors.append(f"[frontmatter] {d}: no parseable description in frontmatter")

# --- 2. workflows.json <-> skill dirs (both directions) -------------------
if not os.path.isfile(WORKFLOWS_JSON):
    errors.append(f"[workflows] {WORKFLOWS_JSON} not found")
else:
    try:
        wf = json.load(open(WORKFLOWS_JSON, encoding="utf-8"))
    except Exception as e:
        wf = None
        errors.append(f"[workflows] {WORKFLOWS_JSON} invalid JSON: {e}")
    if wf is not None:
        wf_names = []
        for _cat, entries in wf.get("workflows", {}).items():
            for entry in entries:
                nm = entry.get("name")
                if nm:
                    wf_names.append(nm)
        dupes = sorted({n for n in wf_names if wf_names.count(n) > 1})
        for n in dupes:
            errors.append(f"[workflows] duplicate entry: {n}")
        dirset, nameset = set(skill_dirs), set(wf_names)
        for n in sorted(nameset - dirset):
            errors.append(f"[workflows] entry '{n}' has no matching skill directory")
        for d in sorted(dirset - nameset):
            errors.append(f"[workflows] skill directory '{d}' has no workflow entry")

# --- 3. references/*.md links resolve -------------------------------------
linked = set()  # (skill_dir, relative_ref_path)
ref_re = re.compile(r'references/[A-Za-z0-9._-]+\.md')
for d, body in skill_bodies.items():
    for rel in ref_re.findall(body):
        linked.add((d, rel))
        target = os.path.join(SKILLS_DIR, d, rel)
        if not os.path.isfile(target):
            errors.append(f"[references] {d}/SKILL.md links '{rel}' but it is missing")

# Orphan reference files on disk that no SKILL.md links (warning only).
linked_paths = {os.path.normpath(os.path.join(SKILLS_DIR, d, rel)) for d, rel in linked}
for d in skill_dirs:
    refdir = os.path.join(SKILLS_DIR, d, "references")
    if not os.path.isdir(refdir):
        continue
    for fn in sorted(os.listdir(refdir)):
        if not fn.endswith(".md"):
            continue
        p = os.path.normpath(os.path.join(refdir, fn))
        if p not in linked_paths:
            warnings.append(f"[references] {d}/references/{fn} exists but is not linked from SKILL.md")

# --- report ---------------------------------------------------------------
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print(f"skills checked   : {len(skill_dirs)}")
print(f"reference links  : {len(linked)}")
print(f"errors           : {len(errors)}")
print(f"warnings         : {len(warnings)}")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
for w in warnings:
    print(f"⚠️  {w}")
for e in errors:
    print(f"❌ {e}")
if errors:
    print("❌ FAIL: unresolved skill references")
    sys.exit(1)
print("✅ PASS: all skill references resolve")
sys.exit(0)
PY