---
description: Resume a GT v22 repo from the canonical state instead of legacy progress files
---

# /continue

Resume work from the current GT v22 contract.

## Execution

### Step 1: Read the actual repo state

Run:

```bash
cat .genius/state.json 2>/dev/null
cat .genius/memory/BRIEFING.md 2>/dev/null | head -40
test -f .claude/plan.md && head -60 .claude/plan.md
test -f .agents/plan.md && head -60 .agents/plan.md
tail -20 .genius/session-log.jsonl 2>/dev/null
```

### Step 2: If state looks stale, recover

Run:

```bash
bash scripts/session-recover.sh 2>/dev/null || true
```

Then re-read `.genius/state.json`.

### Step 3: Determine the actual resume point

Use:

- `phase`
- `currentSkill`
- `currentWorkflow`
- `bootstrapStatus`
- plan file if execution has started

### Step 4: Resume truthfully

If:

- `phase = NOT_STARTED` -> tell the user to run `/genius-start`
- ideation phase -> continue from the current skill
- execution phase -> resume from the next unchecked task in plan
- complete phase -> summarize and offer deployment / QA / follow-up work

### Step 5: Suggest dashboard refresh only if it makes sense

If runtime outputs exist or changed materially, suggest:

```text
Run /genius-dashboard to refresh the project dashboard from .genius/outputs/.
```

Do not mention `.genius/playgrounds/`.
Do not use `PROGRESS.md` as the main resume source.
