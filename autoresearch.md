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

