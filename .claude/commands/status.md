---
description: Show the canonical GT v22 repo status
---

# /status

Show the current GT repo status from the canonical v22 contract.

## Execution

### Step 1: Read the canonical state

Run:

```bash
cat .genius/state.json 2>/dev/null
cat .genius/config.json 2>/dev/null
cat .genius/mode.json 2>/dev/null
cat .genius/outputs/state.json 2>/dev/null
```

### Step 2: Read the memory summary

Run:

```bash
cat .genius/memory/BRIEFING.md 2>/dev/null | head -40
```

### Step 3: Summarize the repo truthfully

Display:

- install mode
- engine
- experience mode
- phase
- current skill
- current workflow
- origin
- migration status
- bootstrap status
- Cortex-ready status

Also show:

- tasks completed / total
- dashboard path
- available outputs count if present

### Step 4: Avoid legacy reporting

Do **not** build status around:

- `PROGRESS.md`
- `.genius/playgrounds/`
- old v17 wording

The source of truth is `.genius/state.json` plus the companion contract files.
