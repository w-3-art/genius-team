# v18-candidate — Changes Log

> Branch: `v18-candidate`
> Base: `main` (v17.0.0) + `feat/autoresearch-framework`
> Started: 2026-03-12 23:00 CET

---

## Changes Implemented

### 1. Post-Compaction Context Survival (CRITICAL)
- `postCompactionSections` in all 4 settings.json now match actual CLAUDE.md headers
- New `## Genius Team Core Rules` section in CLAUDE.md with condensed routing table, anti-drift rules, and playground rules
- **Before**: After compaction, Claude lost ALL Genius Team context → skills stopped being used
- **After**: Core routing rules, anti-drift, and playground rules survive compaction

### 2. Skill Routing Improvements
- Added negative triggers to 5 skills (genius-reviewer, genius-qa-micro, genius-deployer, genius-start, genius-dev)
- Clarified confusion pairs: reviewer vs code-review, qa vs qa-micro, dev vs dev-frontend
- Added disambiguation rules to router: explicit resolution for 5 common misroutes
- Router now has "when ambiguous" protocol: prefer specificity > ask one question > never go solo

### 3. Playground Content Accuracy
- Added mandatory "Playground Update" section to 13 skills that produce output
- Explicit instructions: NEVER create new HTML files, always update existing dashboard tab
- Remove mock data, remind user to open dashboard after each skill

### 4. Orchestration Auto-Chaining
- 8 ideation skills now auto-suggest the next skill on completion
- Chain: interviewer → PMA → specs → designer → marketer → copywriter → integration-guide → architect → orchestrator
- Reduces manual intervention between phases

