---
name: genius-designer
description: >-
  Brand and design system creation. Generates design options (colors, typography, layout)
  and produces DESIGN-SYSTEM.html. Use when SPECIFICATIONS.xml exists and user says
  "design the brand", "create design system", "design options", "visual identity", "UI design".
  Do NOT use for CSS implementation — that's genius-dev-frontend.
context: fork
---

# Genius Designer v10.0 — Visual Identity Creator

**Crafting your brand's visual language through interactive exploration.**
Full playground spec, JSON shapes, and templates: `references/design-details.md`.

## 🚨 CRITICAL: NEVER PRESENT DESIGN OPTIONS AS TEXT

You MUST generate an **interactive HTML file** to present design options. The user CANNOT
see colors from hex codes in chat. The FIRST thing after deciding on 3 options:
1. Write `.genius/outputs/design-playground.html`
2. Tell the user: "Open the playground to see and compare the 3 options live:"
3. `open .genius/outputs/design-playground.html`

Presenting options as text instead of HTML = **you have failed this skill**.

## ⚠️ Mandatory Artifacts

1. **Interactive playground HTML** `.genius/outputs/design-playground.html` — PRIMARY
   OUTPUT. Self-contained, dark bg, 3 options with live swatches, real font samples,
   button examples, mini mockup. Full spec: `references/design-details.md`
   § Playground HTML Requirements.
2. **Config** `.genius/design-config.json`
3. **Unified state** `.genius/outputs/state.json` (`phases.design` populated — field
   shapes: `references/design-details.md` § Unified Dashboard Integration)

**Before transitioning:** playground HTML exists and was announced, design-config.json
exists, state.json design phase complete, user has CHOSEN an option. If playground HTML
is missing → DO NOT proceed, generate it first.

## Prerequisites

**REQUIRED:** `SPECIFICATIONS.xml` from genius-specs (approved)

## Memory Integration

Read `@.genius/memory/BRIEFING.md` at session start. Append design decisions and the
final "DESIGN SYSTEM COMPLETE" entry to `.genius/memory/decisions.json` (JSON shapes:
`references/design-details.md` § Memory Integration).

## Design Process

1. **Analyze Context** — project type, target audience, brand constraints, industry standards
2. **Prepare 2-3 Custom Presets** — tailored to the project's needs
3. **Generate Interactive Playground** — presets injected, live preview
4. **User Exploration** — user tweaks colors, typography, spacing, shadows in real time
5. **Export & Validate** — user copies their chosen configuration
6. **Save Configuration** — store to `design-config.json`

Playground controls, preset field list (`phases.design.data.presets`), and the MANDATORY
`playgrounds/templates/design-tokens.css` token spec: `references/design-details.md`
§ Playground Controls. Do NOT create separate HTML files beyond the playground — the
unified dashboard reads from state.json.

## Design System Components

- **Design tokens**: colors, spacing, typography, radius, shadows
- **Component states**: default, hover, focus, active, disabled, loading, error
- **Responsive breakpoints**: mobile-first approach
- **Accessibility**: WCAG AA compliant (4.5:1 contrast, 44×44px touch targets)

## CHECKPOINT: User Exploration Required

**MANDATORY. Do NOT continue automatically.** Announce the 3 design directions, what the
user can tweak in the dashboard, and ask them to paste the exported "Prompt" output back.
Exact message template: `references/design-details.md` § Checkpoint Message Template.

## After User Validates

1. **Parse the exported prompt** — extract colors, typography, spacing, radius, shadows
2. **Save to `design-config.json`** (schema: `references/design-details.md`
   § design-config.json Schema)
3. **Log decision** to `.genius/memory/decisions.json`
4. **Handoff to genius-marketer**

## Output Files

- `.genius/outputs/state.json` for unified design phase state
- `.genius/design-config.json` for validated design tokens

## Post-Output: Refresh Dashboard

Regenerate `.genius/DASHBOARD.html` via `.claude/commands/genius-dashboard.md` and surface its path to the user.

## Handoffs

- **From genius-specs**: SPECIFICATIONS.xml (approved), screen definitions, target audience
- **To genius-marketer**: DESIGN-SYSTEM.html, design-config.json, brand personality
- **To genius-dev** (later): design-config.json (Tailwind or CSS variables ready)

## Next Step (Auto-Chain)

On completion → suggest: "Design system created! Ready for marketing strategy?
(CHECKPOINT: choose design option first) I'll hand off to **genius-marketer**."
If user approves: route to genius-marketer, update state.json `currentSkill = "genius-marketer"`.

## Definition of Done

- [ ] Design system tokens defined (colors, typography, spacing)
- [ ] 3 design options (A/B/C) presented with trade-offs
- [ ] User selected preferred option at checkpoint
- [ ] Design decisions logged in `.genius/memory/decisions.json`
- [ ] Responsive breakpoints defined (mobile, tablet, desktop)
