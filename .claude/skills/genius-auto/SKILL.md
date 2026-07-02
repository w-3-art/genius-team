---
name: genius-auto
description: >-
  Configures and tunes Auto Mode settings within the current mode (CLI/IDE/Omni/Dual).
  Auto Mode is built into all modes by default — this skill adjusts safety profiles
  per project needs. Use when user says "tune auto mode", "make it more permissive",
  "tighten permissions", "configure auto approve", "safety settings", "I want less prompts".
  Do NOT use for CI/CD pipelines (use genius-ci).
  Do NOT use for scheduled tasks (use genius-scheduler).
context: fork
agent: genius-auto
user-invocable: true
allowed-tools:
  - Read(*)
  - Glob(*)
  - Grep(*)
  - Write(*)
  - Edit(*)
  - Bash(jq *)
  - Bash(cat *)
---

# Genius Auto v22.0 — Auto Mode Tuning

**Tunes Auto Mode safety profiles within your current mode. Auto Mode is ON by default in all modes — this skill adjusts how aggressive it is.**

Auto Mode is NOT a separate mode. It's a layer inside CLI/IDE/Omni/Dual that auto-approves safe actions.

## How It Works

Auto Mode is already active via `CLAUDE_CODE_AUTO_MODE=skill-aware` in all mode configs. This skill helps you:
1. Check your current auto mode profile
2. Switch between safety profiles (permissive/standard/restrictive)
3. Add custom allow/deny rules per project

## Memory Integration

### On Start
Read `@.genius/memory/BRIEFING.md` for project context and current mode.

### On Configuration Complete
Append to `.genius/memory/decisions.json`:
```json
{"id": "d-XXX", "decision": "AUTO-MODE: tuned to [profile] for [reason]", "timestamp": "ISO-date"}
```

---

## Safety Profiles

### Permissive
Best for: content projects, prototyping, solo dev
Auto-approves: file read/write, lint, test, git add/commit, npm install
Requires approval: git push, deploy, production DB, env vars

### Standard (default)
Best for: team projects, active development
Auto-approves: file read/write, lint, test, npm install
Requires approval: git operations, deploy, CI config, DB migrations

### Restrictive
Best for: production, infrastructure, security-sensitive
Auto-approves: file reads, dry-run commands, .genius/ outputs
Requires approval: ALL writes, git, deploy, build, secrets

## Tuning Commands

To change profile, update the mode config:
```bash
# In settings.json for your mode:
"env": { "CLAUDE_CODE_AUTO_MODE": "permissive" | "standard" | "skill-aware" | "restrictive" }
```

Or use conditional hooks (Claude Code 2.1.85+):
```json
{
  "hooks": {
    "PreToolUse": [{
      "type": "command",
      "if": "Bash(git push*)",
      "command": "echo 'CONFIRM: pushing to remote'"
    }]
  }
}
```

---

## Autonomy Ladder (L1 → L4)

**Orthogonal to the Safety Profiles above.** Safety Profiles govern tool-approval prompts for
the *current interactive session*. The Autonomy Ladder governs what an **unattended loop**
(`genius-loop`, LP-02) is permitted to do across runs, declared as `autonomy_level` in the
loop's `CONTRACT.md` (written by `genius-goal-contract`, LP-01). This section is the **canonical
definition** — every other reference to L1-L4 in this repo (`TOOLS.md`, the `CONTRACT.md`
template, `genius-loop`, `genius-autoresearch`, `genius-experiments`, `genius-scheduler`) must
match it.

| Level | Name | What EXECUTE may do | Merge / deploy |
|---|---|---|---|
| **L1** | suggest-only | Analysis only. Writes findings/proposals under `proposals/`, applies nothing. | N/A |
| **L2** | draft | Writes draft diffs/files under `proposals/`, applies nothing. **Default for every new loop.** | N/A |
| **L3** | apply-low-risk-with-merge-approval | May apply changes inside the declared blast radius. | Requires explicit human approval at merge (human-read gate) — never auto-merges. |
| **L4** | full-auto-with-audit-logs | May apply changes and merge/deploy without a per-run blocking prompt. | Still gated: the human-read gate is present as an audit checkpoint, not a blocking prompt — see rules below. |

### Rules (non-negotiable)

1. **Every new loop starts at L1 or L2.** `genius-goal-contract` refuses to write a `CONTRACT.md`
   with `autonomy_level: L3` or `L4` for a loop that has never run.
2. **Promotion to L3 requires a track record**: at least one week of L1/L2 outputs that a human
   has actually read and approved — not just "no complaints." No shortcut.
3. **L4 requires BOTH, simultaneously, or it does not apply:**
   - an **active audit log** — every EXECUTE/VERIFY/merge decision recorded and reviewable after
     the fact (the Cortex control plane, LP-06, is the target home for this; until it exists,
     `STATE.md` + `loop_report` stand in, but must actually be read, not just written);
   - a **human-read gate at merge that is never bypassable.** L4 removes the blocking *prompt*;
     it never removes the *review*. If nobody is reading the audit log, the loop is not really L4.
4. **"Level four is earned, not assumed."** No contract, tuning profile, or hook may set
   `autonomy_level: L4` as a default or a starting point. It is the end of a promotion path,
   never a shortcut typed in for convenience.
5. **Guards enforce this at the boundary.** Push/deploy/publish hooks (P4-08, see
   `decisions/GUARD-POLICY.md`) must refuse a push/deploy initiated by a loop whose
   `autonomy_level` is below L4 without an explicit human approval on that specific run — and
   even at L4 the audit log must show the human-read gate was satisfied, not skipped.

### Cross-references (keep in sync)
- `genius-goal-contract` SKILL.md — writes `autonomy_level` into `CONTRACT.md`.
- `genius-loop` SKILL.md — reads `autonomy_level` to decide what EXECUTE may do.
- `TOOLS.md` § Loop Engineering — one-line summary of the ladder.
- `decisions/GUARD-POLICY.md` — boundary hooks that check autonomy level at push/deploy time.

## Definition of Done
- [ ] Current auto mode profile identified
- [ ] Profile adjusted per user preference
- [ ] Settings written to mode config
- [ ] User informed of what's auto-approved vs gated

## Handoff
After tuning: return to current task. No further action needed.
