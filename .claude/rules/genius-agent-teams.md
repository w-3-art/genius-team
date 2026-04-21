---
description: Agent Teams protocol — how Lead coordinates teammates via delegate mode
paths:
  - '.claude/plan.md'
  - '.genius/state.json'
---

# Agent Teams Protocol

Genius Team v22.0 uses Claude Code Agent Teams.

- **Lead** (main session) coordinates — never codes directly
- **Teammates** are spawned via delegate mode (Shift+Tab) with natural language prompts
- Each teammate gets: task description, file ownership, BRIEFING.md context
- Git worktree isolation for parallel work
- Shared task list via `.claude/plan.md`

## Spawning Subagents

Use `Task(description, prompt)`. Inject the role in the prompt — do NOT use `subagent_type` (unreliable, see Claude Code bug #20931).

| Role | Prompt prefix | Purpose |
|------|--------------|---------|
| genius-dev | "You are genius-dev, implementation specialist." | Code implementation |
| genius-qa-micro | "You are genius-qa-micro, quality checker." | Quick 30s quality check |
| genius-debugger | "You are genius-debugger, error fixer." | Fix errors |
| genius-reviewer | "You are genius-reviewer, code reviewer." | Quality score (read-only) |
