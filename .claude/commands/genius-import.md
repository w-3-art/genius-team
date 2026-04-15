---
description: Import an existing repo into the GT v22 contract and prepare it for Cortex compatibility
---

# /genius-import

Import an existing repo into Genius Team without pretending the repo is already fully GT-ready.

## Execution

### Step 1: Detect the current state

Check:

```bash
test -f .genius/state.json && echo "gt_present" || echo "gt_missing"
test -f .genius/config.json && echo "config_present" || echo "config_missing"
test -f .genius/mode.json && echo "mode_present" || echo "mode_missing"
```

Then inspect:

```bash
ls -la README.md ARCHITECTURE.md .claude/plan.md .agents/plan.md .genius/discovery 2>/dev/null
```

### Step 2: If GT is missing

Do **not** fake an import.

Explain that the repo must first receive GT via:

```bash
bash scripts/add.sh --mode cli --engine claude
```

or the appropriate mode/engine.

### Step 3: If GT is present, migrate runtime state

Run:

```bash
bash scripts/migrate-state.sh --imported
```

### Step 4: If Cortex compatibility is wanted, run the explicit migration

Run:

```bash
bash scripts/migrate-cortex-ready.sh
```

### Step 5: Tell the truth about readiness

Read:

```bash
cat .genius/state.json
```

Then explain clearly:

- current phase
- origin
- migration status
- bootstrap status
- whether the repo is already Cortex-ready

Important rule:

- imported repo != fully ready repo
- full Cortex readability still requires the first meaningful GT bootstrap if not already done

### Step 6: End with the right next action

If bootstrap is not complete:

```text
Next: run /genius-start
```

If Cortex-ready migration has not been done:

```text
Next: run bash scripts/migrate-cortex-ready.sh
```
