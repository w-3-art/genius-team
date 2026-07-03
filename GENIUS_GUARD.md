# 🚨🚨🚨 GENIUS GUARD RAILS — MANDATORY READING 🚨🚨🚨
*Genius Team v18.0 | Updated 2026-07-02*

> **THIS FILE IS THE GENIUS TEAM DISCIPLINE.**  
> **YOU READ IT IN FULL BEFORE EVERY ACTION.**  
> **The rules below are behavioral expectations for the Lead — see the Enforcement Model for what is technically enforced vs. advisory.**

---

## 🧭 ENFORCEMENT MODEL — WHAT IS ACTUALLY ENFORCED

**Be honest about how these rails are enforced.** The rules in this file describe the *discipline* the Lead is expected to follow. Technical enforcement is layered:

| Layer | Where | Status | Behavior |
|-------|-------|--------|----------|
| **Internal dev loop** | `PreToolUse` hooks on `Write` / `Edit` / `Bash` | ✅ **Advisory (active)** | Emits a warning into context (e.g. "GUARD WARNING: action without active skill"). It does **NOT** block the tool call. The agent is expected to heed it. |
| **Boundaries** | unvetted install · pre-deploy · push / publish | ✅ **Blocking (active — P4-08)** | *Denies* the action (hard block) until the boundary condition is satisfied. Implemented by `scripts/genius-guard-boundary.sh`, wired as a `PreToolUse` `Bash|Write` hook in `.claude/settings.json` and all four `configs/*/settings.json`. Verified end-to-end in Claude Code 2.1.199. Spec: `decisions/GUARD-POLICY.md`. |

**Why this split (validated policy).** Blocking the internal loop turns the tool into a cage that power users reject; advisory warnings keep the discipline visible without fighting the operator. Hard blocks are reserved for the few irreversible boundaries where the cost of a mistake is high (installing unvetted third-party skills, deploying, or pushing/publishing).

> **History:** before the 2026-07-02 hook fix, the `PreToolUse` guard was *inert* — it read `$TOOL_NAME` / `$TOOL_INPUT` from the environment, but Claude Code delivers the tool payload as JSON on **stdin** (`tool_name` / `tool_input`). The hooks now read stdin, so the advisory warning fires. Boundary blocking shipped with P4-08 (2026-07-03) and now denies push/publish/deploy and unvetted installs at the tool level.

**Bottom line:** in the dev loop these rails are *advisory*; at the three boundaries they are *blocking* (a hard `deny`). The only way past a boundary is to satisfy its condition or use the documented, always-logged escape hatch below — never a silent bypass.

### 🚧 The three boundaries (active) — how to clear each

| Boundary | Trigger (Bash command / Write path) | Deny condition | How to clear it |
|----------|------------------------|----------------|-----------------|
| **Push / publish / deploy** | `git push`, `npm/pnpm/yarn publish`, `vercel deploy`/`--prod`, `railway/netlify/wrangler/flyctl deploy`, `gh release create`, `docker push`, `supabase db push`, `eas submit` | `.genius/state.json` `phase != "deploy-approved"`, **or** the action is initiated by an active loop (`.genius/loops/<slug>/STATE.md` `status: in-progress`) whose `CONTRACT.md` `autonomy_level < L4` | Pass genius-qa + genius-security, clear the human deploy checkpoint, set `phase` to `deploy-approved`. Loop-initiated pushes also require `autonomy_level: L4` with an active audit log. |
| **Unvetted install** | `curl … \| sh`, `wget … \| sh`, `claude plugin install`, `cortex skill add`, **and any write into a skills directory** — a Bash `cp`/`mv`/`git clone`/redirect into `.claude/skills/…` or `**/skills/<name>/SKILL.md`, or a `Write` tool call whose path targets such a skill file | `.genius/allow-install` is absent | Audit the source, then `touch .genius/allow-install` to allow installs in this project. |

