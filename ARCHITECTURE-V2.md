# Genius Team v2 — Agent Orchestration Framework

> **Vision:** Each skill becomes a spawnable agent with its own context, memory, and playground.
> The orchestrator routes between agents. The user only talks to the orchestrator.

---

## The Paradigm Shift

| Genius Team v1 (Skills Repo) | Genius Team v2 (Agent Framework) |
|-------------------------------|-----------------------------------|
| Skills = shell scripts | Skills = spawnable agents with YAML spec |
| User invokes skills manually | Orchestrator routes automatically |
| No inter-skill memory | State flows through `.genius/state.json` |
| Playgrounds = static demos | Playgrounds = live per-agent interaction |
| Single context | Each agent has isolated context window |

---

## Architecture Overview

```
User
  │
  ▼
genius-orchestrator  ◄── .genius/state.json (shared truth)
  │
  ├── genius-interviewer   → .genius/brief.md
  ├── genius-specs         → .genius/specs.md
  ├── genius-architect     → .genius/architecture.md
  ├── genius-dev           → src/** (via Agent Teams)
  ├── genius-qa            → .genius/qa-report.md
  ├── genius-security      → .genius/security-report.md
  └── genius-deploy        → deployed ✅
```

---

## Agent Specification Format

Each agent is defined in `agents/{agent-id}.yaml` with the following schema:

```yaml
agent:
  id: string               # unique identifier
  version: "2.0.0"
  display_name: string
  emoji: string
  tagline: string          # one-liner for UI
  model_preference: string # claude-opus-4 | claude-sonnet-4 | etc.

persona:
  role: string
  style: string
  never_does: [string]

trigger:
  command: /genius-{name}
  also_triggers_on: [string]

inputs:
  required: [field definitions]
  optional: [field definitions]

outputs:
  primary:
    file: .genius/{output}.md
    format: markdown | json
  secondary: [additional outputs]

handoff:
  next_agent: string
  trigger: string
  message_to_next: string

memory:
  reads: [file paths]
  writes: [file paths]
  does_not_touch: [patterns]

playground:
  id: string
  type: conversation | flow-visualizer | form | preview
  description: string
```

---

## State Machine

```
new
 │
 ▼
briefed     ← genius-interviewer writes .genius/brief.md
 │
 ▼
specced     ← genius-specs writes .genius/specs.md
 │
 ▼
architected ← genius-architect writes .genius/architecture.md
 │
 ▼
in-progress ← genius-dev builds src/**
 │
 ▼
built       ← genius-qa validates
 │
 ▼
deployed    ← genius-deploy ships
```

State is persisted in `.genius/state.json` and survives session restarts.

---

## Playground Architecture

### Global Playground (`genius.w3art.io`)
Aggregates sub-playgrounds from all active agents. Shows:
- Current phase and active agent
- Quick-launch buttons per agent
- Project card (brief.md summary)

### Per-Agent Playgrounds
Each agent spec defines its own playground (`playground:` section in YAML).

Playground types:
- `conversation` — live chat interface (interviewer, orchestrator)
- `form` — structured input form (specs, quick-start)
- `flow-visualizer` — state diagram with real-time updates (orchestrator)
- `preview` — rendered output (specs → spec card, architecture → diagram)

### Playground Schema (JSON)

```json
{
  "id": "string",
  "agent_id": "string",
  "type": "conversation | form | flow-visualizer | preview",
  "title": "string",
  "description": "string",
  "data_sources": [".genius/state.json", ".genius/brief.md"],
  "components": [
    {
      "type": "chat | progress-bar | card | code-block | diagram",
      "data": "string (file path or inline)",
      "config": {}
    }
  ],
  "actions": [
    {
      "label": "string",
      "command": "/genius-{name}",
      "style": "primary | secondary | danger"
    }
  ]
}
```

---

## Agent Registry (Current)

| Agent | File | Status | Phase |
|-------|------|--------|-------|
| genius-orchestrator | `agents/genius-orchestrator.yaml` | ✅ v2.0 | Routing |
| genius-interviewer | `agents/genius-interviewer.yaml` | ✅ v2.0 | new → briefed |
| genius-specs | `agents/genius-specs.yaml` | ✅ v2.0 | briefed → specced |
| genius-architect | `agents/genius-architect.yaml` | ✅ v2.0 | specced → architected |
| genius-dev | `agents/genius-dev.yaml` | ✅ v2.0 | architected → built |
| genius-qa | `agents/genius-qa.yaml` | ✅ v2.0 | built → validated |
| genius-security | `agents/genius-security.yaml` | ✅ v2.0 | validated → secured (optional) |
| genius-deploy | `agents/genius-deploy.yaml` | ✅ v2.0 | validated → deployed |

---

## MCP Distribution (Future)

```
genius-team-mcp (npm package)
├── Wraps all agent scripts as MCP tools
├── Works in any MCP-compatible IDE
└── Setup: npx genius-team-setup
```

---

## Key Design Principles

1. **One agent, one job** — no agent does more than its defined scope
2. **State is truth** — `.genius/state.json` is the only shared memory
3. **Files over summaries** — agents pass file paths, not content
4. **Playgrounds are mandatory** — every agent has a playground
5. **Orchestrator routes, agents execute** — user never bypasses the orchestrator

---

*Last updated: 2026-02-25 05h45 by Echo (nightly build) — **8/8 agents specced ✅ COMPLETE***
