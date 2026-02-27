---
description: Upgrade Genius Team to the latest version
---

# /genius-upgrade

Upgrade your Genius Team installation to the latest version.

## What it does

1. Check current version from `.genius/state.json` (or detect from file structure)
2. Pull and run the **latest upgrade script directly from GitHub** (always fresh, never stale)
3. Show changelog and what's new
4. Ask for confirmation before applying

## Execution

Always fetch the latest upgrade script from GitHub — **never run the local copy** (it may be outdated):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/upgrade.sh)
```

To preview without making changes:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/upgrade.sh) --dry-run
```

## Response Format

### If upgrade available:

```
🆕 New version available!

Current version: v13.0.0
Latest version: v14.0.0

What's new in v14.0:
- 📊 Proactive Dashboard — shown after every skill, /status, and /genius-start
- 🧠 Native Auto Memory — @.genius/memory/BRIEFING.md auto-loaded at session start
- 📁 .claude/rules/genius-memory.md — memory hierarchy guide
- 📝 CLAUDE.local.md template — gitignored personal prefs (local URLs, ports)
- 🌀 Genius-Claw — Auto Memory aware, proactive dashboard in all flows

Proceed with upgrade? (yes/no)
```

### On user approval:

Run the curl command above and display results.

Suggest: "Run `/genius-start` to reinitialize with v13 features."

### If already latest:

```
✅ Genius Team is up to date (v14.0.0)
```

## Safety

- The upgrade script automatically creates a backup at `.genius/backups/pre-v13-upgrade-<timestamp>/`
- Never auto-upgrade without user confirmation
- Use `--dry-run` to preview without changes
- Use `--force` to skip the git-clean check if needed
