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
hooks:
  PreToolUse:
    - type: command
      command: "bash -c 'echo \"[$(date +%H:%M:%S)] ROUTER: $TOOL_NAME\" >> .genius/router.log 2>/dev/null || true'"
---

# Genius Team v17.0 — Your AI Product Team

**From idea to production. Agent Teams. File-based memory. No fluff.**

---

## ⛔ MANDATORY CHECKS (NON-NEGOTIABLE)

Before routing, read `.genius/state.json`, verify the previous checkpoint is validated, and confirm the required artifact/playground exists. If any check fails, block routing and recover first.

---

## Memory Integration

Read `@.genius/memory/BRIEFING.md` at session start and check `plan.md` before routing.

## Intent Detection

| User Says | Route To |
|-----------|----------|
| "new project", "I want to build", "idea", "help me create", "let's build" | genius-interviewer |
| "market analysis", "competitors", "market research", "TAM/SAM" | genius-product-market-analyst |
| "write specs", "requirements", "specifications", "user stories" | genius-specs |
| "design", "branding", "colors", "UI", "visual", "logo" | genius-designer |
| "marketing", "launch plan", "go-to-market", "acquisition" | genius-marketer |
| "write copy", "landing page text", "headlines", "email copy" | genius-copywriter |
| "setup services", "env vars", "API keys", "integrations" | genius-integration-guide |
| "architecture", "plan the build", "technical design", "plan.md" | genius-architect |
| "start building", "execute", "build it", "go", "make it" | genius-orchestrator |
| "run tests", "quality check", "QA", "audit" | genius-qa |
| "security audit", "vulnerabilities", "penetration test" | genius-security |
| "deploy", "go live", "ship it", "production" | genius-deployer |
| "help me test", "testing session", "watch while I test" | genius-test-assistant |
| "remember", "what did we decide", "context", "history" | genius-memory |
| "optimize skills", "update genius team" | genius-team-optimizer |
| "check for updates", "new claude code version" | genius-updater |
| "SEO", "search ranking", "Google ranking", "meta tags", "keywords" | genius-seo |
| "write blog", "content strategy", "article", "newsletter" | genius-content |
| "A/B test", "experiment", "hypothesis", "conversion rate" | genius-experiments |
| "translate", "localization", "i18n", "multi-language" | genius-i18n |
| "performance", "speed", "load time", "Core Web Vitals" | genius-performance |
| "accessibility", "a11y", "WCAG", "screen reader" | genius-accessibility |
| "analytics setup", "tracking", "events", "GA4", "Plausible" | genius-analytics |
| "code review", "review PR", "review code", "review all files" | genius-code-review |
| "debug", "fix this error", "why is this broken" | genius-debugger |
| "documentation", "write docs", "README", "API docs" | genius-docs |
| "crypto", "Web3", "blockchain", "smart contract", "NFT" | genius-crypto |
| "onboard", "user onboarding", "welcome flow", "first-time user" | genius-onboarding |
| "playground template", "generate playground", "create playground" | genius-playground-generator |

## Context Detection

Check both the phase artifact and any required playground before routing:
- No project files: `genius-interviewer`
- `DISCOVERY.xml` + `DISCOVERY.html`: `genius-product-market-analyst`
- `MARKET-ANALYSIS.xml`: `genius-specs`
- `SPECIFICATIONS.xml`: approval gate, then `genius-designer`
- `DESIGN-SYSTEM.xml` + `DESIGN-SYSTEM.html`: choice gate, then `genius-marketer`
- `MARKETING-PLAN.xml`: `genius-copywriter`
- `COPY-SYSTEM.xml` + `COPY-SYSTEM.html`: `genius-integration-guide`
- `INTEGRATIONS.xml`: `genius-architect`
- `ARCHITECTURE.md`: approval gate, then `genius-orchestrator`
- `.claude/plan.md` with active work: resume `genius-orchestrator`
- `PROGRESS.md` complete: `genius-qa` or `genius-deployer`

If the previous artifact or required playground is missing, block routing and regenerate it first.

---

## ⚡ ARTIFACT VALIDATION

