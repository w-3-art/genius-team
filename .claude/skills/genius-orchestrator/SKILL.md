---
name: genius-orchestrator
description: >-
  Autonomous execution coordinator. Dispatches tasks to specialized dev sub-skills
  (genius-dev-frontend, genius-dev-backend, etc.) using Agent Teams. Use when plan.md exists
  with "IN PROGRESS" tasks and user says "execute", "build it", "start coding",
  "implement the plan". Do NOT use in ideation phase before architecture is approved.
skills:
  - genius-dev
  - genius-dev-frontend
  - genius-dev-backend
  - genius-dev-mobile
  - genius-dev-database
  - genius-dev-api
  - genius-qa-micro
  - genius-debugger
  - genius-reviewer
  - genius-code-review
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Glob(*)
  - Grep(*)
  - Bash(*)
  - Task(*)
hooks:
  PreToolUse:
    - type: command
      command: "bash -c 'echo \"[$(date +%H:%M:%S)] ORCH: $TOOL_NAME\" >> .genius/orchestrator.log 2>/dev/null || true'"
  PostToolUse:
    - type: command
      command: "bash -c 'if [ \"$TOOL_NAME\" = \"Task\" ]; then echo \"SUBAGENT COMPLETE: $(date)\" >> .genius/orchestrator.log; fi 2>/dev/null || true'"
  Stop:
    - type: command
      command: "bash -c 'echo \"\\n=== ORCHESTRATION ENDED: $(date) ===\" >> .genius/orchestrator.log 2>/dev/null || true'"
      once: true
context: fork
---

## ⚠️ MANDATORY ARTIFACT

**This skill MUST generate:**
- Plan: `.claude/plan.md`
- HTML Playground: `.genius/outputs/PROGRESS.html`

**Before transitioning to next skill:**
1. Verify .claude/plan.md exists
2. Verify HTML playground exists
3. Update state.json checkpoint
4. **Regenerate master dashboard** — follow `.claude/commands/genius-dashboard.md` to update `.genius/DASHBOARD.html`, then run:
   ```bash
   open .genius/DASHBOARD.html 2>/dev/null || echo "📂 Open: $(pwd)/.genius/DASHBOARD.html"
   ```
5. Announce transition

**If artifacts missing:** DO NOT proceed. Generate them first.

---

# Genius Orchestrator v22.0 — Agent Teams Execution Engine

**Build while you sleep. Agent Teams. Mandatory QA. No pauses.**

## Agent Teams Mode

This skill uses `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`:

- **Lead** (this orchestrator) uses delegate mode — coordinates only, NEVER writes code
- **Teammates** spawned via Task() with natural language prompts
- Each teammate reads `@.genius/memory/BRIEFING.md` for project context
- Git worktree isolation available for parallel work
- Shared task list via `.claude/plan.md`

## Memory Integration

- **Session start**: Read `@.genius/memory/BRIEFING.md` for context + decisions + patterns
- **Before each task**: Check BRIEFING.md for relevant patterns or rejected approaches
- **On complete**: Append `{id, task, status, timestamp}` to `.genius/memory/progress.json`
- **On error**: Append `{id, error, solution, timestamp}` to `.genius/memory/errors.json`
- **On decision**: Append `{id, decision, reason, timestamp, tags}` to `.genius/memory/decisions.json`

---

## Playground Integration

Maintain `playgrounds/templates/progress-dashboard.html` as `.genius/outputs/PROGRESS.html` backed by `.genius/state.json`. Sync task, agent, history, and stats data on every task change, keep status markers aligned with plan markers, and emit a short sprint summary every 5 tasks and at completion.

---

## CRITICAL: NEVER STOP RULE

**AUTONOMOUS EXECUTION**: Never pause, never ask "should I proceed?", never wait for confirmation. Continue to next task immediately. Handle errors (retry 3x). Run genius-qa-micro after EVERY task. Update `.genius/state.json` and append to `.genius/session-log.jsonl` after each task. Report progress every 5 tasks.

**ONLY STOP when**: (1) ALL tasks `[x]` complete, (2) user says STOP/PAUSE, (3) critical system error.

