# genius-orchestrator — Execution Details (progressive disclosure)

Loaded on demand from `SKILL.md`. Contains the full mechanics behind the loop state
kernel, task sync-back protocol, Task() syntax, resume procedure, backward
compatibility, and anti-patterns. `SKILL.md` keeps only the summary each of these
needs to route correctly; read this file before touching loop state, plan.md sync,
or Task() calls directly.

---

## Memory Integration

- **Session start**: Read `@.genius/memory/BRIEFING.md` for context + decisions + patterns
- **Before each task**: Check BRIEFING.md for relevant patterns or rejected approaches
- **On complete**: Append `{id, task, status, timestamp}` to `.genius/memory/progress.json`
- **On error**: Append `{id, error, solution, timestamp}` to `.genius/memory/errors.json`
- **On decision**: Append `{id, decision, reason, timestamp, tags}` to `.genius/memory/decisions.json`

---

## Playground Integration

Maintain `playgrounds/templates/progress-dashboard.html` as `.genius/outputs/PROGRESS.html`
backed by `.genius/state.json`. Sync task, agent, history, and stats data on every task
change, keep status markers aligned with plan markers, and emit a short sprint summary
every 5 tasks and at completion.

---

## Loop state (reuse the kernel — never a bespoke loop)

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

Use `Task({ description, prompt, subagent_type })` and always include BRIEFING context. Use
`genius-dev` for implementation, `genius-qa-micro` after every dev task, `genius-debugger` on
QA failures, and `genius-reviewer` periodically for quality scoring.

```javascript
Task(
  description: "short description",
  prompt: "detailed instructions",
  subagent_type: "genius-dev"
)
```

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

## On Resume

When resuming execution (after terminal close or `/continue`):
1. Read `.genius/memory/BRIEFING.md` for full context
2. Read `.claude/plan.md` for task status
3. Find first `[ ]` or `[~]` task
4. Continue execution loop from that point

---

## Backward Compatibility

For simple subagent use (non-Agent-Teams), `Task()` still works with the same syntax shown
in "Task Tool Syntax" above — no Agent Teams env var required.

---

## Completion Protocol

When all tasks are done, update `.genius/state.json` with final task totals, surface skipped
items, and point the user to the next sequence: full QA, security audit, then deploy. Always
mention `.genius/DASHBOARD.html`.

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
