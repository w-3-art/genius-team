# Autoresearch Journal — Genius Team v18-candidate
*Started: 2026-03-13 00:00 CET*

## Session Summary

**Model:** Claude Sonnet 4.6 (primary) + Codex/GPT-5.4 (Track 3)
**Branch:** v18-candidate
**Total commits so far:** 15

---

## Experiments Log

### Round 1 — Baseline Establishment

**exp/durability-001** (commit `869871e`)
- Finding: `postCompactionSections` had 4 headers that didn't match CLAUDE.md sections
- `## Genius Team` → didn't exist (was just `# Genius Team v17.0`)
- `## Memory` → actual header was `## 🧠 Memory` (emoji + spacing mismatch)
- `## Anti-Drift Rules` → actual was `## 🚨 ANTI-DRIFT RULES` (emoji + case)
- `## Current Phase` → didn't exist at all
- Fix: Added `## Genius Team Core Rules` section to CLAUDE.md + updated settings.json to match
- Impact: **CRITICAL** — postCompactionSections were completely non-functional

**exp/routing-001** (commit `cfd4dfd`)
- Finding: Many skills missing negative triggers (confusion between similar skills)
- Key confusion pairs fixed: genius-reviewer vs genius-code-review, genius-qa vs genius-qa-micro
- Also fixed: genius-deployer (no negative triggers), genius-start (no negative triggers)
- genius-dev dispatcher: clarified it routes to sub-skills for known domains
- Impact: Medium — reduces ambiguous routing

**exp/routing-002** (commit `189d595`)
- Finding: Zero disambiguation instructions in genius-team router
- When user says something ambiguous, Claude just guessed (usually wrong)
- Fix: Added `## Disambiguation Rules` with explicit tiebreak rules + ambiguous examples
- Impact: Medium-High — reduces routing failures on ambiguous requests

**exp/playground-001** (commit `dbb7d5c`)
- Finding: 24 of 42 skills had ZERO playground mentions
- Most v17 skills completely unaware they should update the dashboard
- Fix: Added `## Playground Update (MANDATORY)` section to 13 v17 skills
- Impact: High — playgrounds were systematically not updated after v17 skills ran

**exp/orchestration-001** (commit `0e83de3`)
- Finding: No automatic chain between ideation skills
- After genius-interviewer completes, it just... stopped. Claude had to guess what came next.
- Fix: Added `## Next Step` section to all 8 ideation skills with explicit auto-chain
- Impact: High — chain completion rate should dramatically improve

### Round 2 — Config & CLAUDE.md Updates

**exp/durability-002** (commit `b05dcdb`)
- Finding: 4 config CLAUDE.md files (cli/ide/omni/dual) had NO Anti-Drift rules
- Root cause: Root CLAUDE.md updated, but setup.sh installs from configs/*/CLAUDE.md
- Fix: Added `## 🚨 ANTI-DRIFT RULES` + `## Genius Team Core Rules` to all 4 configs
- Impact: **CRITICAL** — users installing from configs got zero anti-drift protection

**exp/durability-003** (commit `a3b3b16`)
- Finding: PostCompact hook was missing entirely
- After compaction, no guardrails reminder was fired
- Fix: Added PostCompact hook to all 4 configs — echoes anti-drift reminder + GENIUS_GUARD note
- Impact: High — should reduce post-compaction drift significantly

### Round 3 — Skill Output Quality

**exp/quality-001** (commit `641e0d1`)
- Added "Definition of Done" to 8 skills: frontend, backend, database, api, seo, analytics, performance, accessibility
- Dev skills now verify build/lint/tests before declaring done
- Analysis skills now require specific references (not generic advice)
- Impact: High — tasks will no longer be marked complete without verification

**exp/quality-002** (commit `add0820`)
- Output quality requirements for: code-review, docs, copywriter, content
- code-review: must include file:line, severity, category, fix code for every issue
- copywriter: no placeholders, specific benefits, clear CTAs
- docs: Divio-structured, tested examples
- content: complete draft with word count
- Impact: Medium-High — output quality should be more consistent

### Round 4 — Track 3 (Codex agent)

**Track 3 commits** (Codex agent):
- `3462760`: Add shared playground design tokens (CSS variables)
- `4a0174a`: Use shared theme tokens in seo-dashboard template  
- `50b2a65`: Use shared theme tokens in analytics-wizard template
- `fac8ed5`: Use shared theme tokens in performance-monitor template
- Impact: Medium — 3 templates now use design tokens (10 remaining)

### Round 5 — Context Efficiency + Routing

**exp/context-001** (commit `cdbb9b3`)
- Improved PreCompact hook: now captures state, BRIEFING.md (first 80 lines), last 5 completed + next 5 pending tasks
- Before: only ran memory-extract.sh
- After: much richer snapshot for post-compaction recovery
- Impact: Medium — faster context recovery after compaction

**exp/routing-003** (commit `e62dc5e`)
- Finding: 15+ skills had no routing in the intent table (all new v17 skills)
- Missing: SEO, content, experiments, i18n, performance, accessibility, analytics, code-review, debugger, docs, crypto, onboarding, playground-generator
- Fix: Added 15 new rows to intent detection table
- Impact: High — users can now ask for v17 skills and get routed correctly

---

## Metrics Tracking

### Baseline (before session)
- postCompactionSections: BROKEN (0% effectiveness)
- Anti-Drift in configs: MISSING (0/4 configs)
- Intent table coverage: ~50% of skills had routing
- Skills with playground instructions: ~40% 
- Skills with Definition of Done: 0%
- Auto-chain between ideation skills: MISSING

### Current State (after Round 5)
- postCompactionSections: FIXED + PostCompact hook added
- Anti-Drift in configs: FIXED (4/4 configs)
- Intent table coverage: ~85% of skills (was ~50%)
- Skills with playground instructions: ~65% (was ~40%)
- Skills with Definition of Done: 12 skills (was 0)
- Auto-chain between ideation skills: 8 skills chained

### Expected Improvements (Hypothesis)
- Track 1 (Skill Routing): ~50% → ~75% accuracy in short sessions, ~65% → ~80% after compaction
- Track 4 (Orchestration): chain completion ~40% → ~70%
- Track 5 (Output Quality): quality gate compliance 0% → ~60%
- Session Durability: significant improvement due to postCompactionSections fix

---

## Active Processes
- Codex agent (session clear-pine): Completing design token migration for remaining playground templates
