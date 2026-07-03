---
name: genius-team
description: >-
  Main intelligent router for Genius Team. Analyzes intent and routes to the
  right specialized skill. Use when user says "start", "begin project", "what
  should I do next", "I want to build", or asks for status/progress.
  Do NOT use directly for implementation, design, or QA tasks — those have
  dedicated skills.
user-invocable: true
skills:
  - genius-interviewer
  - genius-product-market-analyst
  - genius-specs
  - genius-designer
  - genius-marketer
  - genius-copywriter
  - genius-integration-guide
  - genius-architect
  - genius-orchestrator
  - genius-qa
  - genius-security
  - genius-deployer
  - genius-memory
  - genius-onboarding
  - genius-dev-frontend
  - genius-dev-backend
  - genius-dev-mobile
  - genius-dev-database
  - genius-dev-api
  - genius-code-review
  - genius-skill-creator
  - genius-experiments
  - genius-seo
  - genius-crypto
  - genius-analytics
  - genius-performance
  - genius-accessibility
  - genius-i18n
  - genius-docs
  - genius-content
  - genius-template
  - genius-dev
  - genius-debugger
  - genius-reviewer
  - genius-qa-micro
  - genius-test-assistant
  - genius-dual-engine
  - genius-omni-router
  - genius-start
  - genius-team-optimizer
  - genius-updater
  - genius-playground-generator
  - genius-auto
  - genius-ui-tester
  - genius-ci
  - genius-scheduler
  - genius-tips
  - genius-guard-pre-planning
  - genius-guard-pre-coding
  - genius-guard-pre-deploy
hooks:
  PreToolUse:
    - type: command
      command: "bash -c 'echo \"[$(date +%H:%M:%S)] ROUTER: $TOOL_NAME\" >> .genius/router.log 2>/dev/null || true'"
context: fork
---

# Genius Team v22.0 — Your AI Product Team

**From idea to production. Agent Teams. File-based memory. No fluff.**
Full ladders and maps: `references/routing-details.md`.

## MANDATORY CHECKS (NON-NEGOTIABLE)

Before routing:
1. Read `.genius/state.json` — verify phase, checkpoint, and mode
2. Read `.genius/mode.json` — adjust behavior per mode (beginner: explain +
   confirm; builder: brief announce, default; pro: silent; agency: client-friendly)
3. Verify previous checkpoint is validated and required artifact/playground exists
4. If any check fails, block routing and recover first

Read `@.genius/memory/BRIEFING.md` at session start and check `plan.md` before routing.

## Intent Detection

- **Core flow**: "new project"/"idea" → genius-interviewer · "market analysis"/"competitors" → genius-product-market-analyst · "specs"/"requirements" → genius-specs · "design"/"branding"/"UI" → genius-designer · "marketing"/"go-to-market" → genius-marketer · "write copy"/"headlines" → genius-copywriter · "setup services"/"API keys" → genius-integration-guide · "architecture"/"plan the build" → genius-architect · "execute"/"build it" → genius-orchestrator · "implement"/"code" → genius-dev
- **Quality**: "QA"/"full audit" → genius-qa · "quick check" → genius-qa-micro · "security audit" → genius-security · "review PR" → genius-code-review · "review my code" → genius-reviewer · "debug"/"fix error" → genius-debugger · "manual test" → genius-test-assistant · "test the UI" → genius-ui-tester
- **Growth**: "SEO" → genius-seo · "analytics"/"GA4" → genius-analytics · "performance"/"CWV" → genius-performance · "a11y"/"WCAG" → genius-accessibility · "blog"/"newsletter" → genius-content · "i18n" → genius-i18n · "Web3"/"smart contract" → genius-crypto
- **Infra**: "deploy"/"ship it" → genius-deployer · "setup CI" → genius-ci · "schedule task" → genius-scheduler · "A/B test" → genius-experiments · "docs"/"README" → genius-docs · "remember"/"what did we decide" → genius-memory

Meta intents (skill optimization, updates, onboarding, playground templates,
auto-mode tuning, tips, `/genius-mode`, `/genius-import`) route on each skill's
own description. Full trigger-phrase tables: `references/routing-details.md`
§ Intent Detection — Full Tables and § Meta Intents.

No state.json → genius-interviewer. Otherwise follow the artifact ladder
(DISCOVERY → MARKET-ANALYSIS → SPECS → design → MARKETING-PLAN → COPY →
INTEGRATIONS → architecture → orchestrator): full ladder + required-artifact
map per skill in `references/routing-details.md` § Context Detection and
§ Artifact Validation. Missing artifact/playground → block routing, regenerate first.

## Pre-Transition Guards

- Before genius-architect: invoke `genius-guard-pre-planning`
- Before genius-dev/genius-orchestrator: invoke `genius-guard-pre-coding`
- Before genius-deployer: invoke `genius-guard-pre-deploy`

## Checkpoints & Handoff Protocol (BLOCKING)

User approval is only required after `genius-specs`, `genius-designer`, and
`genius-architect`; other valid handoffs are automatic. Before routing: required
artifact exists, checkpoint validated in `.genius/state.json`, `.genius/outputs/state.json`
reflects the phase. On success: update `state.json` (fresh `updated_at`), pass
context, announce the transition briefly, mention `.genius/DASHBOARD.html`.

## Disambiguation

Prefer specificity; genuinely ambiguous → ask ONE clarifying question; NEVER
work without a skill (wrong skill > no skill). Common confusions table:
`references/routing-details.md` § Disambiguation Rules.

## Error Recovery

Skill fails → retry once → fall back (genius-dev for implementation,
genius-reviewer for review) → log to `.genius/errors.log` → notify user. Never
silently swallow errors. Memory triggers, commands, dual mode, workflow
registry: `references/routing-details.md`.

## Definition of Done

- [ ] Selected skill matches the user's intent and current project state
- [ ] Checkpoint and artifact validation happened before routing
- [ ] Ambiguous requests were clarified or resolved with explicit rules
- [ ] Fallback behavior is defined for routing failures
- [ ] User sees the next skill or recovery step clearly
