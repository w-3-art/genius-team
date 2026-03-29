---
name: genius-evolution
description: >-
  Self-evolving learning system. Captures corrections, verifies codebase patterns,
  promotes learned rules, and makes Genius Team smarter every session.
  Auto-triggers when user corrects Claude ("no", "wrong", "I told you", "we don't do that").
  Also invocable via /genius-evolve for manual evolution audit.
  Do NOT use for code implementation (use genius-dev).
  Do NOT use for autoresearch optimization loops (use genius-autoresearch).
user-invocable: true
context: fork
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Grep(*)
  - Glob(*)
  - Bash(grep *)
  - Bash(wc *)
  - Bash(cat *)
  - Bash(tail *)
---

# Genius Evolution v21.0 — Self-Evolving Learning System

**Genius Team gets smarter every session. Corrections become rules. Rules get verified. The system evolves.**

## Memory Integration
Read `@.genius/memory/BRIEFING.md` for project context.
Read `@.genius/memory/learned-rules.md` for existing rules.

---

## HOW IT WORKS

### Layer 1: Correction Capture (auto-triggered)

When the user corrects you ("no", "wrong", "I told you", "we don't do that", "stop doing X"):

1. **Acknowledge** the correction naturally
2. **Log** to `.genius/memory/corrections.jsonl`:
   ```json
   {"timestamp": "ISO", "correction": "what", "context": "what you were doing", "category": "style|architecture|security|testing|naming|process", "times_corrected": 1, "verify": "Grep pattern or manual"}
   ```
3. **Generate a verify pattern** immediately:
   - "Don't do X" → `Grep("[X pattern]", path="src/") → 0 matches`
   - Can't generate check → `"verify": "manual"` (debt for /genius-evolve)
4. **Auto-promote on 2nd correction:**
   - Same pattern corrected twice → auto-add to `.genius/memory/learned-rules.md` WITH verify line
   - Tell the user: "Learned permanently: [rule]. Verification: [check]."
5. **Apply the correction immediately**

### Layer 2: Hypothesis-Driven Observations

When you notice a codebase pattern during work:

1. **Formulate** as testable claim: "All service functions return Result<T>"
2. **Test immediately** — grep for counter-examples
3. **Log** to `.genius/memory/observations.jsonl`:
   ```json
   {"timestamp": "ISO", "type": "convention|gotcha|architecture|performance", "hypothesis": "...", "evidence": "...", "counter_examples": 0, "confidence": "confirmed|high|medium|low", "verify": "Grep pattern"}
   ```
4. **Auto-promote** if confirmed + 0 counter-examples → add to learned-rules.md

### Layer 3: Verification Sweep (at session start)

At the start of complex tasks, silently verify all rules in learned-rules.md:

1. Read each rule with a `verify:` line
2. Run the check (Grep/Glob)
3. **PASS** → silent. **FAIL** → log to `.genius/memory/violations.jsonl` and surface to user
4. Track in `.genius/memory/sessions.jsonl`:
   ```json
   {"date": "ISO", "rules_checked": 8, "rules_passed": 8, "rules_failed": 0, "corrections_received": 0}
   ```

### Layer 4: Evolution Audit (/genius-evolve)

Run manually every ~10 sessions or when learned-rules.md gets full (max 50 lines):

1. **Analyze corrections** — group by pattern, find repeats, identify missing rules
2. **Analyze observations** — check convergent signals
3. **Audit learned rules** — still relevant? Should graduate to CLAUDE.md? Redundant?
4. **Propose changes**: PROMOTE / GRADUATE / PRUNE / UPDATE / ADD
5. **Wait for user approval** — apply only approved changes
6. **Log everything** to `.genius/memory/evolution-log.md`

## RULES

- Never remove security rules during evolution
- Never weaken anti-drift rules
- Max 50 lines in learned-rules.md (force graduation or pruning)
- Every rule must have a machine-checkable verify line
- A rule without verification is a wish. A rule with verification is a guardrail.
- Bias toward specificity over abstraction
- Never re-propose a rejected rule (check evolution-log.md)

## Capacity Management

Before adding to learned-rules.md:
1. Count lines (max 50)
2. If approaching 50 → suggest /genius-evolve to graduate or prune
3. Rules that passed 10+ sessions → candidates for CLAUDE.md graduation

## Definition of Done
- [ ] Correction/observation logged with verify pattern
- [ ] Auto-promotion triggered if 2nd correction
- [ ] Verification sweep run on session start
- [ ] Evolution audit completed (if invoked)

## Handoff
After correction capture → return to current task.
After evolution audit → user decides next steps.
