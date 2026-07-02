---
name: genius-scheduler
description: >-
  The BRIDGE from a locally-proven loop to a schedule. Documents the discipline
  manual → skill → loop → schedule and refuses to skip a step: only a loop with an
  approved CONTRACT.md, proven stable by hand (repeated `done` via its gate), may be
  scheduled — via native /schedule (cloud Routines) or cron + `claude -p`. Enforces
  heartbeat + logging for every unsupervised run (silent-death guard). Use when user
  says "schedule a task", "recurring check", "run every X minutes", "monitor
  continuously", "setup cron", "watch for changes", "periodic review", "scheduled task".
  Do NOT use for one-time execution (just run the command).
  Do NOT use to schedule a loop that has never been reliabilized by hand.
  Do NOT use for CI/CD pipelines (genius-ci) or deploy monitoring (genius-deployer).
context: fork
agent: genius-scheduler
user-invocable: false
allowed-tools:
  - Read(*)
  - Glob(*)
  - Grep(*)
  - Write(*)
  - Edit(*)
  - Bash(bash scripts/loop-kernel.sh*)
  - Bash(jq *)
  - Bash(cat *)
  - Bash(date *)
---

# Genius Scheduler — the Bridge to Scheduling

**Scheduling is the LAST arrow of a strict pipeline, never a shortcut.**

```
manual  →  skill  →  loop  →  schedule
```

> Discipline (from the corpus): if you cannot yet run it once by hand and check the
> result with a command, you are not ready to loop it — and a loop you cannot trust
> supervised must NEVER run unsupervised. This skill only ever adds the final arrow.

| Stage | What it means | Artifact / tool |
|-------|---------------|-----------------|
| **manual** | Run the task by hand; verify the result with a command. | a terminal + an exit-code check |
| **skill** | Wrap the task in a named, tested GT skill. | `.claude/skills/<skill>/SKILL.md` |
| **loop** | genius-goal-contract writes `CONTRACT.md`; **genius-loop** runs it locally with an objective gate + brakes. | `.genius/loops/<slug>/CONTRACT.md` + `STATE.md` |
| **schedule** | *This skill.* Only a stable loop earns a schedule. | native `/schedule` (cloud Routines) or `cron` + `claude -p` |

## The guardrail — NEVER schedule an un-reliabilized loop

Before writing ANY schedule, confirm the loop is proven by hand. Refuse otherwise:

- [ ] `.genius/loops/<slug>/CONTRACT.md` exists and passes
      `bash scripts/loop-kernel.sh contract_validate .genius/loops/<slug>` (objective gate,
      brakes, blast_radius, autonomy_level all present).
- [ ] The loop has been **run manually via genius-loop and reached `status: done`** on the
      gate across **≥ 3 independent runs** — check `STATE.md`
      (`bash scripts/loop-kernel.sh state_read .genius/loops/<slug>`). A loop that has never
      gone green by hand is NOT schedulable.
- [ ] `autonomy_level` and `blast_radius` are appropriate for unattended runs; anything that
      merges/deploys keeps a human-read gate (L3+).
- [ ] `token_budget` / max wall-time are declared — no unbudgeted unsupervised loop
      (runaway-recursion guard; the corpus's $47k/11-day failure).

If any box is unchecked → STOP and hand back to **genius-goal-contract** /
**genius-loop**. Scheduling does not fix an unreliable loop; it multiplies it.

## Requirements for every unsupervised run (silent-death guard)

An unattended loop with no heartbeat is how loops die silently. Every schedule MUST:

- **Heartbeat + logging** — each run appends a durable line (timestamp, `<slug>`, gate
  exit, iteration) to a log the operator can `tail`. `STATE.md` (via `state_write`) and
  `bash scripts/loop-kernel.sh loop_report` are the durable per-run record; mirror a
  one-line heartbeat to a persistent log/alert channel.
- **Gate timeout** — the contract's gate timeout kills a hung run and counts it FAIL
  (already enforced by `gate_run`).
- **Brakes on every run** — the scheduled command runs the loop THROUGH the kernel so
  `max_iterations` / `no_progress_after` / `flip_flop` still apply; a scheduled run is one
  loop invocation, not an uncapped daemon.
- **Kill switch** — a documented way to disable the schedule (delete the Routine / remove
  the crontab line) and a per-run budget cap.

## Scheduling methods

### 1. Native `/schedule` — cloud Routines (preferred, persistent)
Runs on a cron schedule without an open session. Invoke the harness `/schedule` skill to
create/list/update Routines that call the proven loop, e.g. "every day at 02:00, run
genius-loop against `.genius/loops/<slug>` and post the loop_report".

### 2. `cron` + `claude -p` (headless, self-hosted)
```bash
# proven loop <slug>, nightly, with heartbeat
0 2 * * *  cd /path/to/repo && \
  echo "[$(date -Iseconds)] START <slug>" >> .genius/loops/<slug>/heartbeat.log && \
  claude -p "Run genius-loop against .genius/loops/<slug>; then loop_report." \
    >> .genius/loops/<slug>/run.log 2>&1
```

### 3. In-session `/loop` — SUPERVISED only (not true scheduling)
`/loop 10m /skill genius-experiments` iterates while YOU watch. Use it to *reliabilize* a
loop by hand (the "loop" stage), not to leave it running unattended. Min 30s interval;
stops on session end or `STOP`.

## Configuration protocol

1. Verify the guardrail checklist above — refuse if any box is unchecked.
2. Pick the method: persistent → `/schedule` or cron+`claude -p`; supervised → `/loop`.
3. Record the schedule in `.genius/schedules.json` (slug, cron, method, budget, kill-switch).
4. Provide the activation command AND the disable/kill command to the user.
5. Log the decision to `.genius/memory/decisions.json`:
   `{"decision":"SCHEDULED: <slug> <cron>","reason":"proven stable N runs","tags":["scheduler","loop"]}`

## Cortex-managed schedules (future — LP-06)

When the Cortex loop control plane lands, scheduled loops register a heartbeat and expose a
per-loop / per-project / global kill switch and dashboard. Until then, the heartbeat/logging
requirements above are the operator's manual substitute — do not schedule without them.

## Handoffs

- **From genius-loop** — a loop proven `done` across runs, ready to schedule.
- **To genius-goal-contract / genius-loop** — send back any loop failing the guardrail.
- **From genius-orchestrator / genius-deployer** — recurring monitoring requests.

## Definition of Done

- [ ] Guardrail checklist passed (approved contract + ≥3 manual `done` runs + budget).
- [ ] Method selected; the scheduled command runs the loop THROUGH the kernel (brakes apply).
- [ ] Heartbeat + logging configured for the unsupervised run.
- [ ] Schedule written to `.genius/schedules.json`; activation AND kill commands given.
- [ ] Memory decision logged.
