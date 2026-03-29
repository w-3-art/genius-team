---
description: Memory system rules — how to use BRIEFING.md, decisions.json, and learned-rules.md
paths:
  - '.genius/memory/**/*'
  - '**/BRIEFING*'
---

# Genius Team — Memory System

> Genius Team uses **two complementary memory layers**. Know which to use.

## Memory Hierarchy

| Layer | Location | What goes here | Shared? |
|-------|----------|----------------|---------|
| Auto Memory | `~/.claude/projects/<project>/memory/MEMORY.md` | Personal learnings, debugging insights | No |
| Team Memory | `.genius/memory/` | Decisions, patterns, errors, progress | Yes (git) |
| Learned Rules | `.genius/memory/learned-rules.md` | Self-evolution graduated rules | Yes |

## When Writing Memory
- "Remember that..." → `.genius/memory/decisions.json`
- "This broke because..." → `.genius/memory/errors.json`
- "Pattern: ..." → `.genius/memory/patterns.json`
- Corrections → `.genius/memory/corrections.jsonl` (auto by evolution engine)

## When Reading Memory
- Session start → BRIEFING.md is auto-loaded
- Complex tasks → check learned-rules.md
- Debugging → check errors.json for similar issues
