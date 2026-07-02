---
name: genius-experiments
description: >-
  Autonomous RESEARCH loop built on the loop kernel. A human-authored experiment.md
  is the source of the goal; it is compiled into a CONTRACT.md (gate = the evaluation
  command, standard brakes) and run via scripts/loop-kernel.sh for state/brakes/report.
  Iteratively modifies code, runs the evaluation, keeps improvements, reverts regressions.
  Designed for overnight runs. Use when user says "run experiments", "optimize overnight",
  "autonomous optimization", "A/B test implementations", "find the best approach".
  Do NOT use for regular feature implementation — use genius-dev skills instead.
  Do NOT use without an experiment.md + approved CONTRACT.md (no gate, no loop).
  Do NOT use for cron/schedule setup (genius-scheduler).
when_to_use: optimization, overnight, autonomous, iterative, A/B test
context: fork
agent: genius-experiments
user-invocable: true
skills:
  - genius-goal-contract
  - genius-code-review
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Glob(*)
  - Grep(*)
  - Bash(bash scripts/loop-kernel.sh*)
  - Bash(npm *)
  - Bash(npx *)
  - Bash(node *)
  - Bash(git diff*)
  - Bash(git status*)
  - Bash(git stash*)
  - Bash(git checkout*)
  - Bash(git add*)
  - Bash(git commit*)
hooks:
  PostToolUse:
    - type: command
      command: "bash -c 'echo \"[$(date +%H:%M:%S)] EXPERIMENTS: $TOOL_NAME\" >> .genius/experiments.log 2>/dev/null || true'"
  Stop:
    - type: command
      command: "bash -c 'echo \"EXPERIMENTS COMPLETE: $(date)\" >> .genius/experiments.log 2>/dev/null || true'"
      once: true
---

# Genius Experiments — the Research Loop

**Define the goal in `experiment.md`. Let the agent find the best path. Review the
results in the morning.** Inspired by Karpathy's autoresearch: autonomous iteration
over a well-defined metric, keeping improvements and reverting regressions.

This is the *research* specialization of the loop kernel. It reuses the SAME primitives
as **genius-loop** and **genius-goal-contract** — `CONTRACT.md`, `gate`, `brakes`,
`blast_radius`, `STATE.md`, `checker`, `autonomy_level` — and the SAME runtime,
`scripts/loop-kernel.sh`, for state/brakes/report. It does NOT re-implement stop
conditions, run logs, or reports.

## No gate, no loop

`experiment.md` is the human-authored **source of the goal**; the compiled
`.genius/loops/<slug>/CONTRACT.md` is what the loop actually runs against. No approved
contract → do NOT loop. The gate is the evaluation command whose exit code is the
objective measure of "better", never the agent's opinion.

## `experiment.md` → CONTRACT.md mapping

Author `experiment.md` in the project root; compile each field into the contract:

| experiment.md field                 | CONTRACT.md field |
|-------------------------------------|-------------------|
| **Objective** (what to improve)     | `goal` |
| **Success Metric** (command + key + baseline + target + higher-is-better) | `gate` (+ target as the stopping condition) |
| **Experiment Scope** (files allowed / never-touch) | `blast_radius.allowed_files` / forbidden |
| **Evaluation Command**              | `gate` command (exit 0 = meets target) |
| **Constraints** (max runs / max time / max consecutive regressions) | `brakes` (`max_iterations`, `token_budget`, `no_progress_after`, `flip_flop`) |
| **Ideas to Try**                    | the maker's backlog for the EXECUTE step |

```markdown
# Experiment: Reduce /api/users/search p95
## Objective        Reduce API response time for the search endpoint
## Success Metric    Command: npm run benchmark -- --output json | Key: p95_ms | Baseline: 450 | Target: <200 | Higher is better: false
## Experiment Scope  Allowed: src/api/users.ts, src/db/queries/users.ts | Never: *.test.ts, package.json, prisma/schema.prisma
## Constraints       Max runs: 20 | Max time: 4h | Max consecutive regressions: 3
## Ideas to Try      1. index users.name  2. redis cache 5m TTL  3. full-text search
## Evaluation Command  npm run benchmark -- --endpoint /api/users/search --runs 100 --output json
```

