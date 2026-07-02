# Archive — Agent Framework v2 (never implemented)

**Status: HISTORICAL. These YAML specs were an exploration that was never wired to any runtime.**

These 8 `genius-*.yaml` files described a proposed "Genius Team v2 — Agent
Orchestration Framework" (see [`../../../ARCHITECTURE-V2.md`](../../../ARCHITECTURE-V2.md)),
in which every skill would become a spawnable agent defined by a YAML spec, routed
automatically by a `genius-orchestrator` agent.

## Why this is archived

The framework was **never branched to the runtime**. No script, skill, or hook in
this repository ever parsed or loaded these files — a repo-wide grep for a YAML
loader returns nothing. They were pure design documents that lived at `agents/*.yaml`
and were only ever referenced from prose docs (`ARCHITECTURE-V2.md`, `README.md`,
`CHANGELOG.md`), which gave the misleading impression they were operational.

The `✅ v2.0` markers inside `ARCHITECTURE-V2.md` referred to the completeness of the
*spec draft*, not to any shipped, executed capability.

## What actually superseded it

The real, runtime subagents live in **`.claude/agents/*.md`** (Markdown, Claude Code
native subagent format) and are complemented by the **skills** under
`.claude/skills/`. That is the mechanism actually used in production:

| Concern | Real implementation |
|---------|---------------------|
| Spawnable subagents | `.claude/agents/*.md` (genius-dev, genius-reviewer, genius-qa-micro, genius-debugger, genius-challenger) |
| Task routing / capabilities | `.claude/skills/` |
| Shared state | `.genius/state.json` |

## Note on model references

These archived YAMLs contain `model_preference:` lines with obsolete identifiers
(`claude-opus-4`, `claude-sonnet-4`, `gpt-5.4`). They are **intentionally left
as-is** as a historical record — the files are not executed, so the values are inert.
The live subagents in `.claude/agents/*.md` carry no hardcoded model IDs and inherit
the session default.

_Archived on 2026-07-02 as part of the Phase 1 structural-decisions cleanup (item P1-06)._
