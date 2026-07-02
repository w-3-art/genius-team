---
name: genius-goal-contract
description: >-
  Loop-engineering meta-skill. Turns a vague request into a rigorous GOAL CONTRACT
  BEFORE any loop work starts: expected result, objective verification method (the gate —
  an exact pass/fail command, never the agent's opinion), do-not-touch blast radius,
  stopping condition, proof of completion written up front, and a budget (max iterations,
  time, approx tokens). Writes .genius/loops/<slug>/CONTRACT.md.
  Use when the user says "define a goal", "make this a loop", "run until done",
  "set up a loop", "goal contract", "loop this until it passes", "keep iterating until".
  Do NOT use for one-shot tasks (just run the relevant genius-dev/genius-debugger skill).
  Do NOT use to run the loop itself (that is genius-loop, LP-02).
  Do NOT use for schedule/cron setup (genius-scheduler).
context: fork
agent: genius-goal-contract
user-invocable: true
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Glob(*)
  - Grep(*)
  - Bash(git status*)
  - Bash(git diff*)
  - Bash(ls *)
  - Bash(cat *)
---

# Genius Goal Contract — No Gate, No Loop

**Fixes failure mode #1: "your instructions are just vague."** A loop with no verifiable
stopping condition is a random walk that burns tokens. This skill forces a contract FIRST.

> Discipline: **manual → skill → loop → schedule**, never the reverse. If you cannot yet
> run this once by hand and check the result with a command, you are not ready to loop it.

---

## The Rule

**No objective gate → no loop.** The gate is a command that exits 0 (pass) or non-zero
(fail). Tests, lint, build, a benchmark threshold — never "the agent thinks it looks good."
If success cannot be expressed as a command, stop and make it measurable before looping.

**The gate must be DETERMINISTIC.** Given the same code, the gate's exit code (and any
metric it prints) must be the same every run. No timestamps, random seeds/ordering, network
flakiness, wall-clock durations, or unseeded randomness in what decides pass/fail. A
non-deterministic gate makes `no_progress_after` and `flip_flop` detection blind — the
kernel (`scripts/loop-kernel.sh`) hashes each gate result to spot a stuck loop, and a gate
whose output changes run-to-run for no code reason looks like permanent progress (or
permanent oscillation) even when nothing changed, defeating the no-progress/flip-flop brakes.
If a metric is inherently noisy (e.g. timing), gate on a stable derived signal (median of N
runs, a fixed seed, a pass/fail threshold) — never on the raw noisy number.

---

## Procedure

1. **Read state first.** If `.genius/loops/<slug>/STATE.md` exists, read it — the loop may
   already be `done`/`blocked`. Never restart a finished loop.
2. **Interrogate the request until each field below is unambiguous.** Ask the user to
   resolve anything vague. Refuse to proceed on "make it better" — demand a threshold.
3. **Define proof of completion BEFORE any work.** Write down the exact command whose exit
   code proves done. This is non-negotiable and cannot be edited to fit a failing result.
4. **Set the blast radius.** List the files/globs and commands the loop may touch. Anything
   outside is forbidden — that is the do-not-touch boundary.
5. **Set the brakes** (see below). Every brake is a hard cap.
6. **Start autonomy at L1 or L2.** Never open a fresh loop at L3/L4.
7. **Write** `.genius/loops/<slug>/CONTRACT.md` from the template. Slug = kebab-case goal.
8. **Get human approval of the contract** before the loop runs (comprehension gate).

---

## Contract fields

- **goal** — verifiable stopping condition, phrased as a contract, not a wish.
- **gate** — the exact pass/fail command. Objective only. Never the agent's judgment.
  Must be deterministic (no timestamps/randomness in what decides pass/fail — see "The Rule").
- **brakes** — `max_iterations`, `token_budget` (approx), `no_progress_after` N iterations
  with no gate change, and `flip_flop` detection (same file oscillating between two states).
- **blast_radius** — allowed files/globs + allowed commands. Everything else is off-limits.
- **state** — path to `STATE.md` (`done`/`in-progress`/`blocked`/`next`), read at start of
  every run, written at the end of every run.
- **autonomy_level** — L1 suggest-only → L2 draft → L3 apply-low-risk-with-merge-approval →
  L4 full-auto-with-audit-logs. New loops start L1/L2; L3 requires a week of read/approved
  L1/L2 outputs; L4 requires an active audit log AND a human-read gate at merge that is never
  bypassable — "level four is earned, not assumed." Canonical definitions live in
  `genius-auto`'s "Autonomy Ladder" section — this field must stay consistent with it.
- **checker** — the verifier, kept separate from the maker. The thing that produced the
  change never signs off on it.

---

## Canonical loop cycle (documented in the contract, executed by genius-loop)

```
read STATE → DISCOVER → PLAN → EXECUTE → VERIFY (gate + separate checker)
           → write STATE → ITERATE or HALT+report
```

## The 4 deaths this contract prevents

- **Runaway recursion** → `max_iterations` + `token_budget` caps.
- **Silent death** → heartbeat/timeout on the gate; a hung gate fails the run.
- **Random walk** → objective gate, not opinion.
- **Comprehension debt** → human-read gate at merge (L3+ requires approval).

---

## CONTRACT.md template (write this exactly, filling every field)

```markdown
# Loop Contract: <goal title>

- slug: <kebab-case-slug>
- created: <ISO date>
- author: <human>
- autonomy_level: L1   # L1 suggest-only | L2 draft | L3 apply-low-risk-with-merge-approval | L4 full-auto-with-audit-logs (see genius-auto)

## Goal (stopping condition — a contract, not "make it better")
<One sentence. Done means exactly this and nothing more.>

## Gate (objective pass/fail — the ONLY measure of done)
```bash
<exact command; exit 0 = pass, non-zero = fail>
```
- Interpretation: PASS when exit code == 0.
- Timeout: <e.g. 300s> — exceeding it counts as FAIL (silent-death guard).

## Proof of completion (defined BEFORE work; immutable)
<What artifact/output/exit code will be shown as proof. Cannot be edited to fit a result.>

## Blast radius (do-not-touch boundary)
- allowed_files:
  - <glob or path>
- allowed_commands:
  - <command>
- forbidden: everything not listed above (no pushes, no publish, no unrelated refactors).

## Brakes (hard caps)
- max_iterations: <N>
- token_budget: <approx, e.g. 200k>
- no_progress_after: <N> iterations with no change in gate result → HALT+report
- flip_flop: HALT if any file oscillates between two states across iterations

## Checker (separate from maker)
<Who/what verifies — a distinct reviewer/skill/command, never the maker's self-assessment.>

## State
- path: .genius/loops/<slug>/STATE.md
- protocol: read at run start, write at run end (done | in-progress | blocked | next)

## Budget
- max_wall_time: <e.g. 30m>
- max_iterations: <N>   # mirrors brakes
```

---

## Definition of Done
- [ ] `.genius/loops/<slug>/CONTRACT.md` written with EVERY field filled (no `<...>` left).
- [ ] Gate is a real command that exits 0/non-zero — verified runnable, not aspirational.
- [ ] Proof of completion was fixed before any implementation work.
- [ ] Blast radius and brakes are explicit.
- [ ] Autonomy starts at L1 or L2.
- [ ] Human has approved the contract.

## Handoff / Next Step
Contract approved → hand to **genius-loop** (LP-02) to execute the cycle against this gate.
No approved contract → do NOT loop; run the task once manually (genius-dev / genius-debugger)
and revisit whether it should be a loop at all.
