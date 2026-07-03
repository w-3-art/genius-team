---
name: genius-omni-router
description: >-
  Multi-provider routing for Omni mode. Routes tasks to secondary providers (Codex, Kimi, Gemini)
  based on task type. Use automatically in Omni mode to route specialized tasks to the best
  available provider. Do NOT invoke manually. Do NOT use for implementation, QA, or
  architecture decisions outside Omni routing; use the destination Genius skill instead.
skills:
  - genius-orchestrator
  - genius-team
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Glob(*)
  - Grep(*)
  - Bash(*)
  - Task(*)
  - WebFetch(*)
  - WebSearch(*)
hooks:
  PreToolUse:
    - type: command
      command: "bash -c 'echo \"[$(date +%H:%M:%S)] OMNI-ROUTER: $TOOL_NAME\" >> .genius/omni-router.log 2>/dev/null || true'"
context: fork
---

# Genius Omni Router v22.0 — Multi-Provider Orchestration

**Route tasks to the best AI provider. Claude Code leads. Others assist. Graceful fallback always.**
Per-category rationale, health-check script, route command examples, cost tracking:
`references/omni-routing-details.md`.

## Core Principle

Claude Code (Opus 4.8) is the **lead orchestrator** and the **always-available fallback**. Secondary providers are force multipliers — used when available and when they offer a clear advantage for the task at hand.

## Provider Registry

| Provider | CLI | Model | Strengths | Cost |
|----------|-----|-------|-----------|------|
| **Claude Code** | `claude` | Opus 4.8 | Architecture, reasoning, code review, orchestration | $$$ |
| **Codex CLI** | `codex` | GPT-4.1 | Fast code generation, refactoring, boilerplate | $$ |
| **Kimi CLI** | `kimi` | Kimi K2 | Long-context analysis, documentation, summaries | $ |
| **Gemini CLI** | `gemini` | Gemini 2.5 Pro | Research, multi-modal, large codebases | $$ |

Authentication: each provider's normal CLI login flow. Missing or unauthenticated CLI →
fall back to Claude Code.

## Routing Table

| Task category | Provider | Fallback |
|---------------|----------|----------|
| Architecture & planning | Claude Code (always) | — |
| Code implementation | Codex CLI | Claude Code |
| Code review | Claude Code (always) | — |
| Documentation | Kimi CLI | Claude Code |
| Research & analysis | Gemini CLI | Claude Code |
| QA & testing | Claude Code (always) | — |

Keep on Claude Code even when a secondary is available for: complex/security-sensitive
code, docs requiring architectural decisions, research requiring immediate code changes,
small/quick tasks (routing overhead > savings). Full rationale per category:
`references/omni-routing-details.md` § Routing Rationale.

## Routing Decision Flow

1. Classify the task (architecture/code/review/docs/research/qa)
2. Look up the default provider in the routing table
3. Check availability: binary installed AND authenticated (script: § Provider Health Check)
4. Available → route via Bash, capture output (`RESULT=$(codex "..." 2>&1)`) — command
   examples: § How to Route
5. Unavailable → fall back to Claude Code
6. Log the decision to `.genius/omni-router.log` (§ Cost Tracking)

## Fallback Logic

**Priority chain:** Preferred Provider → Claude Code (always available). No cascading
between secondary providers — Codex unavailable means Claude Code, not Gemini/Kimi.
Degradation levels: **Full Omni** (all providers) → **Partial Omni** (Claude + some) →
**Solo Mode** (Claude only; routing skipped).

## Integration with Genius Team

1. **genius-team** (router) classifies intent and picks a skill
2. **genius-orchestrator** breaks work into tasks
3. **genius-omni-router** decides which *provider* executes each task
4. Results flow back through Claude Code for review and integration

**Important:** Secondary providers produce raw output. Claude Code ALWAYS reviews and integrates the output before committing. Never blindly trust external provider output.

## Session Start Checklist

1. Announce "Omni Mode — Multi-Provider Orchestration"
2. Run provider health check (binary + auth)
3. Report available providers and fallback status
4. Load BRIEFING.md and plan.md as usual, proceed with routing-aware execution

## Handoff

- → **genius-orchestrator**: Return provider choice, fallback status, and command
- → **genius-dev / specialist skills**: Execute the routed task once the provider is selected
- → **genius-start**: Report available providers during session bootstrap

## Next Step

Choose the provider, run the delegated task, then hand the output back to Claude for review and integration.

## Definition of Done

- [ ] Provider choice is justified by task type, cost, or latency
- [ ] Health checks or fallback status are surfaced before execution
- [ ] Output from secondary providers is reviewed before integration
- [ ] Routing preserves Genius Team ownership of the final result
- [ ] Failure path names the fallback provider or local execution plan
