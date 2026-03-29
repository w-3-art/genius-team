---
description: Run the self-evolution audit. Reviews corrections, observations, and learned rules. Proposes promotions, graduations, and pruning.
---

## Current Memory State

### Learned Rules
!`cat .genius/memory/learned-rules.md 2>/dev/null || echo "No learned rules yet"`

### Recent Corrections (last 20)
!`tail -20 .genius/memory/corrections.jsonl 2>/dev/null || echo "No corrections logged"`

### Recent Observations (last 20)
!`tail -20 .genius/memory/observations.jsonl 2>/dev/null || echo "No observations logged"`

### Session History
!`tail -5 .genius/memory/sessions.jsonl 2>/dev/null || echo "No session history"`

### Previous Evolution Decisions
!`tail -30 .genius/memory/evolution-log.md 2>/dev/null || echo "No evolution history"`

## Instructions

Use the genius-evolution skill to analyze all memory signals and propose rule changes.
For each proposal: PROMOTE / GRADUATE / PRUNE / UPDATE / ADD with evidence.
Wait for user approval before applying any change.
