---
name: genius-workflow-loop
description: >-
  LP-09 meta-loop. Runs the GT product pipeline (Interview → Specs → Architecture →
  Dev → Review → Deploy) as ONE self-advancing loop on the loop kernel: each step has
  a deterministic gate (the existing guard/review IS the gate — review pass = gate
  crossed), the kernel advances step by step while gates pass and autonomy allows,
  and HALTs cleanly at explicit human checkpoints (specs, architecture, before
  deploy, before push). Use when user says "run the product pipeline as a loop",
  "workflow loop", "auto-advance the pipeline", "run interview to deploy",
  "resume the pipeline loop". Do NOT use for a single-goal iterate-until-green loop
  (genius-loop). Do NOT use without an approved workflow CONTRACT.md (write one
  first from templates/loops/gt-product-pipeline/ — no gate, no loop). Do NOT use
  for cron/schedule setup (genius-scheduler).
user-invocable: true
skills:
  - genius-loop
  - genius-goal-contract
  - genius-code-review
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Glob(*)
  - Grep(*)
  - Bash(*)
  - Task(*)
---

# Genius Workflow Loop — The Pipeline as One Loop

The product pipeline stops being 6 human-prompted phases and becomes one loop
contract the kernel advances through. Same LP-02 contract, plus a `## Workflow`
table; same brakes, STATE, Cortex control plane. Runtime: `scripts/loop-kernel.sh`
(`workflow_status` / `workflow_advance` / `workflow_approve`).

```
interview → specs ✋ → architecture ✋ → dev → review ✋(before deploy) → deploy ✋(before push)
            gate      gate               gate   gate = review verdict     gate = guard
```

**Hard rules**
- **No gate, no loop.** Each step's gate is a deterministic command (exit 0 = pass).
  The existing guard/review IS the gate: `scripts/review-gate.sh` passes only when
  the latest `.genius/reviews/review-*.md` contains no REQUEST_CHANGES/REJECT;
  `scripts/guard-validate.sh` gates deploy. Never the agent's opinion.
- **Human checkpoints are never bypassable** — not by L4, not by a green gate.
  `checkpoint=human` HALTs (exit 12) after the step's gate passes, until a human
  records a per-step approval (`workflow_approve` → `approvals/<step>`, traceable,
  per-action — GUARD-POLICY §5.5). They sit exactly where GT already puts them:
  after specs, after architecture (and after design if that row is added), plus the
  L3 boundaries **before deploy** and **before push/publish** (GUARD-POLICY §6).
- **Autonomy decides what auto-advances** (genius-auto Autonomy Ladder): at L1/L2
  EVERY step is a human checkpoint; L3+ auto-advances `checkpoint=auto` steps only.
  New contracts start L2 — promotion is earned.
- **The loop never codes directly.** Work inside a step routes to the normal GT
  skills (genius-interviewer, genius-specs, genius-architect, genius-dev,
  genius-code-review, genius-deployer). This skill only drives transitions.
- **Namespace isolation.** Everything lives in `.genius/loops/<slug>/`; never touch
  `.genius/state.json` or `.claude/plan.md`.

## Procedure

### 0. Contract first (refuse early)
No `.genius/loops/<slug>/CONTRACT.md` → copy the template and hand it to the human:
```bash
mkdir -p .genius/loops/gt-product-pipeline
cp templates/loops/gt-product-pipeline/CONTRACT.md .genius/loops/gt-product-pipeline/
```
Adapt the `dev` gate to the project's real test command. **Human approves the
contract**, then validate (also registers with Cortex — LP-06):
```bash
bash scripts/loop-kernel.sh contract_validate .genius/loops/gt-product-pipeline
```
Non-zero exit → report the errors and STOP (placeholder gates, bad checkpoint
values, duplicate steps, missing brakes/budget are all refused).

### 1. Drive the meta-loop
```bash
bash scripts/loop-kernel.sh workflow_status  .genius/loops/gt-product-pipeline
bash scripts/loop-kernel.sh workflow_advance .genius/loops/gt-product-pipeline <cumulative_tokens>
```
`<cumulative_tokens>` is your running estimate of the tokens the pipeline has burned so
far (integer); it is heartbeated to Cortex and arms the LP-07 token-budget kill switch
(estimate > contract `token_budget` → `kill:true` → exit 5). Omit it only when Cortex is
absent. Interpret `workflow_advance` exit codes:
- **0 — ADVANCE / resume / done.** Call `workflow_advance` again for the next transition.
- **1 — STEP GATE FAIL.** Do the step's actual work via the matching GT skill
  (dev → genius-dev, review → genius-code-review, …), inside the blast radius,
  then re-run `workflow_advance`. This inner iterate is exactly the genius-loop
  cycle scoped to one step.
- **12 — HALT: CHECKPOINT.** Clean halt: STATE is `blocked`,
  `awaiting: checkpoint:<step>`. Report to the human what passed and what
  approval is needed. Only a HUMAN runs:
  `bash scripts/loop-kernel.sh workflow_approve <loop_dir> <step>` — then
  `workflow_advance` resumes.
- **2/3/4/5/10/11 — brake HALT** (max_iterations / no-progress / flip-flop /
  Cortex kill / done / blocked): stop and report, same as genius-loop.

### 2. Every HALT ends with a report
```bash
bash scripts/loop-kernel.sh loop_report .genius/loops/gt-product-pipeline <accepted_steps> <tokens_used>
```
`<accepted_steps>` = steps whose gate passed this run, `<tokens_used>` = final cumulative
token estimate — both feed the LP-07 cost-per-accepted-change stats (`cortex loops --stats`).
Show: current step (`workflow_status`), gates crossed, checkpoint awaited or brake
hit, and what the next human action is.

## Cortex control plane (LP-06 — graceful degradation)
Identical to genius-loop: `contract_validate` registers (`cortex loops --register`),
every `workflow_advance` heartbeats through `brakes_check` (`--heartbeat`, carrying the
`<cumulative_tokens>` estimate you pass — LP-07 budget kill),
kill:true → exit 5, STATE blocked; completion sends `--report` with the
`<accepted_steps> <tokens_used>` cost accounting. **Without the
`cortex` CLI the pipeline runs unchanged** — the kernel logs
`WARNING: cortex CLI not reachable` to stderr and continues (no remote kill switch).

## Dry-run simulation (test)
`bash scripts/test-workflow-loop.sh` — hermetic simulation showing step→step
advancement, a failing step gate retry, the HALT at the L3 human checkpoint
(exit 12), approve → resume, completion (`done`), and graceful degradation
without Cortex. Run it after any kernel change.

## Definition of Done
- [ ] `contract_validate` passed before the first transition (or the loop refused).
- [ ] Every step advanced ONLY via its gate command — no self-declared pass.
- [ ] Every `checkpoint=human` HALTed and has a recorded `approvals/<step>` file.
- [ ] STATE.md tracks `step:`/`awaiting:`; `.genius/state.json` untouched.
- [ ] Loop ended via `done` or a brake — never by silently stopping.
- [ ] `loop_report` shown to the human.

## Handoff / Next Step
- No/invalid contract → **genius-goal-contract** (+ the pipeline template).
- Single-goal loop (one gate, no steps) → **genius-loop**.
- HALT at checkpoint → human approves (`workflow_approve`) or revises.
- `done` → the P4-08 boundary hooks still guard actual push/deploy commands;
  ship via genius-deployer. Pipeline proven stable across runs → only then
  consider scheduling (genius-scheduler).