Required handoff artifacts are:
- `genius-interviewer`: `DISCOVERY.xml` + `DISCOVERY.html`
- `genius-product-market-analyst`: `MARKET-ANALYSIS.xml`
- `genius-specs`: `SPECIFICATIONS.xml`
- `genius-designer`: `DESIGN-SYSTEM.xml` + `DESIGN-SYSTEM.html`
- `genius-marketer`: `MARKETING-PLAN.xml`
- `genius-copywriter`: `COPY-SYSTEM.xml` + `COPY-SYSTEM.html`
- `genius-integration-guide`: `INTEGRATIONS.xml`
- `genius-architect`: `ARCHITECTURE.md`
- `genius-orchestrator`: updated `plan.md`
- `genius-qa`: `QA-REPORT.xml`
- `genius-security`: `SECURITY-AUDIT.xml`
- `genius-deployer`: `DEPLOYMENT.md`

See `GENIUS_GUARD.md` for full recovery protocol.

---

## Checkpoints

User approval is only required after `genius-specs`, `genius-designer`, and `genius-architect`. All other valid handoffs are automatic.

## State Management

Update `.genius/state.json` on every successful handoff with the chosen skill and a fresh `updated_at` timestamp.

---

## 🚫 Handoff Protocol (BLOCKING)

Before routing: required artifact exists, required checkpoint is validated, and required playground exists. On success, update `state.json`, pass context, and announce the transition briefly.

---

## Memory Triggers

- "Remember that..." / "We decided..." → `.genius/memory/decisions.json`
- "This broke because..." → `.genius/memory/errors.json`
- "Pattern: ..." → `.genius/memory/patterns.json`

## Disambiguation Rules

When the user's request is ambiguous or could match multiple skills:

1. **Prefer specificity over generality**: If the request mentions "React component" → genius-dev-frontend directly (don't go through genius-dev dispatcher)
2. **When genuinely ambiguous**: Ask ONE clarifying question: "This could be [skill A] or [skill B]. Which direction?"
3. **NEVER default to working without a skill** — if unsure, pick the most likely skill. Wrong skill > no skill.
4. **Common confusions**:
   - "review" without "PR" → genius-reviewer (single-agent). "review PR" / "review pull request" → genius-code-review (multi-agent)
   - "copy" for landing page → genius-copywriter. "blog post" / "article" → genius-content
   - "integrate Stripe" / "add [service]" → genius-dev-api (wrapping external APIs). BUT "Stripe billing" / "subscription billing" / "payment backend" → genius-dev-backend (building server-side billing logic). "how to setup [service]" → genius-integration-guide (guide only)
   - "analyze the market" / "who are the competitors" / "market landscape" → genius-product-market-analyst (NOT genius-specs). "write specs" / "specifications" / "requirements" → genius-specs
   - "define the architecture" / "stack, database schema, API structure" / "technical architecture" → genius-architect (NOT no-skill — even without SPECIFICATIONS.xml if user explicitly asks for architecture)
   - "write specs based on what we discussed" / "formalize what we said" / "specs from our conversation" → genius-specs (NOT genius-designer)
   - "test" / "QA" after full build → genius-qa. "quick check" / after single task → genius-qa-micro
   - "build login page" → genius-dev-frontend. "build auth system" → genius-dev-backend. "build login with auth" → genius-dev (dispatcher, splits the task)

## Commands

Use `/genius-start`, `/status`, `/continue`, `/reset`, `/update-check`, and `/genius-dashboard` as the primary control commands. `STOP` or `PAUSE` halts autonomous execution.

## Master Dashboard

Mention `.genius/DASHBOARD.html` after skill completion, `/genius-start`, `/status`, and checkpoint approvals. When the user wants an overview, refresh it with `/genius-dashboard` instead of generating separate summary pages.

## Dual Mode

Use `/challenge` and `/genius-switch-engine {dual|claude|codex}` for cross-engine workflows.

---

## Error Recovery

If a routed skill fails (crashes, produces empty output, or gets stuck):
1. **Retry once** with the same skill
2. If still fails, **fall back to genius-dev** for implementation tasks or **genius-reviewer** for review tasks
3. **Log the failure** in `.genius/errors.log` with timestamp, skill name, and error
4. **Notify user**: "⚠️ {skill} encountered an issue. Falling back to {fallback}."
5. Never silently swallow errors — always surface them

## Definition of Done

- [ ] Selected skill matches the user's intent and current project state
- [ ] Checkpoint and artifact validation happened before routing
- [ ] Ambiguous requests were clarified or resolved with explicit rules
- [ ] Fallback behavior is defined for routing failures
- [ ] User sees the next skill or recovery step clearly
