---
description: Switch the GT v22 experience mode while preserving the install/runtime config
---

# /genius-mode

Switch the **experience mode** of the repo.

In v22:

- `.genius/mode.json` = experience mode
- `.genius/config.json` = install/runtime config

Do not confuse the two.

## Execution

### Step 1: Read current mode

Run:

```bash
cat .genius/mode.json 2>/dev/null
cat .genius/config.json 2>/dev/null
```

### Step 2: Present the available experience modes

```text
beginner  — more guidance
builder   — balanced default
pro       — less hand-holding
agency    — more client / multi-project oriented
```

### Step 3: Update only the experience mode

Do not overwrite install mode or engine.

Run:

```bash
export PATH="$PWD/.genius/bin:$PATH"
genius-mode <chosen_mode>
```

### Step 4: Confirm the split clearly

Show:

- new experience mode from `.genius/mode.json`
- unchanged install mode from `.genius/config.json`
- unchanged engine from `.genius/config.json`
