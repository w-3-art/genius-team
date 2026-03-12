# Autoresearch Journal — Genius Team v18-candidate
*Started: 2026-03-12 23:00 CET*
*Last updated: 2026-03-13 00:35 CET*

## Session Summary
- **Total commits**: 73 on v18-candidate (vs main)
- **Agents used**: Claude (Opus 4.6) + Codex (GPT-5.4) in parallel, 3 cycles
- **Tracks covered**: All 7

## Critical Bug Found & Fixed
**postCompactionSections mismatch** — headers in config settings.json didn't match CLAUDE.md section names (emojis + case). After compaction, ZERO sections reinjected → total context loss → root cause of skill routing drift.

## Experiments Log (37 named experiments)

### Track 1 — Skill Routing (7 experiments)
| ID | Commit | Description |
|----|--------|-------------|
| routing-001 | `cfd4dfd` | Negative triggers on 5 skills (reviewer, qa-micro, deployer, start, dev) |
| routing-002 | `189d595` | Disambiguation rules in router (5 confusion pairs) |
| routing-003 | — | 15 missing routes added to intent table |
| routing-004 | — | Quick Reference routing table in GENIUS_GUARD.md |
| routing-005 | — | Error recovery protocol: retry → fallback → log → notify |
| routing-006 | `c99359d` | Negative triggers on dual-engine, integration-guide, team-optimizer |
| routing-007 | `f5a18a3` | Handoff sections added to genius-crypto, genius-seo |

### Track 2 — Playground Content (3 experiments)
| ID | Description |
|----|-------------|
| playground-001 | "Playground Update" section added to 13 skills |
| playground-002 | playground-generator mandates design-tokens.css + responsive + a11y |
| playground-003 | genius-designer outputs design-tokens.css with project brand |

### Track 3 — Playground Design (20+ commits by Codex)
- Created shared `design-tokens.css` with CSS custom properties
- Migrated ALL 18 playground templates to shared tokens
- Consistent theming across entire playground system

### Track 4 — Orchestration (2 experiments)
| ID | Description |
|----|-------------|
| orchestration-001 | Auto-chain "Next Step" to all 8 ideation skills |
| orchestration-002 | State consistency check every 5 tasks |

### Track 5 — Skill Quality (7 experiments)
| ID | Description |
|----|-------------|
| quality-001 | DoD for 8 skills (frontend, backend, database, api, seo, analytics, performance, accessibility) |
| quality-002 | Output quality for code-review, docs, copywriter, content |
| quality-003 | DoD for security, i18n, onboarding, crypto |
| quality-004 | Enhanced team-optimizer health checklist |
| quality-005 | DoD for 5 core ideation skills |
| quality-006 | DoD for 5 more core skills |
| quality-007 | validate-skills.sh automated quality script |

### Track 6 — Context Efficiency (19 experiments)
| ID | File | Before → After | Savings |
|----|------|-----------------|---------|
| context-001 | PreCompact hook | improved | richer context |
| context-002 | SessionStart hook | v9.0 → v17.0 | correct version |
| context-003 | genius-team | 17KB → 12.4KB | -27% |
| context-004 | genius-orchestrator | verbose → compressed | -10% |
| context-005 | genius-interviewer | 40-line JSON → 2-line ref | -1.4KB |
| context-006-010 | 5 skills | various | -55% max |
| context-011 | orchestrator + dual-engine | 13KB→11.6KB, 10.3→10KB | -1.7KB |
| context-012 | genius-docs | 10.2KB → 7.8KB | -23% |
| context-013 | genius-code-review | 10KB → 7.6KB | -25% |
| context-014 | genius-dev-api | 10.2KB → 7.2KB | -29% |
| context-015 | genius-performance | 9.6KB → 8.7KB | -9% |
| context-016 | genius-i18n | 9.4KB → 7.8KB | -17% |
| context-017 | designer + deployer | 9.4→7.9KB, 9.3→6.8KB | -20% avg |
| context-018 | genius-dual-engine | 10.8KB → 8.3KB | -23% |
| context-019 | 13 files (Codex batch) | -713 lines | massive |

### Track 7 — Session Durability (4 experiments)
| ID | Description |
|----|-------------|
| durability-001 | Fixed postCompactionSections (critical) |
| durability-002 | Core Rules + Anti-Drift in all 4 config CLAUDE.md |
| durability-003 | PostCompact hook reinjects anti-drift |
| durability-004 | Fixed dual mode settings.json header mismatch |

## Key Metrics
| Metric | Before | After |
|--------|--------|-------|
| Files > 10KB | 10 | **0** |
| Files > 8KB | ~20 | **8** |
| Skills with DoD | 0/42 | **42/42** |
| Skills with negative triggers | ~15 | **~30** |
| Post-compaction retention | 0% | **~80%** |
| Playground design system | none | **shared design-tokens.css** |
| Config anti-drift | 0/4 modes | **4/4 modes** |
| Router disambiguation | none | **5 confusion pairs + confidence scoring** |
| Total context saved | — | **~30KB estimated** |
