---
name: genius-autoresearch
description: >-
  Karpathy-inspired autonomous OPTIMIZATION loop, built on the loop kernel.
  Modifies a component, measures a benchmark, keeps if better, reverts if worse,
  repeats until the gate is met or the brakes halt it. The benchmark is the gate;
  state/brakes/report come from scripts/loop-kernel.sh — not ad-hoc plumbing.
  Use when user says "/autoresearch", "optimize this", "improve this automatically",
  "run autoresearch", "make this better autonomously".
  Do NOT use for initial implementation (use genius-dev).
  Do NOT use for simple fixes (use genius-debugger).
  Do NOT use without a CONTRACT.md whose gate is the benchmark (write one first with
  genius-goal-contract — no gate, no loop).
  Do NOT use for cron/schedule setup (genius-scheduler).
when_to_use: optimization, overnight, autonomous, iterative, karpathy
user-invocable: true
context: fork
skills:
  - genius-goal-contract
  - genius-reviewer
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Grep(*)
  - Glob(*)
  - Bash(*)
  - Task(*)
---

# Genius Autoresearch — the Evaluation Loop (Karpathy)

**Modify → measure → keep if better → revert if worse → repeat.** This is the
*optimization* specialization of the loop kernel. Where **genius-loop** drives a
build-fix loop against a pass/fail gate, autoresearch drives an **evaluation** loop:
it measures a benchmark metric every iteration and keeps the best candidate.

It reuses the SAME primitives as genius-loop and genius-goal-contract —
`CONTRACT.md`, `gate`, `brakes`, `blast_radius`, `STATE.md`, `checker`,
`autonomy_level`. The plumbing (state, brakes, report) lives in
`scripts/loop-kernel.sh`. **This skill owns only the modify→measure→keep/revert
judgment** — it does NOT re-implement stop conditions, logging, or reporting.

## No gate, no loop

Autoresearch needs `.genius/loops/<slug>/CONTRACT.md` whose **gate is the benchmark
it measures**. No contract → run Discovery below to define one (or hand to
**genius-goal-contract**) and stop. The gate is a benchmark command that prints a
metric and **exits 0 only when the candidate meets-or-beats the kept baseline**:
the printed metric drives keep/revert; the exit code is the objective stop signal
the kernel's brakes read. Example gate: `autoresearch/benchmarks/run-benchmark.sh 1 --quick`.

## Memory

Read `@.genius/memory/BRIEFING.md` for context and `@.genius/memory/decisions.json`
for prior optimization decisions.

## Discovery — writes the contract (this IS the benchmark protocol)

When `/autoresearch` is invoked with no contract, interrogate the request until each
CONTRACT.md field is unambiguous. Refuse "make it better" — demand a measurable metric.

1. **What to optimize?** → `goal` (routing accuracy, response time, spec quality, …).
2. **How do we measure "better"?** → `gate` — the exact benchmark command, the metric
   key to read from its output, and whether higher is better. This is objective, never
   the agent's opinion. A subjective quality metric must be scored by the human or
   **genius-reviewer** (maker ≠ checker), never self-scored.
3. **Constraints?** → `brakes`: `max_iterations` (default 30), `token_budget`,
   `no_progress_after` (default 5 → plateau halt), `flip_flop` detection.
4. **Which file(s)?** → `blast_radius`: `allowed_files` + `allowed_commands`. Everything
   else is off-limits.
5. **Minimum score to keep a change?** → the keep threshold.

Confirm the plan, write `.genius/loops/<slug>/CONTRACT.md` (genius-goal-contract
template), and get human approval before iterating. Start at `autonomy_level: L1`/`L2`.

## Baseline

```bash
LOOP=.genius/loops/<slug>
bash scripts/loop-kernel.sh state_read  "$LOOP"                 # init/read STATE.md
bash scripts/loop-kernel.sh gate_run    "$LOOP"                 # benchmark current version
bash scripts/loop-kernel.sh state_write "$LOOP" in-progress <exit> "baseline metric=<score>"
```

Back up the target file(s) before the first change. Record the baseline metric as
best-so-far.

## Iteration loop (modify → test → measure → keep/revert)

For each iteration:

```bash
bash scripts/loop-kernel.sh brakes_check "$LOOP"   # non-zero = HALT (max_iter / no_progress / flip_flop)
```

1. **Analyze** — pick ONE focused change, inside the blast radius, based on prior results.
2. **Modify** — apply that single change (one change per iteration — never batch).
3. **Measure** — `gate_run "$LOOP"`; read the metric from the benchmark output/`last-gate.log`.
4. **Decide** (the preserved benchmark protocol):
   - metric **better** than best → **KEEP**; best = metric.
   - **equal** → keep only if simpler/cleaner; else revert.
   - **worse** → **REVERT completely** (restore the backup — no partial keeps).
5. **Persist** — `state_write "$LOOP" in-progress <gate_exit> "iter N metric=<score> kept=<y/n>"`.
   The kernel hashes each result and drives the no-progress / flip-flop / cap brakes —
   do NOT hand-roll plateau or oscillation detection.
6. **Report one line** — iteration, score, delta from baseline, kept/reverted.

Stop when `brakes_check` returns non-zero (MAX_ITERATIONS / NO_PROGRESS / FLIP_FLOP) or
the gate meets the target. On target reached:
`state_write "$LOOP" done 0 "target metric reached"`.

## Report

```bash
bash scripts/loop-kernel.sh loop_report "$LOOP"
```

Show baseline → final delta, the kept changes (best first), and the failed attempts
(still valuable data). Optionally generate `.genius/outputs/autoresearch-playground.html`.
Append the outcome to `.genius/memory/decisions.json`, then ask the user if satisfied.

## Running continuously

Autoresearch self-paces. For overnight runs, drive it with the native `/loop` while it
is still supervised — schedule an unsupervised run ONLY after it is proven stable
(hand it to **genius-scheduler**, which enforces the manual → skill → loop → schedule
discipline).

## Rules (preserved)

- **ALWAYS back up** target files before a change; **REVERT completely** on a worse score.
- **ONE change per iteration** — never batch multiple changes.
- **NEVER modify** files outside the contract's `blast_radius`.
- **Maker ≠ checker** — subjective quality is scored by the human or genius-reviewer.
- **Namespace isolation** — only `.genius/loops/<slug>/`; never touch `.genius/state.json`
  or `.claude/plan.md` (the Stop hook owns that sync).

## Definition of Done

- [ ] CONTRACT.md exists with the benchmark as an objective gate + brakes + blast_radius.
- [ ] Baseline measured via `gate_run` and written to STATE.md.
- [ ] Every iteration measured the benchmark — no self-declared "better".
- [ ] At least 5 iterations, final metric > baseline, all reverts complete.
- [ ] Loop ended via `done` or a brake — never by silently stopping; `loop_report` shown.

## Handoff / Next Step

- No/invalid contract → **genius-goal-contract**.
- HALT on a brake → human revises the contract (new budget/approach) or stops.
- Proven stable across runs → only then **genius-scheduler** to schedule it.
