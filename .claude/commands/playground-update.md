---
description: Refresh GT runtime outputs and dashboard from the canonical v22 output layer
---

# /playground-update

Refresh the runtime visual layer of the repo.

In v22 this means:

- runtime HTML outputs live in `.genius/outputs/*.html`
- output metadata lives in `.genius/outputs/state.json`
- the hub lives in `.genius/DASHBOARD.html`

## Execution

### Step 1: Inspect the current output layer

Run:

```bash
find .genius/outputs -maxdepth 1 -type f | sort
cat .genius/outputs/state.json 2>/dev/null
```

### Step 2: Refresh the dashboard

Run:

```bash
export PATH="$PWD/.genius/bin:$PATH"
playground-update
```

If the wrapper is unavailable, run:

```bash
export PATH="$PWD/.genius/bin:$PATH"
genius-dashboard
```

### Step 3: Report what changed

State clearly:

- whether runtime outputs were found
- whether the dashboard was regenerated
- whether the output state file was updated

### Step 4: Avoid legacy assumptions

Do **not** assume:

- `.genius/playgrounds/`
- template files are the runtime outputs
- `currentPhase` / `completedSkills` old schema is the contract source
