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
- [ ] For scheduled/webhook/remote triggers, both fields above are mandatory, not just
      "appropriate" — see "Trigger safety" below for the hard-refuse rule.

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

## Trigger safety — scheduled / webhook / remote (P5-06, veille P0)

**"No gate, no loop" extends to triggers: no budget, no trigger.** A trigger firing an
unattended loop is EXECUTE with nobody watching, plus an external party decides
*when*. Refuse ANY scheduled/webhook/remote trigger unless **both** hold:

- [ ] `autonomy_level` declared in the target `CONTRACT.md` (L1-L4) — undeclared is
      refused, never defaulted to L1.
- [ ] `blast_radius` bounded and passes `contract_validate` — empty/wildcard refused.

**Dedup, thread-aware (GT policy, not native).** GitHub-triggered Routines start a new
session per event with no reuse; channel webhooks (`notifications/claude/channel`) are
fire-and-forget, unacknowledged. Neither dedups. A retrying sender re-fires the loop, so
genius-scheduler MUST record an idempotency key (delivery/thread/PR-SHA ID) in
`.genius/schedules.json` before EXECUTE and skip an already-processed key — one event,
one run.

**One-shots: use native `deleteAfterRun`.** One-shot `CronCreate` tasks and `/loop`
reminders delete themselves after firing; a Routine's one-off trigger auto-disables and
shows **Ran**. Never hand-roll a "fake one-shot" recurring job.

**Destination preserved on recurring runs.** A Routine's connector/prompt destination
stays constant across runs even though each run is a new session; a channel reply must
echo the inbound `chat_id`/thread meta so it lands in the triggering thread, not the
most recent one.

**Fallback model per trigger — fable/opus/sonnet only.** Native `fallbackModel` in
`settings.json` is a global session-scoped chain (max 3, no cross-file merge) — not
per-trigger. genius-scheduler records its own `fallback_model` per
`.genius/schedules.json` entry: `claude-opus-4-8` → `claude-sonnet-5` (matches
`configs/*/settings.json`). Never `haiku` for a code-role trigger — reserved for the
marketing chat in `server.js`.

**Remote triggers — trusted hosts + Trusted Devices.** Webhook receivers bind loopback
only (`127.0.0.1`, never `0.0.0.0`) and gate on sender identity before forwarding.
Remote Control only talks to `api.anthropic.com` — a custom `ANTHROPIC_BASE_URL`/gateway
disables it. **Trusted Devices** (Team/Enterprise, beta, off by default) ties Remote
Control to an enrolled device + a sign-in ≤18h old — recommend it for orgs letting
members steer scheduled loops remotely. Doesn't replace the push/deploy/publish
boundary: `decisions/GUARD-POLICY.md` §6 owns that enforcement, this section only
owns the trigger-level refusal.

*Sources (WebFetch-verified 2026-07-03): `code.claude.com/docs/en/{scheduled-tasks,
routines,channels-reference,remote-control,settings}`.*

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
3. Record the schedule in `.genius/schedules.json`: `slug`, `cron`, `method`, `budget`,
   `kill_switch`, `autonomy_level`, `blast_radius_ref`, `recur` (false relies on native
   `deleteAfterRun`), `dedup_key_field` (webhook/remote only), `destination` (fixed
   across runs), `fallback_model` (`claude-opus-4-8` → `claude-sonnet-5`, never haiku).
   See "Trigger safety" above.
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
- [ ] Scheduled/webhook/remote triggers: `autonomy_level`+`blast_radius` present, dedup
      key defined, one-shots use native `deleteAfterRun`, destination fixed,
      `fallback_model` fable/opus/sonnet only.
- [ ] Method selected; the scheduled command runs the loop THROUGH the kernel (brakes apply).
- [ ] Heartbeat + logging configured for the unsupervised run.
- [ ] Schedule written to `.genius/schedules.json`; activation AND kill commands given.
- [ ] Memory decision logged.