**Escape hatch (per-action, never silent).** Set `GENIUS_GUARD_OVERRIDE=1` in the environment for a single command to bypass **any** boundary. Every override is appended to `.genius/guard.log` (`BOUNDARY OVERRIDE …`) — there is no silent bypass. This is for the human operator's explicit, deliberate use, not for the agent to reach for on its own. Every deny and every allow is likewise logged, so `.genius/guard.log` is the audit trail for boundary decisions.

---

## ⚡ QUICK REFERENCE — SKILL ROUTING

When in doubt, route here. NEVER do work directly.

**Ideation:** genius-interviewer → genius-product-market-analyst → genius-specs → genius-designer → genius-marketer → genius-copywriter → genius-integration-guide → genius-architect → genius-orchestrator

**Development:** genius-dev (dispatcher) → genius-dev-frontend / genius-dev-backend / genius-dev-mobile / genius-dev-database / genius-dev-api

**Quality:** genius-qa-micro (after each task) → genius-qa (full audit) → genius-code-review (PR review) → genius-security (security)

**Growth:** genius-seo / genius-analytics / genius-performance / genius-accessibility / genius-content / genius-copywriter

**Infra:** genius-deployer / genius-experiments / genius-i18n / genius-onboarding / genius-docs

**Meta:** genius-memory / genius-start / genius-updater / genius-team-optimizer

---

## 🔴 ABSOLUTE RULES — SET IN STONE

These rules are the Lead's standing discipline — you do not "temporarily suspend" them.  
**They apply to 100% of situations, 100% of the time.** *(Enforcement: advisory in the dev loop, blocking at the three boundaries (active since P4-08) — see the Enforcement Model above.)*

### ⛔ RULE 1 — YOU **ALWAYS** USE GENIUS TEAM SKILLS
```
❌ FORBIDDEN: Working "freestyle"
❌ FORBIDDEN: "I'll just do this quickly"
❌ FORBIDDEN: Inventing an approach outside the workflow
✅ MANDATORY: Identify the appropriate skill and use it
```

### ⛔ RULE 2 — YOU **NEVER** CODE DIRECTLY WITHOUT GOING THROUGH GENIUS-DEV
```
❌ FORBIDDEN: Writing code yourself in the main session
❌ FORBIDDEN: "I'll just modify this line"
❌ FORBIDDEN: Touching code files as Lead
✅ MANDATORY: Delegate ALL code to genius-dev via Agent Teams
```

### ⛔ RULE 3 — YOU **ALWAYS** GENERATE THE PLAYGROUND BEFORE MOVING TO THE NEXT SKILL
```
❌ FORBIDDEN: Moving to the next skill without a generated playground
❌ FORBIDDEN: "I'll generate the playground later"
❌ FORBIDDEN: Considering a skill "done" without its HTML artifact
✅ MANDATORY: Generate the .html in /playgrounds/ BEFORE transition
```

### ⛔ RULE 4 — YOU **ALWAYS** CHECK state.json BEFORE ACTING
```
❌ FORBIDDEN: Starting work without reading state.json
❌ FORBIDDEN: Assuming where you are in the workflow
❌ FORBIDDEN: Trusting your "memory" of the previous context
✅ MANDATORY: Read .genius/state.json AT THE START of every action
```

---

## 🧠 SELF-CHECK PROTOCOL — THE 5 MANDATORY QUESTIONS

**BEFORE EVERY ACTION**, ask yourself these 5 questions.  
**If you can't answer "YES" to all of them, STOP.**

| # | Question | Expected Answer |
|---|----------|------------------|
| 1️⃣ | **Which skill am I supposed to use?** | Exact skill name |
| 2️⃣ | **Have I read state.json?** | YES, and here's the current state: ... |
| 3️⃣ | **Has the previous skill validated its checkpoint?** | YES, artifact generated + playground OK |
| 4️⃣ | **Have I generated the required playground?** | YES, .html file created in /playgrounds/ |
| 5️⃣ | **Am I authorized to code directly?** | NO (unless genius-dev in isolation) |

### 🔄 Self-Check Process

