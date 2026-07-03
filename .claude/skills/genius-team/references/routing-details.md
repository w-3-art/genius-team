# genius-team — Routing Reference Details

Loaded on demand from `SKILL.md`. Full context-detection ladder, artifact
validation map, disambiguation rules, and recovery protocol for the main router.

---

## Mode-Aware Behavior (full detail)

Read `@.genius/mode.json` and adjust:
- **beginner**: Explain routing choice, confirm with user before invoking
- **builder**: Announce transition briefly (default)
- **pro**: Route silently, minimal output
- **agency**: Client-friendly status updates

---

## Context Detection (full ladder)

Check both the runtime state and required project artifacts before routing:
- No `.genius/state.json`: `genius-interviewer`
- `.genius/discovery/DISCOVERY.xml` present and market phase not complete: `genius-product-market-analyst`
- `.genius/discovery/MARKET-ANALYSIS.xml` present and specs phase not complete: `genius-specs`
- `.genius/discovery/SPECIFICATIONS.xml` present and specs checkpoint pending: approval gate, then `genius-designer`
- Design phase complete in `.genius/outputs/state.json`: `genius-marketer`
- `.genius/discovery/MARKETING-PLAN.xml` present: `genius-copywriter`
- `.genius/discovery/COPY.xml` present: `genius-integration-guide`
- `.genius/discovery/INTEGRATIONS.xml` present: `genius-architect`
- Architecture checkpoint approved in `.genius/state.json`: `genius-orchestrator`
- `.claude/plan.md` or `.agents/plan.md` with active work: resume `genius-orchestrator`
- QA or deploy artifacts requested explicitly: `genius-qa`, `genius-security`, or `genius-deployer`

If the previous artifact or required playground is missing, block routing and regenerate it first.

---

## Artifact Validation (full map)

Required handoff artifacts are:
- `genius-interviewer`: `.genius/discovery/DISCOVERY.xml` + `.genius/outputs/state.json`
- `genius-product-market-analyst`: `.genius/discovery/MARKET-ANALYSIS.xml` + `.genius/outputs/state.json`
- `genius-specs`: `.genius/discovery/SPECIFICATIONS.xml` + `.genius/outputs/state.json`
- `genius-designer`: `.genius/outputs/design-playground.html` + `.genius/outputs/state.json`
- `genius-marketer`: `.genius/discovery/MARKETING-PLAN.xml` + `.genius/outputs/GTM-STRATEGY.html`
- `genius-copywriter`: `.genius/discovery/COPY.xml` + `.genius/outputs/COPY-OPTIONS.html`
- `genius-integration-guide`: `.genius/discovery/INTEGRATIONS.xml` + `.genius/outputs/STACK-CONFIG.html`
- `genius-architect`: `.genius/ARCHITECTURE.md` or architecture phase data in `.genius/outputs/state.json`
- `genius-orchestrator`: updated `.claude/plan.md` or `.agents/plan.md`
- `genius-qa`: `.genius/QA-REPORT.xml`
- `genius-security`: `.genius/SECURITY-AUDIT.xml`
- `genius-deployer`: `.genius/DEPLOYMENT.md`

See `GENIUS_GUARD.md` for full recovery protocol.

---

## Intent Detection — Full Tables (by category)

### Core Workflow
| User Says | Route To |
|-----------|----------|
| "new project", "I want to build", "idea", "let's build" | genius-interviewer |
| "market analysis", "competitors", "market research", "TAM/SAM" | genius-product-market-analyst |
| "write specs", "requirements", "specifications", "user stories" | genius-specs |
| "design", "branding", "colors", "UI", "visual", "logo" | genius-designer |
| "marketing", "launch plan", "go-to-market", "acquisition" | genius-marketer |
| "write copy", "landing page text", "headlines", "email copy" | genius-copywriter |
| "setup services", "env vars", "API keys", "integrations" | genius-integration-guide |
| "architecture", "plan the build", "technical design", "plan.md" | genius-architect |
| "start building", "execute", "build it", "go", "make it" | genius-orchestrator |
| "implement", "code", "build feature", "create component" | genius-dev |

