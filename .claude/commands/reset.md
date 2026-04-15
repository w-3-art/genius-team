---
description: Reset the GT v22 repo state with backup and confirmation
---

# /reset

Reset the repo runtime state without pretending old files like `PROGRESS.md` are still central.

## Execution

### Step 1: Confirm explicitly

Tell the user this will:

- create a backup in `.genius/backups/`
- reset `.genius/state.json`
- reset `.genius/outputs/state.json`
- clear `.genius/session-log.jsonl`
- remove plan files if present

Tell the user this will **not**:

- delete generated artifacts
- delete project code
- erase memory files under `.genius/memory/`

Require explicit confirmation.

### Step 2: Run the reset

Run:

```bash
export PATH="$PWD/.genius/bin:$PATH"
reset --yes
```

### Step 3: Report the backup path and new state

Then show:

- backup path
- phase = `NOT_STARTED`
- bootstrap status
- migration status

### Step 4: End with the right restart action

```text
Next: run /genius-start
```