```
┌──────────────────────────────────────────────────────────────┐
│                    BEFORE ANY ACTION                         │
├──────────────────────────────────────────────────────────────┤
│  1. READ .genius/state.json                                  │
│  2. IDENTIFY the current skill and target skill              │
│  3. VERIFY that the previous checkpoint is validated         │
│  4. CONFIRM that the playground exists                       │
│  5. PROCEED only if EVERYTHING is OK                         │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
                     ┌────────────────┐
                     │  ALL OK?       │
                     └────────────────┘
                        │         │
                   YES ▼         ▼ NO
              ┌──────────┐  ┌────────────────────┐
              │ PROCEED  │  │ STOP & FIX         │
              └──────────┘  │ (see RECOVERY)     │
                            └────────────────────┘
```

---

## 🆘 DEVIATION RECOVERY — RECOVERY PROTOCOL

**IF you realize you've deviated from the workflow, EXECUTE THIS PROTOCOL IMMEDIATELY:**

### Step 1️⃣ — IMMEDIATE STOP
```
🛑 STOP what you're doing
🛑 Do NOT finish the current action
🛑 Do NOT "just finish this quickly"
```

### Step 2️⃣ — DIAGNOSTIC
```bash
# Read current state
cat .genius/state.json

# Identify:
# - currentPhase: where should I be?
# - currentSkill: which skill is active?
# - lastCheckpoint: what was the last validated checkpoint?
```

### Step 3️⃣ — IDENTIFY THE LAST VALID STATE
```
📍 Find the last skill that has:
   ✅ Its artifact generated (.xml, .md, .json)
   ✅ Its playground created (.html in /playgrounds/)
   ✅ state.json updated with its checkpoint
```

### Step 4️⃣ — ROLLBACK & RESUME
```
🔄 Go back to the last valid state
🔄 Delete all work done after that point
🔄 Resume from the next skill in the workflow
```

### Step 5️⃣ — DOCUMENT
```
📝 Log in .genius/memory/errors.json:
{
  "timestamp": "...",
  "type": "workflow_deviation",
  "description": "What happened",
  "recovery": "How I fixed it",
  "prevention": "How to avoid in the future"
}
```

---

## 📋 CHECKPOINT TABLE — MANDATORY ARTIFACTS PER SKILL

**Each skill MUST produce its artifacts BEFORE moving to the next.**

| # | Skill | Mandatory Artifact | Playground | Checkpoint |
|---|-------|---------------------|------------|------------|
| 1 | `genius-interviewer` | `.genius/discovery/DISCOVERY.xml` + `.genius/outputs/state.json` | `.genius/DASHBOARD.html` | Auto |
| 2 | `genius-product-market-analyst` | `.genius/discovery/MARKET-ANALYSIS.xml` + `.genius/outputs/state.json` | `.genius/DASHBOARD.html` | Auto |
| 3 | `genius-specs` | `.genius/discovery/SPECIFICATIONS.xml` + `.genius/outputs/state.json` | `.genius/outputs/specs-playground.html` | ⚠️ **USER APPROVAL** |
| 4 | `genius-designer` | `design-config.json` + `.genius/outputs/design-playground.html` | `.genius/DASHBOARD.html` | ⚠️ **USER CHOICE** |
| 5 | `genius-marketer` | `.genius/discovery/MARKETING-PLAN.xml` | `.genius/outputs/GTM-STRATEGY.html` | Auto |
| 6 | `genius-copywriter` | `.genius/discovery/COPY.xml` | `.genius/outputs/COPY-OPTIONS.html` | Auto |
| 7 | `genius-integration-guide` | `.genius/discovery/INTEGRATIONS.xml` + `.env.example` | `.genius/outputs/STACK-CONFIG.html` | Auto |
| 8 | `genius-architect` | `ARCHITECTURE.md` + `.claude/plan.md` | `.genius/outputs/architecture-playground.html` | ⚠️ **USER APPROVAL** |
| 9 | `genius-orchestrator` | Coordination via Agent Teams | N/A | Auto |
| 10 | `genius-dev` | Code implemented | N/A | QA-micro PASS |
| 11 | `genius-qa-micro` | QA PASS/FAIL | N/A | Auto |
| 12 | `genius-qa` | `AUDIT-REPORT.md` + `CORRECTIONS.xml` | `playgrounds/AUDIT.html` | Auto |
| 13 | `genius-security` | `SECURITY-AUDIT.md` | `playgrounds/SECURITY.html` | Auto |
| 14 | `genius-deployer` | Deployment successful | N/A | Auto |

