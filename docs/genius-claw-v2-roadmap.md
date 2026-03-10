# Genius-Claw v2 — OpenClaw Integration Roadmap

## Status: In progress (v18+ target)

## Feature 1: ContextEngine Plugin (v18)

OpenClaw's ContextEngine plugin slot provides full lifecycle hooks.

**Goal**: Replace SessionStart hook memory loading with a ContextEngine plugin that:
- Always includes BRIEFING.md in assembled context (`ingest` hook)
- Re-injects decisions.json and current phase after compaction (`compact` hook)
- Updates memory after each turn (`afterTurn` hook)

**Result**: Genius-Claw with lossless memory — no context loss on compaction.

## Feature 2: prependSystemContext (v18)

Use plugin `prependSystemContext` to inject Genius Team guidance into system prompt space:
- Anti-drift rules always present
- Better cache efficiency = lower per-turn cost
- Consistent baseline across all sessions

## Feature 3: Compaction Lifecycle Hooks (v17 partial, v18 full)

`session:compact:before` → trigger memory capture script  
`session:compact:after` → reload BRIEFING.md injection  
Currently using postCompactionSections in configs (v17).

## Feature 4: Per-topic Agent Routing (v18)

Use OpenClaw's per-topic agentId routing so different Discord topics can route to different Genius skills directly.

## Timeline

| Version | Feature |
|---------|---------|
| v17 ✅ | ACP provenance check, allowBots:mentions, postCompactionSections |
| v18 | ContextEngine plugin, prependSystemContext, compaction lifecycle |
| v19 | Lossless memory, per-topic routing, auto-heartbeat task generation |
