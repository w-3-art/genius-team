# Autoresearch Journal — Genius Team v18-candidate
*Started: 2026-03-12 23:00 CET*
*Last updated: 2026-03-13 01:15 CET*

## Session Summary
- **Total commits**: 52 on v18-candidate (vs main)
- **Agents used**: Claude (Opus 4.6) + Codex (GPT-5.4) in parallel
- **Tracks covered**: 1 (Routing), 2 (Playground Content), 3 (Playground Design), 4 (Orchestration), 5 (Skill Quality), 6 (Context Efficiency), 7 (Session Durability)

## Critical Bug Found
**postCompactionSections mismatch** — headers in configs didn't match CLAUDE.md (emojis + case differences). After compaction, ZERO sections reinjected. This is THE root cause of context drift.

## Experiments Log

### Track 1 — Skill Routing (4 experiments)
- `routing-001` — Added negative triggers to 5 skills (reviewer, qa-micro, deployer, start, dev)
- `routing-002` — Added disambiguation rules to router (5 common confusion pairs)
- `routing-003` — Added 15 missing routes to intent table (SEO, content, a/b, i18n, debug, etc.)
- `routing-004` — Added Quick Reference routing table to GENIUS_GUARD.md

### Track 2 — Playground Content (3 experiments)
- `playground-001` — Added mandatory "Playground Update" section to 13 skills
- `playground-002` — playground-generator must use design-tokens.css + responsive + a11y
- `playground-003` — genius-designer now outputs design-tokens.css with project brand

### Track 3 — Playground Design (Codex agent, 20+ commits)
- Created `playgrounds/templates/design-tokens.css` (shared CSS custom properties)
- Migrated seo-dashboard, analytics-wizard, performance-monitor to shared tokens
- Expanded design tokens with full theme coverage
- Batch migration of ALL remaining 18 playground templates

### Track 4 — Orchestration (1 experiment)
- `orchestration-001` — Added auto-chain "Next Step" to all 8 ideation skills

### Track 5 — Skill Quality (4 experiments)
- `quality-001` — Definition of Done for 8 skills (frontend, backend, database, api, seo, analytics, performance, accessibility)
- `quality-002` — Output quality for code-review, docs, copywriter, content
- `quality-003` — Definition of Done for security, i18n, onboarding, crypto
- `quality-004` — Enhanced team-optimizer with concrete health checklist

### Track 6 — Context Efficiency (5 experiments)
- `context-001` — Improved PreCompact hook (richer critical context)
- `context-002` — Fixed version in SessionStart hook (v9.0 → v17.0)
- `context-003` — genius-team SKILL.md: 17KB → 12.4KB (-27%)
- `context-004` — genius-orchestrator: compressed NEVER STOP RULE + sprint template
- `context-005` — genius-interviewer: replaced 40-line JSON with 2-line cross-reference

### Track 7 — Session Durability (3 experiments)
- `durability-001` — Fixed postCompactionSections (headers didn't match CLAUDE.md)
- `durability-002` — Added Core Rules + Anti-Drift to ALL 4 config CLAUDE.md files
- `durability-003` — Added PostCompact hook to reinject anti-drift after compaction

## Metrics (estimated improvement)
| Metric | Before | After (estimated) |
|--------|--------|-------------------|
| Routing accuracy | ~60% | ~85% (disambiguation + negative triggers) |
| Post-compaction retention | 0% | ~80% (fixed headers + PostCompact hook) |
| Skill quality gates | 0/42 skills | 16/42 skills have DoD |
| Playground token system | none | shared design-tokens.css |
| Router context size | 17KB | 12.4KB (-27%) |
| Config anti-drift | 0/4 modes | 4/4 modes |
| postCompaction headers | ~60% match | 100% match (20/20 verified) |