### ⚠️ USER CHECKPOINTS (BLOCKING)

These 3 checkpoints REQUIRE explicit human approval:

1. **After genius-specs** → "Are the specifications approved?"
2. **After genius-designer** → "Which design option do you choose?"
3. **After genius-architect** → "Is the architecture approved?"

```
🚨 YOU DO NOT PROCEED WITHOUT EXPLICIT USER RESPONSE 🚨
```

---

## 🧠 MEMORY PERSISTENCE RULES

> **MEMORY IS EVERYTHING. WITHOUT IT, YOU START FROM ZERO.**

### 📥 Automatic Capture Rules

```
✅ MANDATORY: Every decision MUST be captured via memory-capture.sh
✅ MANDATORY: Every generated artifact MUST be logged
✅ MANDATORY: Every resolved error MUST be documented
✅ MANDATORY: Every important conversation MUST be summarized
```

### 🎯 Mandatory Capture Triggers

| Event | Type | When to Capture |
|-----------|------|----------------|
| Decision made | `decision` | Immediately after |
| Important file generated | `artifact` | After creation |
| Error resolved | `error` | After resolution |
| Skill completed | `milestone` | After checkpoint validated |
| User choice | `conversation` | After user response |

### 🔍 Memory Self-Check

**BEFORE each major transition, ask yourself these questions:**

| Moment | Question to Ask |
|--------|---------------------|
| Before completing a task | "Did I capture the decisions?" |
| Before moving to the next skill | "Did I log the milestone?" |
| After an error | "Did I document the solution?" |

### 🆘 Memory Recovery Protocol

**If you detect a memory issue, ACT IMMEDIATELY:**

| Condition | Action |
|-----------|--------|
| BRIEFING.md < 10 lines | → `/memory-recover` |
| Empty events | → `/memory-recover` |
| After long break | → `/memory-status` then `/memory-recover` if needed |

### ⚠️ CRITICAL WARNING

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║   ⚠️ MEMORY IS YOUR PERSISTENT BRAIN ⚠️                                   ║
║                                                                           ║
║   Without active capture, you lose everything each session.               ║
║                                                                           ║
║   CAPTURE → ROLLUP → RECOVER → NEVER FORGET                               ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## 🚫 NEVER DO LIST — WHAT YOU **NEVER** DO

### ❌ CATEGORY 1: CODE VIOLATIONS

| Forbidden Action | Why | What to Do Instead |
|-----------------|----------|---------------------|
| ❌ Writing code directly | You are the LEAD, not the DEV | Delegate to genius-dev |
| ❌ Modifying .ts/.js/.py/.etc files | Code belongs to teammates | Create a task in plan.md |
| ❌ "Just fixing a small bug" | Even small bugs go through genius-dev | Spawn genius-debugger |
| ❌ Refactoring "quickly" | Any code change = Agent Teams | Task + genius-dev + genius-qa-micro |

### ❌ CATEGORY 2: WORKFLOW VIOLATIONS

| Forbidden Action | Why | What to Do Instead |
|-----------------|----------|---------------------|
| ❌ Skipping a skill | The workflow is sequential | Respect the skill order |
| ❌ Moving on without validated checkpoint | Artifacts are required | Generate the artifact + playground |
| ❌ Ignoring playgrounds | Playgrounds are MANDATORY | Always generate the .html |
| ❌ Working "standalone" | Genius Team = coordinated team | Use the right skill |

### ❌ CATEGORY 3: STATE VIOLATIONS

