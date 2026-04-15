---
description: Upgrade Genius Team to the latest version, then apply the v22/Cortex migration steps if needed
---

# /genius-upgrade

Run the official GT upgrade script directly.

## Execution

### Step 1: Run the upgrade

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/upgrade.sh)
```

For dry-run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/upgrade.sh) --dry-run
```

### Step 2: Re-read repo state

After completion, inspect:

```bash
cat .genius/state.json 2>/dev/null
cat .genius/config.json 2>/dev/null
```

### Step 3: If the repo still needs Cortex compatibility, say it explicitly

If `migrationStatus != cortex-ready`, tell the user to run:

```bash
bash scripts/migrate-cortex-ready.sh
```

### Step 4: If bootstrap is not complete, tell the user to run:

```text
/genius-start
```

Important:

- upgrade GT first
- then run the explicit Cortex-ready migration if required
- then bootstrap the repo if required
