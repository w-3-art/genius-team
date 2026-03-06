# Genius Team v16.0

[![Version](https://img.shields.io/badge/version-16.0.0-blue.svg)](https://github.com/w-3-art/genius-team/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-1.0%2B-purple.svg)](https://docs.anthropic.com/claude-code)

> Your AI product team. From idea to production.

## What is Genius Team?

Genius Team is an open-source framework that orchestrates 21+ specialized AI agents — each spawnable on demand — to take your idea from interview to production, with human checkpoints at every phase.

```
genius-interviewer → genius-specs → genius-architect → genius-dev → genius-qa → genius-deploy
        ↓                 ↓                ↓               ↓            ↓            ↓
    Brief ✅         Specs ✅         Arch ✅          Code ✅       QA ✅       Live 🚀
```

Every phase ends with a human checkpoint. You approve. Only then does the next agent spawn.

## What's New in v16.0

- 📁 **`${CLAUDE_SKILL_DIR}` portable paths** — skills work anywhere, no hardcoded paths
- 🤖 **GPT-5.4 in Codex** — `--engine=codex` now runs GPT-5.4 (1M context, reasoning, computer use)
- 🌩️ **Cloudflare Code Mode MCP** — genius-dev uses any API in ~1K tokens (vs millions)
- 🔔 **`InstructionsLoaded` hook** — startup confirms GENIUS_GUARD.md + memory loaded
- 🔗 **Git conflict prevention** — `includeGitInstructions: false` in all configs
- 📊 **HTTP Hooks enriched** — webhook payloads now include `agent` field

*Full release history: [CHANGELOG.md](./CHANGELOG.md)*

---

## Quick Start

### Option A — OpenClaw (recommended)

If you use [OpenClaw](https://openclaw.ai), install Genius-Claw — the native plugin:

```bash
openclaw plugins install https://genius.w3art.io/genius-claw.zip
```

Genius-Claw gives you cross-project memory, a global dashboard, and auto-updates via your OpenClaw setup.

### Option B — Standalone (Claude Code / Codex CLI)

**New project:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/create.sh) my-project
```

**Add to existing project:**
```bash
cd my-existing-project
bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/add.sh)
```

**Options:**
```bash
# Choose your environment
--env cli         # Terminal / Claude Code CLI (default)
--env ide         # VS Code / Cursor

# Choose your AI engine
--engine=claude   # Claude Code only (default)
--engine=codex    # Codex CLI (OpenAI / GPT-5.4)
--engine=dual     # Both engines (builder + challenger)
```

**Examples:**
```bash
# Terminal + Claude (default)
bash <(curl -fsSL .../create.sh) my-app

# VS Code + Codex (GPT-5.4)
bash <(curl -fsSL .../create.sh) my-app --env ide --engine=codex

# Terminal + Dual engine
bash <(curl -fsSL .../create.sh) my-app --engine=dual
```

After install, open your project in Claude Code or Codex and run `/genius-start`.

### Upgrade from any previous version

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/upgrade.sh)
```

The script auto-detects your version (v9 through v15) and upgrades to v16. Your `.genius/memory/` data is preserved.

---

## How It Works

### 1. Interview
Run `/genius-start`. genius-interviewer asks the right questions before any work begins — no assumptions, no drift. Output: a validated brief you approve.

### 2. Ideation (Agents in parallel)
genius-specs, genius-product-market-analyst, genius-designer, and genius-marketer run with isolated contexts. Each produces a deliverable. You approve at the checkpoint before any code is written.

### 3. Build (Agent Teams)
genius-architect plans the stack. genius-dev implements with Agent Teams (parallel execution, git worktree isolation). Mandatory QA loop after every task: Dev → QA-micro → Fix → Re-QA → ✅.

### 4. Ship
genius-security audits. genius-deployer ships. A Retrospective Engine runs after each phase — learnings feed into cross-project memory.

---

## 21+ Specialized Skills

| Skill | Purpose |
|-------|---------|
| genius-team | Intelligent router — entry point |
| genius-interviewer | Requirements discovery |
| genius-product-market-analyst | Market validation |
| genius-specs | Formal specifications |
| genius-designer | Brand & design system |
| genius-marketer | Go-to-market strategy |
| genius-copywriter | Marketing copy |
| genius-integration-guide | Service setup guides |
| genius-architect | Technical planning |
| genius-orchestrator | Autonomous execution coordinator |
| genius-dev | Code implementation (Agent Teams) |
| genius-qa | Full quality audit |
| genius-qa-micro | Quick per-task validation |
| genius-debugger | Error fixing |
| genius-reviewer | Code review |
| genius-security | OWASP security audit |
| genius-deployer | Deployment |
| genius-memory | Knowledge management |
| genius-onboarding | First-time setup |
| genius-test-assistant | Manual testing |
| genius-team-optimizer | Self-improvement |
| genius-updater | Version tracking & updates |
| genius-dual-engine | Builder + Challenger workflow |

---

## Memory System

Everything is file-based — no external services, no MCPs required.

```
.genius/memory/
├── BRIEFING.md          # Auto-generated summary, loaded at every session start
├── decisions.json       # Key decisions with rationale
├── patterns.json        # Code patterns and conventions
├── progress.json        # Task progress (7-day window)
├── errors.json          # Resolved errors and solutions
└── session-logs/        # Session logs (30-day retention)
```

Memory persists across sessions and across projects. The more you build, the smarter your agents become.

---

## Commands

| Command | Description |
|---------|-------------|
| `/genius-start` | Initialize environment, load memory, begin interview |
| `/genius-dashboard` | Open the master visual dashboard |
| `/genius-upgrade` | Upgrade to latest version |
| `/status` | Show current phase and progress |
| `/continue` | Resume from last checkpoint |
| `/reset` | Start over (with backup) |
| `/save-tokens` | Toggle save-token mode (Sonnet for dev, Opus for lead) |
| `/guard-check` | Verify GENIUS_GUARD.md compliance |
| `/guard-recover` | Recover from drift |
| `/memory-status` | Show memory summary |
| `/update-check` | Check for Claude Code + Genius Team updates |

---

## Project Structure

```
your-project/
├── CLAUDE.md                    # Project instructions (mode-specific)
├── AGENTS.md                    # Codex CLI instructions (engine=codex/dual)
├── .claude/
│   ├── settings.json            # Permissions, hooks & env vars
│   ├── commands/                # Slash commands (/genius-start, etc.)
│   ├── skills/                  # 21+ Genius Team skill files
│   └── plan.md                  # Task list (single source of truth)
├── .genius/
│   ├── state.json               # Current project phase & checkpoint
│   ├── DASHBOARD.html           # Visual master dashboard
│   └── memory/                  # File-based memory system
│       ├── BRIEFING.md
│       ├── decisions.json
│       ├── patterns.json
│       ├── progress.json
│       ├── errors.json
│       └── session-logs/
├── agents/                      # Agent YAML specs (orchestration)
├── scripts/
│   ├── create.sh                # One-liner new project setup
│   ├── add.sh                   # Add Genius to existing project
│   ├── setup.sh                 # Configure modes & engines
│   ├── upgrade.sh               # Upgrade to latest version
│   └── verify.sh                # Verify installation health
└── docs/                        # Documentation & guides
```

---

## Requirements

| Tool | Minimum | Notes |
|------|---------|-------|
| Claude Code | ≥ 1.0.0 | Required for Claude engine |
| Codex CLI | ≥ 0.107.0 | Required for `--engine=codex` or `--engine=dual` |
| jq | any | Required for memory system JSON processing |
| Git | any | Required for version control and worktrees |
| Node.js | ≥ 18 | Recommended for most project types |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License — see [LICENSE](LICENSE)

---

**Built with** 🧠 **Genius Team v16.0** — Agent Orchestration · File-Based Memory · Interactive Playgrounds
