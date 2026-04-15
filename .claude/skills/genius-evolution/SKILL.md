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

# Genius Evolution v22.0 — Self-Evolving Learning System

**Genius Team gets smarter every session. Corrections become rules. Rules get verified. The system evolves.**

## Memory Integration
Read `@.genius/memory/BRIEFING.md` for project context.
Read `@.genius/memory/learned-rules.md` for existing rules.

---

## HOW IT WORKS

### Layer 1: Dissatisfaction Analysis (continuous, intelligent)

This is NOT keyword matching. You must use your intelligence to detect ANY sign of user dissatisfaction, understand WHY they're unhappy, and extract the lesson.

**Signals to analyze (non-exhaustive — use judgment):**
- Explicit corrections ("no", "wrong", "that's not what I asked")
- Frustration ("this is terrible", "ça marche pas", "encore ?!", "t'es nul")
- Repeated requests (user asks the same thing twice = you failed the first time)
- Rewording (user rephrases their request = your interpretation was wrong)
- Undoing your work (user reverts, deletes, or manually redoes what you did)
- Silence after your output (long pause then topic change = output was useless)
- Sarcasm or rhetorical questions ("tu crois vraiment que c'est bon ?")
- Explicit rejection of approach ("pas comme ça", "c'est pas la bonne façon")
- Quality complaints ("c'est moche", "c'est basique", "ça fait mal aux yeux")
- Scope complaints ("c'est pas ce que j'ai demandé", "t'as rien compris")

**For EACH detected dissatisfaction:**

1. **Analyze the root cause** — don't just log what the user said. Understand WHY:
   - Was it a wrong interpretation of the request?
   - Was it a quality issue (too fast, too sloppy)?
   - Was it a missing context (didn't read existing code)?
   - Was it a process issue (skipped a step, didn't verify)?
   - Was it a technical mistake (wrong approach, incompatible)?
   - Was it a communication issue (too verbose, too terse, wrong language)?

2. **Extract the lesson** — formulate as a concrete, actionable rule:
   - Bad: "User was unhappy" (useless)
   - Good: "When modifying UI code, always verify the result visually before declaring it done"
   - Good: "Never propose a workaround (skip/bypass) when the real problem should be fixed"
   - Good: "Check compatibility with Claude Code AND Codex before proposing structural changes"

3. **Log** to `.genius/memory/corrections.jsonl`:
   ```json
   {"timestamp": "ISO", "user_signal": "what the user said/did", "root_cause": "why they were unhappy", "lesson": "the actionable rule extracted", "context": "what you were doing", "category": "quality|interpretation|process|technical|communication", "verify": "how to check compliance", "severity": "minor|major|critical"}
   ```

4. **Generate a verify pattern** when possible:
   - Process issue → verify: "Check that [step] was completed before [next step]"
   - Quality issue → verify: "manual — review output quality before presenting"
   - Technical → verify: `Grep("[bad pattern]") → 0 matches`

5. **Auto-promote on pattern detection:**
   - Same ROOT CAUSE appearing twice (not same words — same underlying issue) → promote to learned-rules.md
   - Tell the user: "I've learned: [lesson]. I'll verify this going forward."

6. **Apply the lesson immediately** — and retroactively check if the same mistake exists elsewhere

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

At the start of EVERY session, run the verification sweep:

1. Read `.genius/memory/learned-rules.md` — load all rules
2. For each rule with a `verify:` line:
   - If verify is a Grep pattern → run `Grep(pattern)` and check expected result
   - If verify is a Glob pattern → run `Glob(pattern)` and check expected result
   - If verify is "manual" → skip (cannot auto-verify)
3. **PASS** → silent, increment pass counter
4. **FAIL** → log to `.genius/memory/violations.jsonl`:
   ```json
   {"timestamp": "ISO", "rule": "rule name", "verify": "the check", "expected": "what should have been", "actual": "what was found", "session": "session-id"}
   ```
5. Surface ALL failures to user with: "Verification sweep found N violation(s):"
6. Track session results in `.genius/memory/sessions.jsonl`:
   ```json
   {"date": "ISO", "rules_checked": 8, "rules_passed": 7, "rules_failed": 1, "corrections_received": 0, "observations_made": 0, "violations": ["rule-name"]}
   ```
7. **Trend detection**: Read last 5 entries in sessions.jsonl. If `corrections_received` is increasing across sessions, the rules aren't working — flag for `/genius-evolve`.

### Layer 4: Session Scoring (at session end)

Before session ends, write a scorecard to `.genius/memory/sessions.jsonl`:

```json
{
  "date": "ISO",
  "rules_checked": 8,
  "rules_passed": 7,
  "rules_failed": 1,
  "corrections_received": 2,
  "observations_made": 1,
  "new_rules_added": 0,
  "rules_graduated": 0
}
```

Trend analysis:
- If `corrections_received` increasing over 3+ sessions → rules aren't preventing mistakes → flag for review
- If `rules_failed` consistently > 0 for same rule → rule may be obsolete → flag for pruning
- If `rules_passed` consistently 100% for 10+ sessions → rules are stable → candidates for graduation

### Layer 5: Evolution Audit (/genius-evolve)

Run manually every ~10 sessions or when learned-rules.md gets full (max 50 lines):

1. **Analyze corrections** — group by root cause, find repeats, identify missing rules
2. **Analyze observations** — check convergent signals, verify hypotheses still hold
3. **Audit learned rules** — still relevant? Should graduate to CLAUDE.md? Redundant?
4. **Check session trends** — read sessions.jsonl for patterns
5. **Propose changes**: PROMOTE / GRADUATE / PRUNE / UPDATE / ADD
6. **Wait for user approval** — apply only approved changes
7. **Log everything** to `.genius/memory/evolution-log.md`

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
