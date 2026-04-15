---
description: Reload execution tasks from the plan file into the current GT v22 session
---

# /hydrate-tasks

Reload execution tasks from the canonical plan file.

## Truth to preserve

Persistent truth is now:

- `.claude/plan.md` or `.agents/plan.md` for execution tasks
- `.genius/state.json` for repo runtime state
- `.genius/session-log.jsonl` for activity timeline

Do **not** present `PROGRESS.md` as a central source of truth.

## Execution

### Step 1: Read the plan

Run:

```bash
if [ -f .claude/plan.md ]; then
  cat .claude/plan.md
elif [ -f .agents/plan.md ]; then
  cat .agents/plan.md
else
  echo "No plan file found"
fi
```

### Step 2: Parse the task counts

Count:

- total
- completed
- in progress
- pending
- blocked

### Step 3: Read repo state too

Run:

```bash
cat .genius/state.json 2>/dev/null
```

### Step 4: Summarize hydration

Show:

- task counts
- next pending task
- current phase
- current skill

End with:

```text
Ready to continue execution.
```
