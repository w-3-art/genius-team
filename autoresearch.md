# 🔬 Autoresearch Journal — Genius Team v18

> Started: 2026-03-12 23:00 CET
> Model: Claude Sonnet 4.6 (primary) + Codex (secondary)
> Objective: Maximize skill routing accuracy, playground quality, orchestration chain completion, and context durability across 30-task sessions including compaction.

---

## Night Session — 2026-03-12 → 2026-03-13

### Phase 0: Baseline Establishment

#### Finding 0.1 — CRITICAL: postCompactionSections don't match CLAUDE.md headers
- `compaction.postCompactionSections` in all 4 settings.json references:
  - `"## Genius Team"` → DOES NOT EXIST (title is `# Genius Team v17.0 — CLI Mode`)
  - `"## Memory"` → MISMATCH (actual: `## 🧠 Memory` — emoji prefix)
  - `"## Anti-Drift Rules"` → MISMATCH (actual: `## 🚨 ANTI-DRIFT RULES` — emoji + caps)
  - `"## Current Phase"` → DOES NOT EXIST
- **Impact**: After compaction, ZERO sections are reinjected. Claude loses all Genius Team context.
- **Fix**: Match actual headers + add skill routing rules

#### Finding 0.2 — Skill descriptions quality varies widely
- Some skills (genius-accessibility, genius-analytics) have excellent trigger phrases
- Others (genius-architect, genius-memory) have weak/generic descriptions
- genius-dev and genius-dev-frontend overlap without clear disambiguation
- genius-reviewer vs genius-code-review: unclear when to use which

#### Finding 0.3 — No explicit "always use skills" instruction survives compaction
- CLAUDE.md has `🚨 ANTI-DRIFT RULES` but it's lost after compaction
- The router (genius-team/SKILL.md) has good intent detection table but it's in the skill, not in base instructions

#### Finding 0.4 — 24 skills have zero playground update instructions
- Only core ideation skills (interviewer, designer, etc.) mention playgrounds
- All v17 dev/analysis/content skills produce output but don't update dashboard
- Result: skills create orphan HTML files or don't update anything

#### Finding 0.5 — No auto-chaining between ideation skills
- Each skill completes and waits for user to manually invoke the next one
- No "Next Step" suggestions in any skill

#### Finding 0.6 — Router has zero disambiguation logic
- When request could match multiple skills, no rules for resolution
- Claude defaults to working solo instead of picking the closest match

---

### Phase 1: Experiments (23:00 → ongoing)

#### Experiment durability-001 ✅ (commit 869871e)
- **Track**: Session Durability
- **Change**: Fixed postCompactionSections (headers didn't match CLAUDE.md) + added "Genius Team Core Rules" section
- **Impact**: CRITICAL — after compaction, Claude now retains skill routing rules, anti-drift, and playground rules
- **Files**: CLAUDE.md, 4x settings.json

#### Experiment routing-001 ✅ (commit cfd4dfd)
- **Track**: Skill Routing
- **Change**: Added negative triggers to 5 skills, clarified confusion pairs
- **Impact**: Reduced ambiguity for reviewer/code-review, qa/qa-micro, dev/dev-frontend
- **Files**: 5x SKILL.md

#### Experiment playground-001 ✅ (commit dbb7d5c)
- **Track**: Playground Content
- **Change**: Added mandatory "Playground Update" section to 13 skills
- **Impact**: Skills now instructed to update dashboard tabs, not create orphan files
- **Files**: 13x SKILL.md

#### Experiment routing-002 ✅ (commit 189d595)
- **Track**: Skill Routing
- **Change**: Added disambiguation rules to router
- **Impact**: 5 common confusion pairs now have explicit resolution rules
- **Files**: genius-team/SKILL.md

#### Experiment orchestration-001 ✅ (commit 0e83de3)
- **Track**: Orchestration
- **Change**: Added auto-chain "Next Step" to 8 ideation skills
- **Impact**: Skills now suggest the next skill when they complete
- **Files**: 8x SKILL.md

