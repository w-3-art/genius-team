# Genius Team v2 — Architecture

> **Status:** In Design (2026-02-25) — Not yet implemented  
> **Author:** Echo (AI assistant)  
> **Review needed:** Ben Bellity before implementation

---

## v1 → v2: The Pivot

### v1 (current — v10.0)
Genius Team is a **skill collection**. All 21+ skills run in the **same Claude Code session**. The user invokes skills manually. Memory is file-based (`.genius/`), but there's no real agent isolation — everything shares the same context window.

### v2 (target)
Genius Team becomes an **agent orchestration framework**. Each skill becomes a **spawnable agent** with:
- Its own isolated context window (separate session)
- Its own memory namespace
- Clear inputs/outputs defined in YAML spec
- A playground fragment it contributes to the global dashboard

---

## Core Concepts

### 1. Agent Specs (`agents/*.yaml`)
Each agent is defined by a YAML spec file that documents:
- **Identity:** role, persona, model preference
- **Trigger:** when it gets invoked
- **Inputs/Outputs:** what it reads and writes
- **Protocol:** how it executes its task
- **Memory:** what files it touches (read / write / never-touch)
- **Playground:** what UI fragment it contributes

### 2. Orchestration Flow

```
User Input
    │
    ▼
┌─────────────────────┐
│  genius-orchestrator │  ← reads state.json, decides what's next
└────────┬────────────┘
         │ spawns
    ┌────┴────────────────────────────────────────────────┐
    │                    Agent Selection                   │
    └────┬──────────┬──────────┬──────────┬──────────────┘
         │          │          │          │
         ▼          ▼          ▼          ▼
  interviewer    specs     market     dev
  (fresh)     (briefed)  (optional) (specs_ready)
         │          │          │          │
         ▼          ▼          ▼          ▼
   brief.md    specs.md  analysis.md  src/feature/
         │          │          │          │
         └──────────┴──────────┴──────────┘
                           │
                           ▼
                    genius-qa (after each dev)
                           │
                     (pass/fail loop)
                           │
                    genius-deploy (pre_deploy)
                           │
                           ▼
                       🚀 Live URL
```

### 3. State Machine

State is tracked in `.genius/state.json`. The orchestrator reads this at every invocation to determine what phase the project is in and which agent to spawn next.

```
fresh → briefed → specs_ready → building → pre_deploy → complete
                      ↓
               (optional branch)
            → market-analysis (parallel)
```

### 4. Memory Model

```
.genius/
├── state.json          ← Orchestrator-owned: current phase + progress
├── brief.md            ← interviewer writes, all agents read
├── specs.md            ← specs writes, dev+qa+deploy read
├── market-analysis.md  ← market-analyst writes
├── architecture.md     ← architect writes (L+ complexity)
├── design-system.md    ← designer writes
├── security-report.md  ← security writes
├── orchestration.log   ← JSONL event log (every spawn/completion)
├── playground-data.json← Global playground state (orchestrator-owned)
└── activity.log        ← Existing hook-based file tracking
```

**Access rules:**
- Each agent only writes to its own output files
- All agents can read `brief.md`, `specs.md`, `state.json`
- Only orchestrator writes `state.json` and `orchestration.log`
- Dev agents only touch `src/**`

### 5. Playground Architecture

Every agent contributes a **sub-playground fragment** to the global dashboard.

```
Global Playground (genius.w3art.io/playground/{project-id})
├── Status Card (orchestrator)
│   └── Phase, progress bar, ETA
├── 🎙️ Interview Card (genius-interviewer)
│   └── Project brief summary
├── 📐 Specs Card (genius-specs)
│   └── Tech stack + feature list
├── 🤖 Dev Board (genius-dev per feature)
│   └── Kanban: Todo / In Progress / Done
├── 🧪 QA Card (genius-qa)
│   └── Test results, coverage
└── 🚀 Deploy Card (genius-deploy)
    └── Live URL + deployment status
```