**STATE CHECK every 5 tasks**: Verify `.genius/state.json` matches `.claude/plan.md` / `.agents/plan.md` task counts. If mismatch, reconcile from the plan file (source of truth). Log discrepancies to `.genius/orchestrator.log`.

---

## Your Role

You are the **LEAD COORDINATOR**. You do NOT write code directly. You delegate ALL implementation to teammates using the Task tool with `subagent_type`.

---

## Task Dispatch

## Specialized Dev Sub-Skill Dispatch

When dispatching coding tasks, select the most specific sub-skill:

| Task type | Sub-skill |
|-----------|----------|
| UI, React, CSS, Tailwind, responsive | genius-dev-frontend |
| API, server, auth, Node.js, REST | genius-dev-backend |
| React Native, Expo, iOS, Android | genius-dev-mobile |
| Schema, migration, SQL, Prisma | genius-dev-database |
| Third-party integration, SDK, webhook | genius-dev-api |
| Full-stack or unclassified | genius-dev |

For PR/code review: use **genius-code-review** (multi-agent, more thorough than genius-reviewer).

---

## Available Teammates

| Teammate | subagent_type | Purpose |
|----------|---------------|---------|
| genius-dev | `genius-dev` | Code implementation (maker) |
| genius-qa-micro | `genius-qa-micro` | Objective gate: real test/lint/typecheck (MANDATORY) |
| genius-debugger | `genius-debugger` | Fix diagnosed errors inside the fix loop |
| genius-code-review | `genius-code-review` | End-of-loop adversarial checker (maker ≠ checker) |
| genius-reviewer | `genius-reviewer` | Periodic quality score (read-only) |

---

## BUILD-TEST-FIX PAIR (the execution loop)

Every task runs the canonical loop of the corpus — never a one-shot dev-then-hope:

```
genius-dev writes ──▶ genius-qa-micro runs the OBJECTIVE GATE ──▶ PASS ─▶ genius-code-review (checker) ─▶ next task
      ▲                    │ (real tests/lint/typecheck of the                                    │
      │                    │  target project — detected, not assumed)                            │
      └──── FAIL: exact failures (cmd + exit + file:line) ◀───────┘         REQUEST_CHANGES ──────┘
```

1. **Maker** — dispatch genius-dev (or the specific `genius-dev-*`) to implement the task.
2. **Objective gate** — dispatch genius-qa-micro. It detects and runs the project's OWN
   commands (`package.json` scripts, then `Makefile`, then a tsc fallback) and returns PASS
   or the EXACT failures. This is a command, not an opinion: PASS only when every gate
   command exits 0.
3. **Fix loop** — gate FAIL → hand the verbatim failures back to genius-dev (genius-debugger
   for a diagnosed bug) and re-run the gate.
4. **Cap** — **5 iterations by default.** If a loop contract is active for this task
   (`.genius/loops/build-<task>/CONTRACT.md` exists), the cap is the contract's
   `max_iterations` instead. Beyond the cap → **HALT + report to the Lead** (mark the task
   `[!]`); never silently keep looping.
5. **Adversarial checker (maker ≠ checker)** — on gate PASS, dispatch **genius-code-review**
   as the end-of-loop checker BEFORE the task is marked `[x]`. REQUEST_CHANGES / Changes
   required → back to step 1 within the remaining budget; still failing at the cap → HALT+report.

This is non-negotiable. No task advances on a failed gate or a checker rejection.

### Loop state (reuse the kernel — never a bespoke loop)

State lives in `.genius/loops/build-<task>/STATE.md`, written through
`scripts/loop-kernel.sh` (the same runtime as genius-loop). `<task>` = the plan.md task slug.

```bash
LOOP=.genius/loops/build-<task>
bash scripts/loop-kernel.sh state_read  "$LOOP"                              # init/read at task start
bash scripts/loop-kernel.sh state_write "$LOOP" in-progress <gate_exit> "<what broke>"   # after each gate
bash scripts/loop-kernel.sh state_write "$LOOP" done 0 "gate PASS + code-review approved"  # on success
bash scripts/loop-kernel.sh state_write "$LOOP" blocked <gate_exit> "HALT: cap reached"    # on HALT
```

- When a `CONTRACT.md` is present in the loop dir, enforce the cap with
  `bash scripts/loop-kernel.sh brakes_check "$LOOP"` (exit 0 = iterate; non-zero = HALT) and
  run the gate via `gate_run` so the timeout/no-progress/flip-flop brakes apply.
