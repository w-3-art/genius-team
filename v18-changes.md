# v18 Changes — Implementation Log

## Critical Fixes

### 1. postCompactionSections — BROKEN (now fixed)
**File:** `configs/*/settings.json` (all 4 modes)
**Problem:** 4 section headers in `postCompactionSections` didn't match actual CLAUDE.md headers
- `"## Genius Team"` → didn't exist
- `"## Memory"` → actual was `"## 🧠 Memory"` (emoji + case)
- `"## Anti-Drift Rules"` → actual was `"## 🚨 ANTI-DRIFT RULES"`
- `"## Current Phase"` → didn't exist at all
**Fix:** Added `## Genius Team Core Rules` section + updated all 4 configs to reference it

### 2. Anti-Drift + Core Rules missing from config CLAUDE.md files
**File:** `configs/cli/CLAUDE.md`, `configs/ide/CLAUDE.md`, `configs/omni/CLAUDE.md`, `configs/dual/CLAUDE.md`
**Problem:** Root CLAUDE.md had anti-drift rules, but `setup.sh` installs from configs → users never got them
**Fix:** Added `## 🚨 ANTI-DRIFT RULES` + `## Genius Team Core Rules` to all 4 config files

### 3. PostCompact hook missing
**File:** `configs/*/settings.json` (all 4 modes)
**Problem:** No hook fired after compaction to reinforce anti-drift rules
**Fix:** Added PostCompact hook to echo critical reminders

---

## Skill Improvements

### Routing Improvements
- `genius-reviewer`: Added negative trigger (vs genius-code-review)
- `genius-qa-micro`: Added negative trigger (vs genius-qa full audit)
- `genius-deployer`: Added negative triggers + pre-deployment checklist
- `genius-start`: Added negative triggers (vs genius-interviewer, vs /continue)
- `genius-dev`: Clarified as smart dispatcher with routing table

### Router (genius-team/SKILL.md)
- Added `## Disambiguation Rules` section with explicit tiebreak rules
- Added 15 new intent routes for v17 skills (SEO, content, i18n, analytics, etc.)

### Orchestration
- `genius-interviewer` → auto-chains to `genius-product-market-analyst`
- `genius-product-market-analyst` → auto-chains to `genius-specs`
- `genius-specs` → auto-chains to `genius-designer`
- `genius-designer` → auto-chains to `genius-marketer`
- `genius-marketer` → auto-chains to `genius-copywriter`
- `genius-copywriter` → auto-chains to `genius-integration-guide`
- `genius-integration-guide` → auto-chains to `genius-architect`
- `genius-architect` → auto-chains to `genius-orchestrator`

### Playground Instructions
Added mandatory playground update section to 13 v17 skills:
genius-seo, genius-crypto, genius-analytics, genius-performance, genius-accessibility, genius-code-review, genius-docs, genius-content, genius-dev-frontend, genius-dev-backend, genius-dev-mobile, genius-dev-database, genius-dev-api

### Output Quality (Definition of Done)
Added DoD to 8 skills:
- `genius-dev-frontend`: build, TypeScript, lint, responsive, console, a11y
- `genius-dev-backend`: app starts, endpoints tested, error handling, no hardcoded secrets, input validation
- `genius-dev-database`: migration runs, schema valid, indexes defined, rollback script
- `genius-dev-api`: integration tested, error handling, rate limiting respected, secrets in env
- `genius-seo`: every recommendation is specific, actionable, measurable, prioritized
- `genius-analytics`: events verified, test cases provided, edge cases covered
- `genius-performance`: baseline score, specific issues, implementation steps, expected after
- `genius-accessibility`: WCAG level cited, element reference, impact, fix code

Added output quality requirements to 4 more skills:
- `genius-code-review`: file:line, severity, category, fix code for every issue
- `genius-docs`: tested, Divio-structured, no broken links
- `genius-copywriter`: no placeholders, specific benefits, clear CTAs
- `genius-content`: complete draft, word count, GEO-optimized, CTA included

---

## Design System

### Playground Design Tokens
**New file:** `playgrounds/templates/design-tokens.css`
CSS variables: `--color-primary`, `--color-bg-dark`, `--color-bg-card`, `--color-text`, etc.

**Migrated templates:**
- `seo-dashboard.html` → uses design tokens
- `analytics-wizard.html` → uses design tokens
- `performance-monitor.html` → uses design tokens
- (Remaining 9+ templates to be migrated by Codex agent)

---

## Context Efficiency

### Improved PreCompact Hook
Now captures before compaction:
- Current state (phase, skill, task)
- First 80 lines of BRIEFING.md
- Last 5 completed + next 5 pending tasks

---

## Commits

| Commit | Description |
|--------|-------------|
| `869871e` | exp/durability-001: fix postCompactionSections |
| `cfd4dfd` | exp/routing-001: skill descriptions + negative triggers |
| `189d595` | exp/routing-002: disambiguation rules to router |
| `dbb7d5c` | exp/playground-001: playground section to 13 skills |
| `0e83de3` | exp/orchestration-001: auto-chain to 8 ideation skills |
| `b05dcdb` | exp/durability-002: Core Rules + Anti-Drift to all 4 configs |
| `a3b3b16` | exp/durability-003: PostCompact hook |
| `641e0d1` | exp/quality-001: Definition of Done to 8 skills |
| `add0820` | exp/quality-002: output quality to code-review, docs, copywriter, content |
| `3462760` | design-tokens.css (Codex) |
| `4a0174a` | seo-dashboard tokens (Codex) |
| `50b2a65` | analytics-wizard tokens (Codex) |
| `fac8ed5` | performance-monitor tokens (Codex) |
| `cdbb9b3` | exp/context-001: PreCompact hook improvement |
| `e62dc5e` | exp/routing-003: 15 new routes in intent table |
