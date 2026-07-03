#!/usr/bin/env bash
# trigger-evals.sh — Regression eval for skill trigger routing.
#
# Scores how the local heuristic router (IDF keyword match over SKILL.md
# descriptions, top-1) resolves a frozen set of user phrases in
# autoresearch/trigger-evals.jsonl. This is a REGRESSION gate, not an LLM
# benchmark: the baseline is measured once (autoresearch/trigger-evals-baseline.md)
# then frozen. CI fails if the score drops below (baseline - 5).
#
# Usage:
#   scripts/trigger-evals.sh              # measure, enforce floor from baseline md
#   scripts/trigger-evals.sh --floor 90   # measure, enforce explicit integer floor
#   scripts/trigger-evals.sh --no-gate    # measure only, always exit 0
#
# Part of Genius Team Phase 4 (P4-04).

set -euo pipefail

cd "$(dirname "$0")/.."

SKILLS_DIR=".claude/skills"
EVALS="autoresearch/trigger-evals.jsonl"
BASELINE_MD="autoresearch/trigger-evals-baseline.md"

FLOOR=""
GATE=1
while [ $# -gt 0 ]; do
  case "$1" in
    --floor) FLOOR="$2"; shift 2 ;;
    --no-gate) GATE=0; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [ ! -f "$EVALS" ]; then
  echo "❌ eval set not found: $EVALS" >&2
  exit 1
fi

# Resolve the CI floor: explicit --floor wins, else the FLOOR marker in baseline md.
if [ -z "$FLOOR" ] && [ -f "$BASELINE_MD" ]; then
  FLOOR=$(grep -oE 'FLOOR:[[:space:]]*[0-9]+' "$BASELINE_MD" | grep -oE '[0-9]+' | head -1 || true)
fi

SKILLS_DIR="$SKILLS_DIR" EVALS="$EVALS" FLOOR="$FLOOR" GATE="$GATE" python3 - <<'PY'
import os, re, json, math, sys

SKILLS_DIR = os.environ["SKILLS_DIR"]
EVALS = os.environ["EVALS"]
FLOOR = os.environ.get("FLOOR", "").strip()
GATE = os.environ.get("GATE", "1") == "1"

STOP = set("""
the a an and or of to in on for with your you use used using user users when
task tasks involves says say run runs runp per via into this that these those
skill skills genius team based mode modes not do dont don t is are be it its
after before also help helps handle handles handled create creates creating
generate generates generating support supports supported works work working
via use-when e g eg etc such as new set sets setting during while any all one
two three each only right best good better make makes making writes write
written written- writing does doesn while what where were where s re ll
""".split())

def tokens(text):
    text = text.lower()
    raw = re.split(r'[^a-z0-9]+', text)
    return [w for w in raw if len(w) >= 3 and w not in STOP]

def parse(f):
    t = open(f, encoding="utf-8").read()
    m = re.match(r'^---\n(.*?)\n---', t, re.S)
    fm = m.group(1) if m else ""
    name = re.search(r'^name:\s*(.+)$', fm, re.M)
    dm = re.search(r'^description:\s*(?:>[-]?|\|[-]?)?\s*\n((?:[ \t]+.*\n?)+)', fm, re.M)
    if dm:
        desc = " ".join(l.strip() for l in dm.group(1).splitlines())
    else:
        dm2 = re.search(r'^description:\s*(.+)$', fm, re.M)
        desc = dm2.group(1).strip() if dm2 else ""
    return (name.group(1) if name else None), desc

# Build per-skill keyword profiles + document frequencies for IDF.
profiles = {}
for s in sorted(os.listdir(SKILLS_DIR)):
    f = os.path.join(SKILLS_DIR, s, "SKILL.md")
    if not os.path.isfile(f):
        continue
    name, desc = parse(f)
    if not name:
        continue
    prof = set(tokens(desc)) | set(w for w in name.split("-") if len(w) >= 3 and w not in STOP)
    profiles[name] = prof

N = len(profiles)
df = {}
for prof in profiles.values():
    for t in prof:
        df[t] = df.get(t, 0) + 1
idf = {t: math.log(N / c) for t, c in df.items()}

def route(phrase):
    """Return top-1 skill for a user phrase (IDF keyword overlap; alpha tie-break)."""
    toks = set(tokens(phrase))
    best_name, best_score = None, -1.0
    for name in sorted(profiles):  # alpha order => deterministic tie-break
        prof = profiles[name]
        score = sum(idf.get(t, 0.0) for t in toks if t in prof)
        if score > best_score:
            best_score, best_name = score, name
    return best_name

rows = []
with open(EVALS, encoding="utf-8") as fh:
    for line in fh:
        line = line.strip()
        if line:
            rows.append(json.loads(line))

st_pass = st_tot = sn_pass = sn_tot = 0
fails = []
for r in rows:
    top = route(r["phrase"])
    if r["type"] == "should_trigger":
        st_tot += 1
        ok = (top == r["expect"])
        if ok:
            st_pass += 1
        else:
            fails.append((r["type"], r["skill"], r["phrase"], top))
    else:
        sn_tot += 1
        ok = (top != r["not"])
        if ok:
            sn_pass += 1
        else:
            fails.append((r["type"], r["skill"], r["phrase"], top))

tot = st_tot + sn_tot
passed = st_pass + sn_pass
pct = 100.0 * passed / tot if tot else 0.0

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print(f"Skills profiled : {N}")
print(f"Eval cases      : {tot}  ({st_tot} should-trigger, {sn_tot} should-not)")
print(f"should-trigger  : {st_pass}/{st_tot}")
print(f"should-not      : {sn_pass}/{sn_tot}")
print(f"Routing score   : {passed}/{tot} = {pct:.1f}%")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
if fails:
    print("Misroutes:")
    for typ, skill, phrase, top in fails:
        print(f"  [{typ}] {skill}: \"{phrase}\" -> {top}")

if GATE and FLOOR:
    floor = int(FLOOR)
    if pct + 1e-9 < floor:
        print(f"❌ FAIL: routing score {pct:.1f}% below floor {floor}%")
        sys.exit(1)
    print(f"✅ PASS: routing score {pct:.1f}% >= floor {floor}%")
elif GATE and not FLOOR:
    print("ℹ️  no floor configured (baseline not yet frozen) — informational run")
else:
    print("ℹ️  --no-gate: informational run")
sys.exit(0)
PY