### Quality
| User Says | Route To |
|-----------|----------|
| "run tests", "quality check", "QA", "full audit" | genius-qa |
| "quick check", "validate this", "did it work" | genius-qa-micro |
| "security audit", "vulnerabilities", "penetration test" | genius-security |
| "code review", "review PR", "review code", "review all files" | genius-code-review |
| "review my code", "check code quality" | genius-reviewer |
| "debug", "fix this error", "why is this broken" | genius-debugger |
| "help me test", "testing session", "manual test" | genius-test-assistant |
| "test the UI", "visual testing", "screenshot test" | genius-ui-tester |

### Growth
| User Says | Route To |
|-----------|----------|
| "SEO", "search ranking", "Google ranking", "keywords" | genius-seo |
| "analytics setup", "tracking", "events", "GA4", "Plausible" | genius-analytics |
| "performance", "speed", "load time", "Core Web Vitals" | genius-performance |
| "accessibility", "a11y", "WCAG", "screen reader" | genius-accessibility |
| "write blog", "content strategy", "article", "newsletter" | genius-content |
| "translate", "localization", "i18n", "multi-language" | genius-i18n |

### Business
| User Says | Route To |
|-----------|----------|
| "crypto", "Web3", "blockchain", "smart contract", "NFT" | genius-crypto |

### Infrastructure
| User Says | Route To |
|-----------|----------|
| "deploy", "go live", "ship it", "production" | genius-deployer |
| "setup CI", "GitHub Actions", "CI pipeline" | genius-ci |
| "schedule a task", "recurring check", "run every X minutes" | genius-scheduler |
| "A/B test", "experiment", "autonomous optimization" | genius-experiments |
| "documentation", "write docs", "README", "API docs" | genius-docs |

### Meta (incl. memory)
| User Says | Route To |
|-----------|----------|
| "remember", "what did we decide", "context", "history" | genius-memory |

---

## Meta Intents (full table)

| User Says | Route To |
|-----------|----------|
| "optimize skills", "update genius team" | genius-team-optimizer |
| "check for updates", "new claude code version" | genius-updater |
| "onboard", "user onboarding", "welcome flow" | genius-onboarding |
| "playground template", "generate playground" | genius-playground-generator |
| "tune auto mode", "make it more permissive" | genius-auto |
| "switch mode", "change to pro", "beginner mode" | /genius-mode command |
| "import project", "add existing project" | /genius-import command |
| "tips", "what else can you do", "show me features" | genius-tips |

---

## Disambiguation Rules (full)

When the user's request is ambiguous or could match multiple skills:

1. **Prefer specificity over generality**: If the request mentions "React component" -> genius-dev-frontend directly
2. **When genuinely ambiguous**: Ask ONE clarifying question
3. **NEVER default to working without a skill** — wrong skill > no skill
4. **Common confusions**:
   - "review" without "PR" -> genius-reviewer. "review PR" -> genius-code-review
   - "copy" for landing page -> genius-copywriter. "blog post" -> genius-content
   - "integrate Stripe" -> genius-dev-api. "Stripe billing" -> genius-dev-backend
   - "analyze the market" -> genius-product-market-analyst (NOT genius-specs)
   - "define the architecture" -> genius-architect
   - "test" / "QA" after full build -> genius-qa. "quick check" -> genius-qa-micro
   - "build login page" -> genius-dev-frontend. "build auth system" -> genius-dev-backend

---

## Memory Triggers

- "Remember that..." / "We decided..." -> `.genius/memory/decisions.json`
- "This broke because..." -> `.genius/memory/errors.json`
- "Pattern: ..." -> `.genius/memory/patterns.json`

---

## Error Recovery (full protocol)

If a routed skill fails:
1. **Retry once** with the same skill
2. If still fails, **fall back to genius-dev** for implementation or **genius-reviewer** for review
3. **Log the failure** in `.genius/errors.log`
4. **Notify user**
5. Never silently swallow errors

---

## Commands / Dashboard / Dual Mode / Workflow Registry

- Commands: `/genius-start`, `/status`, `/continue`, `/reset`, `/update-check`,
  `/genius-dashboard`, `/genius-mode`, `/genius-import`. `STOP` or `PAUSE` halts
  autonomous execution.
- Master Dashboard: mention `.genius/DASHBOARD.html` after skill completion,
  `/genius-start`, `/status`, and checkpoint approvals.
- Dual Mode: `/challenge` and `/genius-switch-engine {dual|claude|codex}` for
  cross-engine workflows.
- Workflow Registry: the full workflow dependency graph is defined in
  `.genius/workflows.json`. Reference it for prerequisites and next-workflow routing.
