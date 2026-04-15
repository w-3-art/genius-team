---
description: Bootstrap or resume a Genius Team v22 repo using the canonical contract
---

# /genius-start

Bootstrap the current repo on the GT v22 contract, refresh the canonical state, and make the repo ready for work.

## Execution

### Step 1: Validate minimum GT structure

Run:

```bash
test -d .genius && test -d scripts && echo "GT repo detected"
```

If GT is missing, explain that this repo must first be created with `create.sh` or equipped with GT using `add.sh`.

### Step 2: Ensure contract files exist

Run:

```bash
bash scripts/setup.sh --mode "$(jq -r '.installMode // .mode // "cli"' .genius/config.json 2>/dev/null || echo cli)" --engine "$(jq -r '.engine // "claude"' .genius/config.json 2>/dev/null || echo claude)"
```

This guarantees the v22 contract skeleton exists:

- `.genius/state.json`
- `.genius/config.json`
- `.genius/mode.json`
- `.genius/outputs/state.json`
- `.genius/session-log.jsonl`
- `.genius/DASHBOARD.html`

### Step 3: Refresh runtime state

Run:

```bash
bash scripts/migrate-state.sh
```

### Step 4: Mark bootstrap completion

Run:

```bash
export PATH="$PWD/.genius/bin:$PATH"
genius-start
```

If running the local wrapper from inside the slash command would recurse, reproduce its behavior:

- append an event to `.genius/session-log.jsonl`
- set `bootstrapStatus=completed`
- refresh `.genius/outputs/state.json`
- display the current status

### Step 5: Show the repo status

Read:

```bash
cat .genius/state.json
cat .genius/outputs/state.json
```

Then summarize:

- install mode
- engine
- experience mode
- phase
- current skill
- migration status
- bootstrap status
- Cortex-ready status

### Step 6: Give next actions

Always end with:

```text
Ready. Useful next actions:
  /status
  /continue
  /genius-dashboard
```

If the repo is not yet Cortex-ready, also mention:

```text
If this repo needs to be fully readable by Cortex:
  bash scripts/migrate-cortex-ready.sh
```
