---
name: genius-dual-engine
description: >-
  Builder + Challenger adversarial workflow. One engine builds, another challenges with a critical review.
  Use when user says "dual review", "challenge mode", "builder challenger", "adversarial review",
  or when task is marked with 🔄. Requires --engine=dual or --engine=codex.
  Do NOT use for single-engine code review (use genius-reviewer or genius-code-review).
  Do NOT use for standard QA (use genius-qa or genius-qa-micro).
context: fork
user-invocable: true
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Glob(*)
  - Grep(*)
  - Bash(*)
  - Task(*)
  - WebFetch(*)
  - WebSearch(*)
hooks:
  Stop:
    - type: command
      command: "bash -c 'if [ -f .genius/dual-state.json ]; then jq --arg now \"$(date -Iseconds 2>/dev/null || date)\" \".updated_at = \\\"$now\\\"\" .genius/dual-state.json > .genius/dual-state.json.tmp && mv .genius/dual-state.json.tmp .genius/dual-state.json; fi 2>/dev/null || true'"
      once: true
---

# Genius Dual Engine v17.0 — Builder + Challenger

**Two minds are better than one. Especially when one is trying to break your code.**

## True Simultaneous Dual — Bridge Architecture

**Two terminals. One project. Real-time cross-challenges.**

### Setup

1. Open Terminal 1: `claude` (Claude Code)
2. Open Terminal 2: `codex` (Codex CLI)
3. Both read/write `.genius/dual-bridge.json` automatically

### The Bridge

`.genius/dual-bridge.json` records each engine's last action:
- What task was done
- Which files were modified
- The actual diff (what changed)
- Timestamp

Updated automatically by the `Stop` hook after every dev action.

### /challenge — Cross-Engine Review

In either terminal, type `/challenge` to:
1. Read what the OTHER engine just did (from the bridge)
2. Get the diff automatically
3. Run genius-code-review on those changes
4. Receive: CRITICAL / HIGH / MEDIUM / LOW findings

**No context needed.** The bridge handles it.

### Hook Integration

The `Stop` hook in both engines calls `scripts/update-dual-bridge.sh` automatically:

```bash
# In Claude Code Stop hook:
bash scripts/update-dual-bridge.sh claude "$TASK_DESCRIPTION"

# In Codex Stop hook (AGENTS.md):
bash scripts/update-dual-bridge.sh codex "$TASK_DESCRIPTION"
```

---

## Overview

The Dual Engine coordinates two AI models in complementary roles:
- **Builder** — Plans, architects, and implements (default: Claude Opus)
- **Challenger** — Reviews, tests, audits, and challenges (default: Codex CLI)

The engine is **opt-in per task**. Not every task needs adversarial review — use it for critical features, security-sensitive code, or when you want high confidence.

---

## State Management

### Initialize Dual State
On first use, create `.genius/dual-state.json`:
```json
{
  "active": false,
  "mode": null,
  "cycle": 0,
  "max_rounds": 3,
  "builder_model": "opus",
  "challenger_model": "codex",
  "challenger_profile": "balanced",
  "current_task": null,
  "last_verdict": null,
  "history": [],
  "updated_at": "ISO-date"
}
```

### Update State
After every cycle iteration, update `.genius/dual-state.json` with:
- Incremented `cycle` count
- `last_verdict`: `"APPROVE"`, `"REQUEST_CHANGES"`, or `"REJECT"`
- Append to `history[]` with cycle details

---

## Mode 1: Build-Review Cycle

The primary workflow. Builder implements, Challenger reviews.

### Protocol

```
┌─────────────┐     implement     ┌─────────────┐
│   BUILDER   │ ───────────────→  │  Code/Files  │
└─────────────┘                   └──────┬───────┘
                                         │
                                         ▼
                                  ┌─────────────┐
                                  │ CHALLENGER   │
                                  │  (review)    │
                                  └──────┬───────┘
                                         │
                              ┌──────────┼──────────┐
                              ▼          ▼          ▼
                         APPROVE   REQUEST_CHANGES  REJECT
                           │          │              │
                           ▼          ▼              ▼
                         Done    Builder fixes   Escalate
                                  (cycle++)      to user
```

### Step-by-Step

1. **Activate**: Set `dual-state.json` → `active: true, mode: "build-review", cycle: 0`
2. **Builder Phase**: Builder receives the task and implements it normally using genius-dev patterns
3. **Handoff**: Builder signals completion. Write implementation summary to `.genius/dual-review-request.md`:
   ```markdown
   # Dual Review Request
   ## Task: [description]
   ## Files Changed: [list]
   ## Approach: [summary]
   ## Tests: [pass/fail status]
   ```
4. **Challenger Phase**: Spawn Challenger agent (`genius-challenger`) with:
   - Read-only access to all project files
   - The review request document
   - The challenger profile configuration
5. **Verdict**: Challenger writes `.genius/dual-verdict.md`:
   ```markdown
   # Challenger Verdict — Cycle N
   ## Verdict: APPROVE | REQUEST_CHANGES | REJECT
   ## Score: XX/100
   ## Findings:
   ### Critical (must fix)
   ### Important (should fix)
   ### Minor (could fix)
   ## Rationale: [explanation]
   ```
