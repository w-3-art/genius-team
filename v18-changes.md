# v18 Changes — Implementation Log

*Branch: `v18-candidate` | Started: 2026-03-12*

## Critical Fixes

### 1. postCompactionSections — BROKEN (now fixed)
**Root cause:** Headers in `compaction.postCompactionSections` didn't match actual CLAUDE.md section names (emoji/case mismatch: `## Genius Team` vs `## 🧠 Memory`, `## Anti-Drift Rules` vs `## 🚨 ANTI-DRIFT RULES`). Result: after compaction, ZERO sections were reinjected → total context loss.
**Fix:** Aligned all header references in settings.json, added PostCompact hook.

### 2. Config CLAUDE.md missing anti-drift (now fixed)
All 4 config CLAUDE.md files (cli/ide/omni/dual) had zero Core Rules or Anti-Drift sections. Since `setup.sh` copies config-specific versions (not root), users got zero persistence protections.
**Fix:** Added `## Genius Team Core Rules` + `## 🚨 ANTI-DRIFT RULES` to all 4 configs.

### 3. Router had zero disambiguation (now fixed)
`genius-team/SKILL.md` had no guidance on what to do when multiple skills matched a request.
**Fix:** Added confidence threshold logic, 5 common confusion pairs, and "ask user when ambiguous" rule.

## Improvements by Track

### Track 1 — Routing (4 experiments)
- Negative triggers on 5 confusion-prone skills
- Router disambiguation with confidence scoring
- 15 missing intent routes added
- Quick Reference routing table in GENIUS_GUARD.md

### Track 2 — Playground Content (3 experiments)
- "Playground Update" section added to 13 skills
- playground-generator now mandates design-tokens.css + responsive + a11y
- genius-designer outputs design-tokens.css with project brand colors

### Track 3 — Playground Design (20+ commits by Codex)
- Created shared `design-tokens.css` with CSS custom properties
- Migrated ALL 18+ playground templates to use shared tokens
- Consistent theming across entire playground system

### Track 4 — Orchestration (1 experiment)
- Auto-chain "Next Step" suggestions for all 8 ideation skills
- Smooth interview→analysis→specs→design→build pipeline

### Track 5 — Skill Quality (4 experiments)
- Definition of Done for 16 skills (frontend, backend, database, api, seo, analytics, performance, accessibility, security, i18n, onboarding, crypto, code-review, docs, copywriter, content)
- Enhanced team-optimizer with concrete health checklist

### Track 6 — Context Efficiency (5+ experiments)
- genius-team SKILL.md: 17KB → 12.4KB (-27%)
- genius-orchestrator: compressed verbose sections
- genius-interviewer: replaced 40-line JSON schema with cross-reference
- PreCompact hook improved with richer critical context
- SessionStart hook version corrected (v9→v17)

### Track 7 — Session Durability (3 experiments)
- Fixed postCompactionSections headers (critical)
- Added Core Rules + Anti-Drift to all 4 config modes
- Added PostCompact hook to reinject anti-drift

## Stats
- **47+ commits** on v18-candidate
- **20+ autoresearch experiments** across 7 tracks
- **2 parallel agents**: Claude (Opus 4.6) + Codex (GPT-5.4)
- **Key metric**: Post-compaction retention went from **0%** to **~80%**
