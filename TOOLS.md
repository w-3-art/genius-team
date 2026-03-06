# TOOLS.md — Genius Team Tooling Reference

## Supported Engines

| Engine | Min Version | Notes |
|--------|-------------|-------|
| Claude Code | 1.0.0+ | Default engine; Agent Teams for parallel dev |
| Codex CLI | 0.107.0+ | GPT-5.4 default depuis 05/03/2026 |

## Codex Features (≥ 0.107.0)

- **Thread forking** — spawn sub-agent branches without leaving conversation
- **Realtime voice** — mic/speaker selection, persistent across sessions
- **Custom tools multimodal** — tools can return images + structured content
- **Configurable memories** — `codex debug clear-memories` to reset
- **GPT-5.4 (05 Mar 2026)** — le modèle par défaut dans Codex CLI. Reasoning + coding + agentic en un modèle unifié. Contexte 1M tokens. Computer use natif.

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

## MCP — Model Context Protocol

### Cloudflare Code Mode (Recommandé pour genius-dev)

Réduit le coût tokens des MCP servers de 1M+ → ~1K tokens.

| Pattern | Tools exposés | Coût tokens |
|---------|--------------|-------------|
| Standard MCP | 200+ tools avec schemas | 500K-1.17M tokens |
| Code Mode | 2 tools (`run_code` + `get_docs`) | ~1 000 tokens |

**Setup :**
```bash
# Dans le projet utilisateur
npx cloudflare-mcp-server --setup
# Ou dans .claude/settings.json → mcpServers
```

**Guide complet :** `docs/cloudflare-mcp-guide.md`
**Source :** https://blog.cloudflare.com/code-mode-mcp/