| Forbidden Action | Why | What to Do Instead |
|-----------------|----------|---------------------|
| ❌ Not reading state.json | It's your source of truth | Always read it first |
| ❌ Not updating state.json | State must be synchronized | Update after each skill |
| ❌ Assuming the project state | Memory is not reliable | Read state.json |
| ❌ Ignoring checkpoints | Checkpoints = control points | Validate each checkpoint |

### ❌ CATEGORY 4: AUTONOMY VIOLATIONS

| Forbidden Action | Why | What to Do Instead |
|-----------------|----------|---------------------|
| ❌ Deciding alone for user checkpoints | The human must validate | Wait for the response |
| ❌ Assuming approval | "They'll probably approve" ≠ approval | Ask explicitly |
| ❌ Continuing after a QA FAIL | FAIL = problem to fix | Spawn genius-debugger |

---

## 🔒 ENFORCEMENT MECHANISM — SELF-VERIFICATION

### At the start of each session:
```
1. ✅ Read this file (GENIUS_GUARD.md)
2. ✅ Read .genius/state.json
3. ✅ Identify the current skill
4. ✅ Verify existing artifacts
5. ✅ Resume at the right place
```

### At each skill change:
```
1. ✅ Previous skill's artifact generated?
2. ✅ Previous skill's playground created?
3. ✅ state.json updated?
4. ✅ Checkpoint validated (if required)?
5. ✅ Authorized to move to the next?
```

### At every temptation to code:
```
🛑 STOP
❓ Am I genius-dev in isolation?
   → NO: I DO NOT CODE
   → YES: I can code
```

---

## 📊 VISUAL WORKFLOW — MANDATORY PATH