The playground is:
- **Static JSON** served from `.genius/playground-data.json`
- **Updated** by orchestrator after each agent completes
- **Accessible** at a public URL (if hosted via Vercel)
- **Offline-capable** (generates from local files too)

---

## Agent Dependency Graph

```
genius-interviewer ──────────────────────────────────────┐
        │                                                 │
        ▼                                                 ▼
genius-specs ──────────────────────────────── genius-market-analyst
        │                                          (parallel, optional)
        ▼
genius-architect (if complexity >= L)
        │
        ▼
genius-designer (optional, needs visual design)
        │
        ▼
genius-dev ──── genius-qa ──── (loop per feature)
                                │
                                ▼ (when all features done)
                        genius-security (parallel)
                                │
                                ▼
                        genius-deploy
                                │
                                ▼
                         🚀 Complete
```

**Parallelism allowed:**
- `genius-specs` + `genius-market-analyst` (same input, different outputs)
- `genius-security` + `genius-deploy` (if security is non-blocking)

---

## Implementation Roadmap

### Phase 1 — Foundation (current, docs only)
- [x] Agent specs in YAML (`agents/*.yaml`)
- [x] Playground schema (`agents/playground-schema.json`)
- [x] Architecture documentation (this file)
- [ ] Ben review + validation

### Phase 2 — Orchestrator MVP
- [ ] Implement `genius-orchestrator` as a real skill
- [ ] State machine in `scripts/orchestrator.js`
- [ ] Integration with existing `state.json` format
- [ ] Test with a fresh project

### Phase 3 — Agent Isolation
- [ ] Each agent runs in a `sessions_spawn` sub-session (Claude Code)
- [ ] Proper context window isolation
- [ ] Cross-agent communication via files (not shared context)

### Phase 4 — Playground v2
- [ ] Global playground reads `playground-data.json`
- [ ] Per-agent sub-playground cards
- [ ] Real-time updates via polling or webhook
- [ ] Public URL with project sharing

### Phase 5 — MCP Distribution
- [ ] npm package `genius-team-mcp`
- [ ] MCP tools: `spawn_agent`, `get_state`, `update_playground`
- [ ] Dual distribution: ClawHub skill + `npx genius-team-setup`

---

## Key Design Decisions

### Why YAML for agent specs?
- Human-readable and editable
- Tool-agnostic (not locked to Claude Code)
- Can be transpiled to JSON for programmatic use
- Serves as documentation AND configuration

### Why file-based communication?
- Works offline
- No external services needed (no Pub/Sub, no Redis)
- Git-trackable history of every agent output
- Survives session restarts and agent failures

### Why not share context between agents?
- Context window isolation = better performance per agent
- Forces clean interfaces (agents communicate via files, not memory)
- Enables parallel execution without conflicts
- Each agent gets a fresh, focused context

### Why a global playground?
- Gives the user a single URL to share with stakeholders
- Provides transparency into what AI did at each step
- Makes the build process legible to non-technical founders
- Eventually enables collaborative feedback (stakeholders comment on specs)

---

## Open Questions (for Ben)

1. **Agent spawning mechanism:** Use `sessions_spawn` (existing OpenClaw) or Claude Code's native `--dangerously-skip-permissions` subagent mode?
2. **Playground hosting:** Continue on Vercel (`genius.w3art.io`) or self-host?
3. **MCP priority:** How soon does the npm package matter? Who are the early adopters?
4. **Monetization:** Playground as SaaS (pay per project)? Or free + upsell on agency services?
5. **genius-market-analyst:** Worth building now or wait until the core 3 agents are stable?

---

## Files in `agents/`

| File | Description |
|------|-------------|
| `genius-interviewer.yaml` | Onboarding + requirements discovery |
| `genius-specs.yaml` | Technical specification generation |
| `genius-orchestrator.yaml` | Master flow coordinator |
| `playground-schema.json` | JSON Schema for global playground |
| `ARCHITECTURE.md` | This file |
