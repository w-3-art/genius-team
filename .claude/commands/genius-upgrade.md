---
description: Upgrade Genius Team to the latest version
---

# /genius-upgrade

Upgrade your Genius Team installation to the latest version.

## ⚠️ CRITICAL — Always fetch from GitHub

**NEVER run `bash scripts/upgrade.sh` directly** — the local script targets the version it was installed with, not the latest. It will falsely report "already up to date" on older installs.

**Always use this exact command:**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/upgrade.sh)
```

To preview without changes:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/upgrade.sh) --dry-run
```

To force re-download of all files (even if already at latest):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/upgrade.sh) --force
```

## What it does

1. Fetches the **latest upgrade script** from GitHub (always fresh)
2. Detects current version from `.genius/state.json` or `CLAUDE.md`
3. If upgrade available: backs up current config, downloads new files
4. Shows changelog and what's new
5. Asks for confirmation before applying

## Response Format

### If upgrade available:

```
🆕 New version available!

Current version: v11.0.0
Latest version: v19.0.0

What's new in v19.0:
- 📱 Claude Code Channels — vibe code from Telegram/Discord, talk to your session from your phone
- 🎙️ Voice mode — /voice for push-to-talk, brainstorm hands-free, 20 languages
- 🔄 /loop integration — native recurring tasks, no more bash wrappers for autoresearch
- 🎚️ /effort levels — low/medium/high analysis depth control per-task
- 🧠 1M token context — Opus 4.6 full context, less compaction, longer sessions
- 🔧 Subagent fix — workaround for Claude Code bug #20931 (genius-dev/qa-micro now always work)
- ⬆️ Claude Code min version: 2.1.76

Proceed with upgrade? (yes/no)
```

### On user approval:

Run the curl command above (NOT the local script) and display results.

After completion: "Run `/genius-start` to reinitialize with v19 features."

### If already at latest:

```
✅ Genius Team is up to date (v19.0.0)
```

### If local script gives wrong result:

If `bash scripts/upgrade.sh` says "already up to date" at a version below the latest, ignore it and run the GitHub curl command. The local script is stale.

## Safety

- The upgrade script auto-creates a backup at `.genius/backups/pre-v17-upgrade-<timestamp>/`
- Never auto-upgrade without user confirmation
- Use `--dry-run` to preview without changes