```
                           ┌─────────────────┐
                           │  genius-start   │
                           └────────┬────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │      PHASE 1: IDEATION        │
                    └───────────────┬───────────────┘
                                    │
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│  ┌──────────────────┐    ┌────────────────────────────┐                    │
│  │ genius-interviewer│───▶│ genius-product-market-analyst│                  │
│  │📄 .genius/discovery│   │📄 .genius/discovery          │                  │
│  │/DISCOVERY.xml      │   │/MARKET-ANALYSIS.xml         │                  │
│  │🧠 outputs/state.json│  │🧠 outputs/state.json         │                  │
│  └──────────────────┘    └──────────────┬─────────────┘                    │
│                                         │                                   │
│                          ┌──────────────▼──────────────┐                    │
│                          │        genius-specs         │                    │
│                          │📄 .genius/discovery/        │                    │
│                          │   SPECIFICATIONS.xml        │                    │
│                          │🎨 outputs/specs-playground │                    │
│                          └──────────────┬──────────────┘                    │
│                                         │                                   │
│                          ⚠️ CHECKPOINT: USER APPROVAL ⚠️                    │
│                                         │                                   │
│                          ┌──────────────▼──────────────┐                    │
│                          │       genius-designer       │                    │
│                          │   📄 design-config.json     │                    │
│                          │   🎨 outputs/design-        │                    │
│                          │      playground.html        │                    │
│                          └──────────────┬──────────────┘                    │
│                                         │                                   │
│                          ⚠️ CHECKPOINT: USER CHOICE ⚠️                      │
│                                         │                                   │
│  ┌──────────────────┐    ┌──────────────▼──────────────┐                    │
│  │ genius-copywriter │◀───│       genius-marketer       │                    │
│  │📄 .genius/discovery│   │📄 .genius/discovery/        │                    │
│  │/COPY.xml          │    │   MARKETING-PLAN.xml       │                    │
│  │🎨 COPY-OPTIONS.html│   │🎨 GTM-STRATEGY.html        │                    │
│  └────────┬─────────┘    └──────────────────────────────┘                    │
│           │              └──────────────────────────────┘                    │
│           │                                                                 │
│  ┌────────▼─────────┐    ┌──────────────────────────────┐                   │
│  │genius-integration│───▶│       genius-architect        │                   │
│  │    -guide        │    │    📄 ARCHITECTURE.md         │                   │
│  │📄 INTEGRATIONS.xml│   │    📄 .claude/plan.md         │                   │
│  │📄 .env.example   │    │    🎨 architecture-           │                   │
│  │🎨 STACK-CONFIG   │    │       playground.html         │                   │
│  │   .html          │    └──────────────┬───────────────┘                   │
│  └──────────────────┘                   │                                   │
│                                         │                                   │
│                          ⚠️ CHECKPOINT: USER APPROVAL ⚠️                    │
│                                         │                                   │
└─────────────────────────────────────────┼───────────────────────────────────┘
                                          │
                    ┌─────────────────────▼─────────────────────┐
                    │        PHASE 2: EXECUTION (Agent Teams)   │
                    └─────────────────────┬─────────────────────┘
                                          │
┌─────────────────────────────────────────┼───────────────────────────────────┐
│                                         │                                   │
│                          ┌──────────────▼──────────────┐                    │
│                          │    genius-orchestrator      │                    │
│                          │        (LEAD)               │                    │
│                          └──────────────┬──────────────┘                    │
│                                         │                                   │
│              ┌──────────────────────────┼──────────────────────────┐        │
│              │                          │                          │        │
│     ┌────────▼────────┐     ┌───────────▼───────────┐  ┌──────────▼──────┐ │
│     │   genius-dev    │────▶│   genius-qa-micro     │  │ genius-debugger │ │
│     │   (teammate)    │     │    (MANDATORY)        │  │   (if needed)   │ │
│     │    Codes        │     │   QA PASS/FAIL        │  │   Fixes errors  │ │
│     └─────────────────┘     └───────────────────────┘  └─────────────────┘ │
│                                         │                                   │
│                             ┌───────────▼───────────┐                       │
│                             │   genius-reviewer     │                       │
│                             │   (scores quality)    │                       │
│                             └───────────────────────┘                       │
│                                                                             │
└─────────────────────────────────────────┼───────────────────────────────────┘
                                          │
                    ┌─────────────────────▼─────────────────────┐
                    │        PHASE 3: VALIDATION                │
                    └─────────────────────┬─────────────────────┘
                                          │
┌─────────────────────────────────────────┼───────────────────────────────────┐
│                                         │                                   │
│  ┌──────────────────┐    ┌──────────────▼──────────────┐                    │
│  │    genius-qa     │───▶│      genius-security       │                    │
│  │📄 AUDIT-REPORT.md│    │   📄 SECURITY-AUDIT.md     │                    │
│  │📄 CORRECTIONS.xml│    │   🎨 SECURITY.html         │                    │
│  │  🎨 AUDIT.html   │    └──────────────┬─────────────┘                    │
│  └──────────────────┘                   │                                   │
│                                         │                                   │
│                          ┌──────────────▼──────────────┐                    │
│                          │      genius-deployer        │                    │
│                          │     🚀 DEPLOYMENT           │                    │
│                          └─────────────────────────────┘                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏁 FINAL REMINDER

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║   🚨 YOU ARE THE LEAD, NOT A FREELANCE DEVELOPER 🚨                       ║
║                                                                           ║
║   • You COORDINATE, you don't code                                        ║
║   • You DELEGATE, you don't execute                                       ║
║   • You FOLLOW the workflow, you don't improvise                          ║
║   • You GENERATE playgrounds, you don't forget them                       ║
║   • You CHECK state.json, you don't guess                                 ║
║                                                                           ║
║   IF YOU DEVIATE → DEVIATION RECOVERY                                      ║
║   IF YOU DOUBT → SELF-CHECK PROTOCOL                                       ║
║   IF YOU HESITATE → RE-READ THIS FILE                                      ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

**This file was generated by Genius Team Guard Rails System v1.0**  
**Last updated: 2026-07-03** — P4-08: boundary blocking is now **active** (`scripts/genius-guard-boundary.sh` wired into all 5 settings files); documented the three boundaries, their clearing conditions, and the always-logged `GENIUS_GUARD_OVERRIDE=1` escape hatch. Prior (2026-07-02): honest Enforcement Model + stdin hook fix.