Compile with **genius-goal-contract** (writes/validates the CONTRACT.md) and get human
approval before the loop runs. Start at `autonomy_level: L1`/`L2`.

## Setup (safe iteration — preserved)

```bash
LOOP=.genius/loops/<slug>
git checkout -b experiment/$(date +%Y%m%d-%H%M%S)     # never experiment on main/staging/prod
bash scripts/loop-kernel.sh contract_validate "$LOOP" # refuse early if the contract is not runnable
bash scripts/loop-kernel.sh state_read        "$LOOP" # init/read STATE.md
bash scripts/loop-kernel.sh gate_run          "$LOOP" # baseline evaluation
bash scripts/loop-kernel.sh state_write "$LOOP" in-progress <exit> "baseline metric=<value>"
```

## Experiment loop (kernel-driven)

```
READ experiment.md + STATE.md
  ↓
LOOP:
  brakes_check → non-zero = HALT (max_runs / no_progress / flip_flop)
  1. Pick the next idea (or generate a variant) inside the blast radius
  2. git stash --include-untracked      # save state (rollback trail)
  3. Implement ONE change
  4. gate_run → read the metric from the evaluation output
  5. IMPROVED → git stash drop (keep) [+ optional commit];  REGRESSED → git stash pop (revert)
  6. state_write "$LOOP" in-progress <gate_exit> "run N metric=<value> kept=<y/n>"
  ↓
loop_report → HALT+report; write final report to .genius/loops/<slug>/report-<date>.md
```

The kernel now owns cap / plateau / oscillation detection and the run log — do NOT
hand-roll `runs-*.jsonl` or bespoke stop conditions. The evaluation-driven keep/revert
(git stash) and the branch isolation remain this skill's protocol.

## Checker (maker ≠ checker)

On a green gate, dispatch **genius-code-review** (read-only) as the end-of-loop
adversarial checker before any winning change is proposed for merge. The maker never
signs off on its own change.

## Running overnight & in parallel (preserved)

- Overnight (supervised): `/loop 10m /skill genius-experiments`, or a persistent session
  (`tmux new-session -d -s experiments 'claude --skill genius-experiments'`). Monitor with
  `tail -f .genius/experiments.log` and `cat .genius/loops/<slug>/STATE.md`.
- Parallel (Dual/Codex): run one loop per hypothesis (caching / query / architecture),
  each its own `<slug>` contract against the same gate; merge the winners at the end.
- Unsupervised scheduling is a SEPARATE step — hand to **genius-scheduler**, which refuses
  to schedule a loop not yet proven stable by hand.

## Safety rules (preserved)

1. **Never experiment on** `main`, `production`, or `staging` — always a dedicated branch.
2. **Never modify** anything outside the contract's `blast_radius` (tests, package.json,
   schema, env files stay off-limits).
3. **Always** keep a git stash/commit trail — every change is reversible.
4. **Namespace isolation** — loop state only in `.genius/loops/<slug>/`; never
   `.genius/state.json` or `.claude/plan.md`.
5. **Emergency stop** — `git stash; git checkout main` abandons the experiment instantly.

## Definition of Done

- [ ] experiment.md authored; CONTRACT.md compiled, validated, and human-approved.
- [ ] Baseline measured via `gate_run`; every run measured the evaluation command.
- [ ] Each change is traceable and reversible (branch + stash/commit trail).
- [ ] Winner / loser / inconclusive identified; winning change counter-verified by checker.
- [ ] Loop ended via `done` or a brake; `loop_report` + report-<date>.md produced.

## Handoff / Next Step

- No/invalid contract → **genius-goal-contract**.
- Winning change → **genius-qa-micro** (tests) → **genius-code-review** → **genius-deployer**.
- Loop proven stable across runs → only then **genius-scheduler** to schedule it.
