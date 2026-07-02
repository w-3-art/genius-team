---
name: genius-loop
description: >-
  Loop Engineering kernel (runtime). Executes an APPROVED loop contract written by
  genius-goal-contract: read STATE → DISCOVER → PLAN → EXECUTE (route to a GT skill,
  never code directly) → VERIFY (objective gate + separate checker) → write STATE →
  ITERATE or HALT+report. Brakes enforced by scripts/loop-kernel.sh: max_iterations,
  no-progress, flip-flop, gate timeout. Use when user says "run the loop", "start the
  loop", "iterate until the gate passes", "execute the contract", "resume loop <slug>".
  Do NOT use without a CONTRACT.md (write one first with genius-goal-contract — no gate,
  no loop). Do NOT use for one-shot tasks (genius-dev / genius-debugger).
  Do NOT use for cron/schedule setup (genius-scheduler).
user-invocable: true
skills:
  - genius-dev
  - genius-qa-micro
  - genius-debugger
  - genius-reviewer
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Glob(*)
  - Grep(*)
  - Bash(*)
  - Task(*)
---

# Genius Loop — The Kernel

Runs the canonical cycle against a loop contract. The runtime helpers live in
`scripts/loop-kernel.sh`; this skill is the driver, the kernel is the brakes.

```
read STATE → DISCOVER → PLAN → EXECUTE → VERIFY (gate + separate checker)
           → write STATE → ITERATE or HALT+report
```

**Hard rules**
- **No gate, no loop.** No `CONTRACT.md` → hand off to genius-goal-contract and stop.
- **The loop never codes directly** (GENIUS_GUARD). EXECUTE always routes to the right
  GT skill (genius-dev-* via genius-dev routing, genius-debugger for fixes).
- **Namespace isolation.** All loop state lives in `.genius/loops/<slug>/`. NEVER touch
  `.genius/state.json` or `.claude/plan.md` — the Stop hook owns that sync.
- **Maker ≠ checker.** The gate result is counter-verified by the read-only
  `genius-reviewer` subagent, never by the skill that produced the change.

## Procedure

### 0. Preflight (refuse early, refuse loudly)
```bash
bash scripts/loop-kernel.sh contract_validate .genius/loops/<slug>
```
Non-zero exit → report the errors and STOP. Do not "fix" the contract yourself; that is
genius-goal-contract's job plus human approval. Validation refuses: missing
goal/gate/brakes/blast_radius/checker, placeholder or non-executable gates, and any
blast-radius path outside the project root.

Read `autonomy_level` from the contract. It decides what EXECUTE may do:
- **L1 (suggest)** — analysis only; write findings/proposals to
  `.genius/loops/<slug>/proposals/`, apply nothing.
- **L2 (draft)** — write draft diffs/files under `proposals/`, apply nothing. **Default.**
- **L3 (apply low-risk)** — dispatch skills that apply changes INSIDE the blast radius;
  merge/commit/deploy still requires explicit human approval (human-read gate).
- **L4 (full-auto-with-audit-logs)** — only if the contract literally says `autonomy_level: L4`
  AND an active audit log exists. The human-read gate at merge still applies — L4 removes the
  blocking prompt, never the review (see genius-auto's Autonomy Ladder — "level four is earned,
  not assumed").
Anything not stated ≥ L3 in the contract means: the loop PROPOSES, it does not apply.

### 1. Read STATE
```bash
bash scripts/loop-kernel.sh state_read .genius/loops/<slug>
bash scripts/loop-kernel.sh brakes_check .genius/loops/<slug>   # before ANY work
```
`brakes_check` non-zero → skip to step 6 (HALT). `status: done` loops are never restarted.

### 2. DISCOVER
Read the `Next` / `Blocked` sections of STATE.md and inspect only files inside the
blast radius. Identify the smallest step that could change the gate result.

### 3. PLAN
One iteration = one small, verifiable step. State it in one sentence before acting.

### 4. EXECUTE (delegate, respecting blast radius + autonomy)
Route through the existing GT skill routing: code changes → genius-dev (which dispatches
to genius-dev-frontend/backend/database/api/mobile/web3), bug fixes → genius-debugger,
quick validation → genius-qa-micro. Constrain the dispatched skill to the contract's
`allowed_files` and `allowed_commands`. At L1/L2, output goes to `proposals/` only.

### 5. VERIFY (gate, then separate checker)
```bash
bash scripts/loop-kernel.sh gate_run .genius/loops/<slug>
```
Objective only — exit 0 is the ONLY pass. A hung gate is killed at the contract's
timeout and counts as FAIL (silent-death guard). If the gate PASSES, dispatch the
**genius-reviewer** subagent (Task, read-only) to counter-verify: does the change
actually satisfy the contract's Goal and Proof of completion, inside the blast radius?
Checker REQUEST_CHANGES/REJECT → treat the iteration as failed despite the green gate.

### 6. Write STATE, then ITERATE or HALT
```bash
bash scripts/loop-kernel.sh state_write .genius/loops/<slug> <status> <gate_exit> "<gate output summary>"
bash scripts/loop-kernel.sh brakes_check .genius/loops/<slug>
```
Status: `done` (gate PASS + checker approve), `blocked` (needs human input), else
`in-progress`. Also update the `Done` / `In Progress` / `Blocked` / `Next` sections of
STATE.md by hand — the next run starts from them. Then:
- `brakes_check` exit 0 → go to step 2 (next iteration).
- Any other exit (MAX_ITERATIONS / NO_PROGRESS / FLIP_FLOP / DONE / BLOCKED) → HALT:
```bash
bash scripts/loop-kernel.sh loop_report .genius/loops/<slug>
```
Show the report to the human with: what changed, final gate verdict, checker verdict,
and (on a brake halt) what you would try next if the loop were re-authorized.

## Definition of Done
- [ ] `contract_validate` passed before iteration 1 (or the loop refused to start).
- [ ] Every iteration ran the gate via `gate_run` — no self-declared success.
- [ ] Gate passes were counter-verified by genius-reviewer (maker ≠ checker).
- [ ] STATE.md written after every iteration; `.genius/state.json` untouched.
- [ ] Loop ended via `done` or a brake — never by silently stopping.
- [ ] `loop_report` shown to the human.

## Handoff / Next Step
- No contract or invalid contract → **genius-goal-contract**.
- HALT on a brake → human decides: revise the contract (new budget/approach) or abandon.
- `done` at L3+ → human merge approval (comprehension gate), then genius-qa /
  genius-deployer as the project workflow dictates.
- Loop proven stable across runs → only then consider scheduling it (genius-scheduler).