6. **Resolution**:
   - **APPROVE** → Task complete. Log to history. Set `active: false`.
   - **REQUEST_CHANGES** → Builder receives findings, fixes issues. Increment `cycle`. If `cycle >= DUAL_MAX_ROUNDS` → escalate to user.
   - **REJECT** → Escalate to user immediately with Challenger's rationale.

### Spawning the Challenger

Use Agent Teams task delegation:
```
Task the genius-challenger agent: Review the implementation described in .genius/dual-review-request.md.
Apply the {DUAL_CHALLENGER_PROFILE} profile. Write verdict to .genius/dual-verdict.md.
```

If the configured challenger model CLI is available (codex, kimi, gemini), use it:
```bash
# Example with Codex CLI
codex --approval-mode full-auto "Review the code changes in .genius/dual-review-request.md. Write your verdict to .genius/dual-verdict.md following the format in ${CLAUDE_SKILL_DIR}/genius-dual-engine/SKILL.md"
```

If no external CLI is available, fall back to spawning a Claude Code Task with the genius-challenger agent prompt.

---

## Mode 2: Discussion Mode

When Builder and Challenger disagree on **approach** (not just implementation details).

### Protocol

```
┌─────────────┐  Approach A   ┌─────────────┐  Approach B
│   BUILDER   │ ───────────→  │ CHALLENGER   │ ───────────→  Compare
└─────────────┘               └─────────────┘
       │                             │
       ▼                             ▼
   Rebuttal ◄─── Round 2 ───► Rebuttal
       │                             │
       ▼                             ▼
   Converge? ─── No (Round 3) ──→ User Decides
       │
      Yes → Proceed with agreed approach
```

### Step-by-Step

1. **Activate**: Set `mode: "discussion"` in dual-state
2. **Builder Proposes**: Write approach A to `.genius/dual-discussion.md`:
   ```markdown
   ## Builder — Approach A
   ### Proposal: [description]
   ### Rationale: [why this approach]
   ### Trade-offs: [pros/cons]
   ```
3. **Challenger Counter-Proposes**: Challenger appends approach B
4. **Debate**: Max 3 rounds. Each round, both sides respond to the other's points
5. **Resolution**:
   - If convergence → proceed with agreed approach
   - If no convergence after 3 rounds → present both approaches to user with pros/cons summary

---

## Mode 3: Audit Mode

Challenger performs independent audit: tests (genius-qa), security/OWASP (genius-security), performance (genius-performance), spec compliance (genius-reviewer).
Output to `.genius/dual-audit-report.md` with Summary, Critical/Important/Minor Findings, Recommendations, and Verdict (PASS/CONDITIONAL_PASS/FAIL).

---

## Challenger Profiles

Set via `DUAL_CHALLENGER_PROFILE` env var or per-task override:
- **strict** (90+ to approve): full audit, every decision challenged. For production/security-critical.
- **balanced** (70+, default): standard code review. For regular development.
- **lenient** (50+): bugs/breaking changes only, tests only. For prototyping/internal tools.

---

## Integration with Agent Teams

Team: Lead Agent (Builder) + genius-dev + genius-architect + genius-challenger (read-only reviewer).
Communication is file-based: `.genius/dual-review-request.md`, `.genius/dual-verdict.md`, `.genius/dual-discussion.md`, `.genius/dual-audit-report.md`, `.genius/dual-state.json`.
In plan.md, prefix dual tasks with `🔄` and `(DUAL: mode, profile)` to signal the orchestrator.

---

## Relationship to Existing Skills

Challenger reuses reviewer's scoring rubric (iteratively, not single-pass), invokes QA/security checks during audit, and never implements (that's genius-dev's job).

## Cost & Performance Notes

- **Token usage**: ~2x baseline (two models reasoning over the same code)
- **Time**: Each cycle adds a review round. Expect 1.5-3x wall-clock time.
- **When to use**: Critical features, security-sensitive code, complex algorithms, pre-release audits
- **When NOT to use**: Simple refactors, typo fixes, documentation updates, prototypes (use `lenient` profile or skip dual entirely)

---

## Quick Start

1. Mark a task with `🔄` in plan.md, or say "dual review this"
2. Builder implements normally
3. Engine automatically triggers Challenger review
4. Iterate until APPROVE or escalation
5. Check status anytime with `/dual-status`
6. Force a review with `/dual-challenge`

---

## Switching to/from Dual Mode

To switch an existing project to dual mode:
```
/genius-switch-engine dual
```

To go back to Claude Code only:
```
/genius-switch-engine claude
```

To switch to Codex only:
```
/genius-switch-engine codex
```

This preserves all your project data (.genius/) and only reconfigures the engine files.

## Definition of Done

- [ ] Builder and Challenger roles are both exercised for the marked task
- [ ] Challenger feedback is concrete and either resolved or escalated
- [ ] Final status is one of `APPROVE`, `REVISE`, or `ESCALATE`
- [ ] Dual-mode status files reflect the latest outcome
- [ ] User can see the remaining next step without rereading the thread
