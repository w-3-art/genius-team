# Genius Team v14.0 — IDE Mode

> Your AI product team. From idea to production. Powered by Agent Teams.

**Mode:** IDE (VS Code / Cursor)
**Settings:** `configs/ide/settings.json` → `.claude/settings.json`

---

## Quick Start

**First time?** Run `/genius-start` to initialize your environment.

**Returning?** Just say what you want to do — your BRIEFING.md has the context.

**📊 Dashboard:** `open .genius/DASHBOARD.html` — your real-time project hub.
Run `/genius-dashboard` to generate or refresh it. **Always show this link to the user after completing any skill.**

---

## 🧠 Memory

**Auto-loaded at session start:**
- This CLAUDE.md + @.genius/memory/BRIEFING.md (project context)
- Auto Memory `~/.claude/projects/<project>/memory/MEMORY.md` (personal learnings)

**During sessions:** Say "remember that..." to save to Auto Memory. Use `.genius/memory/` for team-shared decisions.
**Personal preferences:** `CLAUDE.local.md` (auto-gitignored). See `.claude/rules/genius-memory.md` for full details.

---

## IDE Mode Features

- **VS Code Tasks**: Memory operations available from Command Palette (`Cmd+Shift+P`)
- **Cursor Rules**: `.cursorrules` provides IDE-specific context
- **No PostToolUse hooks**: IDE environments don't support PostToolUse reliably
- **Agent Teams via Task()**: Spawn teammates from the Claude Code panel
- **Memory:** Native `@.genius/memory/BRIEFING.md` import + Auto Memory + SessionStart hook

### VS Code Tasks

Open Command Palette (`Cmd+Shift+P`) → "Tasks: Run Task":

- **Genius: Generate Memory Briefing** — Regenerate BRIEFING.md
- **Genius: Extract Memories** — Extract memories from current session
- **Genius: Setup** — Re-run IDE setup
- **Genius: Verify** — Verify installation

### Agent Teams in IDE

In IDE mode, Agent Teams are accessed via the **Task()** function in the Claude Code panel:

```
Task(
  description: "Implement auth flow",
  prompt: "Read @.genius/memory/BRIEFING.md for context. Then implement...",
  subagent_type: "genius-dev"
)
```

Teammates work in isolated git worktrees. Results merge back when complete.

### Cursor Integration

The `.cursorrules` file tells Cursor about Genius Team conventions, the memory system, and skill locations. It references this CLAUDE.md for full project context.

---

## Agent Teams Protocol

Genius Team v14.0 uses Claude Code Agent Teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`).

- **Lead** (you, the main session) coordinates — never codes directly
- **Teammates** are spawned via Task() with natural language prompts
- Each teammate gets: task description, file ownership, BRIEFING.md context
- Git worktree isolation for parallel work
- Shared task list via `.claude/plan.md`

### Subagents

| Subagent | subagent_type | Purpose |
|----------|---------------|---------|
| genius-dev | `genius-dev` | Code implementation |
| genius-qa-micro | `genius-qa-micro` | Quick 30s quality check |
| genius-debugger | `genius-debugger` | Fix errors |
| genius-reviewer | `genius-reviewer` | Quality score (read-only) |

---

## Memory System (File-Based)

No external MCPs required. All memory is file-based in `.genius/memory/`:

| File | Purpose |
|------|---------|
| `BRIEFING.md` | Auto-generated ~150 line project summary (loaded at session start) |
| `decisions.json` | Key decisions with rationale and timestamps |
| `patterns.json` | Code/project patterns and conventions |
| `progress.json` | Task progress (7-day rolling window) |
| `errors.json` | Resolved errors and their solutions |
| `session-logs/` | Compressed session logs (30-day retention) |

### Memory Protocol

- **Session start**: BRIEFING.md is auto-loaded via SessionStart hook
- **On decisions**: Append to `.genius/memory/decisions.json`
- **On errors resolved**: Append to `.genius/memory/errors.json`
- **On patterns found**: Append to `.genius/memory/patterns.json`
- **Before compaction**: `scripts/memory-extract.sh` extracts key info from session
- **BRIEFING.md regenerated** from all JSON files via `scripts/memory-briefing.sh`

### Auto-loaded Context

@.genius/memory/BRIEFING.md
@.claude/plan.md

### Memory Triggers

| Say This | Effect |
|----------|--------|
| "Remember that..." | Appends to decisions.json |
| "We decided..." | Appends to decisions.json |
| "This broke because..." | Appends to errors.json |
| "Pattern: ..." | Appends to patterns.json |

---

## QA Loop (Mandatory)

After EVERY task, `genius-qa-micro` runs. A task is NOT complete until QA passes:

```
Dev → QA-micro → Fix (if needed) → Re-QA → ✅
```

---

## Save-Token Mode

Toggle with `/save-tokens`. When enabled, high-volume roles (dev, qa-micro, debugger, reviewer) use Sonnet instead of Opus. Lead and architect always use Opus.

---

## Two Phases

### Phase 1: IDEATION (Conversational)
Skills ASK questions. User input expected at checkpoints.

```
genius-interviewer → genius-product-market-analyst → genius-specs
                                                      ↓
                                            [CHECKPOINT: Approve specs]
                                                      ↓
                                            genius-designer
                                                      ↓
                                            [CHECKPOINT: Choose design]
                                                      ↓
                           genius-marketer → genius-copywriter → genius-integration-guide
                                                      ↓
                                            genius-architect
                                                      ↓
                                            [CHECKPOINT: Approve architecture]
```

### Phase 2: EXECUTION (Autonomous)
Agent Teams EXECUTE without stopping. No questions asked.

```
genius-orchestrator (Lead, coordinates):
├── genius-dev (teammate, implements)
├── genius-qa-micro (teammate, validates)
├── genius-debugger (teammate, fixes)
└── genius-reviewer (teammate, scores)

Then: genius-qa (full audit) → genius-security → genius-deployer
```

---

## Commands

| Command | What It Does |
|---------|-------------|
| `/genius-start` | Initialize environment, load memory, show status |
| `/genius-dashboard` | **Generate/refresh your Dashboard** → `open .genius/DASHBOARD.html` |
| `/status` | Show current progress + Dashboard link |
| `/continue` | Resume from last point |
| `/reset` | Start over (with backup) |
| `/hydrate-tasks` | Reload tasks from plan.md |
| `/save-tokens` | Toggle save-token mode |
| `/update-check` | Check for Claude Code updates |
| `STOP` / `PAUSE` | Halt autonomous execution |

---

## Key Files

| File | Purpose |
|------|---------|
| `.claude/plan.md` | **Single source of truth** for task list |
| `.genius/state.json` | Project state tracking |
| `.genius/config.json` | Team configuration (models, memory settings) |
| `.genius/memory/BRIEFING.md` | Auto-generated project context |
| `PROGRESS.md` | Real-time execution status |

---

## Checkpoints (User Input Required)

1. **After Specs**: "Specifications complete. Ready for design phase?"
2. **After Designer**: "Which design option do you prefer?"
3. **After Architect**: "Architecture complete. Ready to start building?"

All other transitions happen automatically.

---

## Important Rules

1. **IDEATION Phase**: Ask questions, validate understanding, get approval at checkpoints
2. **EXECUTION Phase**: Never stop, handle errors, keep going until ALL tasks complete
3. **Always update** PROGRESS.md and plan.md after each task
4. **Memory**: Read BRIEFING.md at session start, update JSON files during work
5. **QA Loop**: Every task must pass genius-qa-micro before completion
6. **Agent Teams**: Lead coordinates, teammates execute — never mix roles
