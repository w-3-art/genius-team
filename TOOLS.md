# TOOLS.md — Genius Team Tooling Reference

## Supported Engines

| Engine | Min Version | Notes |
|--------|-------------|-------|
| Claude Code | 1.0.0+ | Default engine; Agent Teams for parallel dev |
| Codex CLI | 0.107.0+ | Thread forking for native sub-agents (0.107.0 stable) |

## Codex Features (≥ 0.107.0)

- **Thread forking** — spawn sub-agent branches without leaving conversation
- **Realtime voice** — mic/speaker selection, persistent across sessions
- **Custom tools multimodal** — tools can return images + structured content
- **Configurable memories** — `codex debug clear-memories` to reset

## Claude Code Features (≥ 1.0.0)

- **HTTP Hooks** — POST JSON to external URL on hook events (set `GENIUS_WEBHOOK_URL`)
- **Shared project configs** — configs sync across git worktrees automatically
- **Agent Teams** — `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` for parallel genius-dev
- `/simplify`, `/batch` — built-in slash commands for context management

## OpenClaw (Genius-Claw)

- **sessions_spawn + attachments** — pass files inline to genius sub-agents
- **PDF tool** — genius-qa can analyze PDF specs natively
- **Canvas** — present `.genius/DASHBOARD.html` as live OpenClaw canvas
- **Telegram streaming** — genius-dev/qa stream output in real-time
