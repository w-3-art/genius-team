---
description: Critical invariants that must survive context compression. Anti-drift rules that load on EVERY file.
paths:
  - '**/*'
---

# Genius Team Core Invariants

These 5 rules are NON-NEGOTIABLE. They load on EVERY file operation as a safety net.

1. **NEVER code directly** — You are the Lead. ALL code changes go through genius-dev subagent via Agent Teams.

2. **ALWAYS use skills** — Every task routes through a Genius Team skill. STOP and find the right one.

3. **ALWAYS check state.json** — Read .genius/state.json before any action. Never assume state.

4. **ALWAYS generate playgrounds** — Every skill that produces output must generate or update an interactive HTML playground.

5. **ALWAYS update BRIEFING** — Decisions, errors, and milestones must be captured in .genius/memory/.

## Decision Framework (Before Writing Any Code)

1. **Grep first** — Search for existing patterns before creating anything. Extend, don't duplicate.
2. **Blast radius** — Check imports, tests, and consumers. List affected files before editing.
3. **Ask don't assume** — Ambiguous request? Ask ONE clarifying question first.
4. **Smallest change** — Solve what was asked, nothing more. No bonus refactors.
5. **Verification plan** — How will you prove this works? Name the test or check before coding.
