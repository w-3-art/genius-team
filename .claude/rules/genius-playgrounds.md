---
description: Playground generation rules — every skill output needs an interactive HTML playground
paths:
  - '.genius/outputs/**'
  - 'playgrounds/**'
---

# Playground Rules — MANDATORY

After EVERY skill that produces output, generate an interactive HTML playground.

- Self-contained HTML file: dark theme (#0F0F0F), zero external dependencies, interactive
- After generating: tell user `open .genius/outputs/<name>-playground.html`
- Also update the unified dashboard tab in `.genius/DASHBOARD.html`

## Required Playgrounds by Skill

| Skill | File |
|-------|------|
| genius-specs | `specs-playground.html` |
| genius-designer | `design-playground.html` |
| genius-architect | `architecture-playground.html` |
| genius-marketer | `marketing-playground.html` |
| genius-dev | `dev-playground.html` |
| genius-seo | `seo-playground.html` |
| genius-deployer | `deploy-playground.html` |