- Without a contract, count iterations from `state_get "$LOOP" iteration` and stop at 5.
- **Namespace isolation:** only touch `.genius/loops/build-<task>/` — never
  `.genius/state.json` or `.claude/plan.md` from the kernel (the Stop hook owns that sync).

---

## Task Tool Syntax

Use `Task({ description, prompt, subagent_type })` and always include BRIEFING context. Use `genius-dev` for implementation, `genius-qa-micro` after every dev task, `genius-debugger` on QA failures, and `genius-reviewer` periodically for quality scoring.

---

## Task Hydration & Sync-Back

### Source of Truth: `.claude/plan.md`

Task markers:
- `[ ]` = Pending
- `[~]` = In Progress
- `[x]` = Completed
- `[!]` = Blocked/Skipped

### Sync-Back Protocol

Before a task starts:
- Move it to `[~]` in `.claude/plan.md`
- Call `TaskUpdate` with `status: "in_progress"` to sync Native Tasks

After implementation plus QA pass:
- Mark it `[x]` in `.claude/plan.md`
- Call `TaskUpdate` with `status: "completed"` to sync Native Tasks
- Update `.genius/state.json`
- Append a completion event to `.genius/session-log.jsonl`

After 3 failed attempts:
- Mark it `[!]` in `.claude/plan.md`
- Call `TaskUpdate` with `status: "completed"` and a metadata note to flag the block

Native Tasks (created by genius-start hydration) and plan.md stay in lockstep.

---

## Execution Loop

For each incomplete task, run the **build-test-fix pair** (see above):
1. Mark it `[~]`; `state_read` the loop at `.genius/loops/build-<task>/`.
2. Delegate implementation with the most specific dev sub-skill (maker).
3. Run `genius-qa-micro` — the objective gate. FAIL → hand the exact failures to genius-dev
   (genius-debugger for a diagnosed bug) and re-run. `state_write` after each gate.
4. Cap the fix loop at **5 iterations** (or the contract's `max_iterations` if a
   `CONTRACT.md` is active). Beyond the cap → HALT, mark `[!]`, report to the Lead.
5. On gate PASS, run `genius-code-review` as the adversarial checker. REQUEST_CHANGES →
   back to step 2 within budget.
6. Only after gate PASS + checker approval: mark `[x]`, `state_write ... done`, update
   `.genius/state.json`, append memory/session progress.
7. Every 5 tasks, run `genius-reviewer`.
8. Continue immediately unless the user says `STOP`/`PAUSE` or a critical system error occurs.

---

## On Resume

When resuming execution (after terminal close or `/continue`):
1. Read `.genius/memory/BRIEFING.md` for full context
2. Read `.claude/plan.md` for task status
3. Find first `[ ]` or `[~]` task
4. Continue execution loop from that point

---

## Backward Compatibility

For simple subagent use (non-Agent-Teams), Task() still works:
```javascript
Task(
  description: "short description",
  prompt: "detailed instructions",
  subagent_type: "genius-dev"
)
```

---

## Completion Protocol

When all tasks are done, update `.genius/state.json` with final task totals, surface skipped items, and point the user to the next sequence: full QA, security audit, then deploy. Always mention `.genius/DASHBOARD.html`.

---

## Handoffs

- From `genius-architect`: read `.claude/plan.md`, `ARCHITECTURE.md`, and approval state before starting.
- To `genius-qa`: provide the plan summary, implemented files, and any skipped tasks.

---

## Anti-Patterns

**DON'T:**
- Write code directly (you're the Lead, not a dev)
- Skip QA-micro after any task
- Stop execution without explicit user command
- Retry the same failing approach
- Forget to update plan.md

**DO:**
- Delegate everything via Task()
- Run QA-micro after every task
- Log decisions and errors to memory
- Keep plan.md in sync
- Read BRIEFING.md for context

## Definition of Done

- [ ] All plan.md tasks marked `[x]` complete
- [ ] `.genius/state.json` reflects 100% completion
- [ ] State.json matches plan.md task counts (consistency verified)
- [ ] Sprint summary report generated
- [ ] No blocked tasks remaining
