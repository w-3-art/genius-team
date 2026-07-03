---
name: genius-playground-generator
description: >-
  Generates context-aware HTML playgrounds tailored to the specific project.
  Reads project data from .genius/ outputs and specifications to create a
  custom interactive dashboard — not a generic template but a project-specific
  visualization tool. Use when user says "generate playground", "create dashboard",
  "visualize my project", "project playground", "custom dashboard for my project".
  Also automatically suggested after each major skill completes.
  Do NOT use for static template browsing — use /genius-dashboard for that.
context: fork
agent: genius-playground-generator
user-invocable: true
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Glob(*)
  - Grep(*)
  - Bash(cat *)
  - Bash(jq *)
  - Bash(find *)
  - Bash(ls *)
hooks:
  Stop:
    - type: command
      command: "bash -c 'echo \"PLAYGROUND GENERATED: $(date)\" >> .genius/playground.log 2>/dev/null || true'"
      once: true
---

# Genius Playground Generator v22 — Context-Aware Dashboards

**Not templates. Real project data. Real insights.**
Discovery commands, dashboard section spec, HTML rules, type-specific specs:
`references/playground-details.md`.

Static templates show fake data. This skill reads YOUR project's actual data — real app
name (SPECIFICATIONS.xml / state.json), actual tech stack (ARCHITECTURE.md), real market
data (MARKET-ANALYSIS.xml), actual skill outputs (.genius/outputs/) — and generates an
HTML file 100% specific to the project.

## Data Discovery Protocol

**Step 1 — Identify available data sources**: state.json (project/phase/skills run),
`.genius/outputs/`, `*.xml` specs, ARCHITECTURE.md. Exact commands:
`references/playground-details.md` § Data Discovery Commands.

**Step 2 — Determine playground type from data available:**

| Data found | Playground to generate |
|-----------|----------------------|
| SPECIFICATIONS.xml + ARCHITECTURE.md | Project Overview Dashboard |
| MARKET-ANALYSIS.xml | Market Research Dashboard |
| .genius/seo-report.md | Live SEO/GEO Dashboard |
| .genius/outputs/state.json with dev phase | Development Progress Dashboard |
| .genius/experiments/ | Experiments Results Dashboard |
| Multiple sources | Master Project Dashboard (aggregates all) |

**Step 3 — Extract real data**: project name, description, tech stack, phase completion,
key metrics/decisions/risks, actual URLs/APIs/services.

## Generation Protocol

Master Project Dashboard (most common) → `.genius/outputs/PROJECT-DASHBOARD.html` with 8
required sections: header, phase progress bar, tech stack card, market intelligence,
specifications summary, development progress, memory log (last 5), quick actions. Full
section spec: `references/playground-details.md` § Master Project Dashboard.

Type-specific variants (SEO-DASHBOARD.html, DEV-PROGRESS.html, EXPERIMENTS.html — always
real data from the source files): § Specific Playground Types.

## HTML Generation Rules (essentials)

- Single HTML file, zero external dependencies; design tokens ALWAYS included
  (`playgrounds/templates/design-tokens.css` link, or inline `<style>` when generated in
  the project) and used for ALL colors via CSS variables
- Dark mode default, responsive, print-friendly, aria-labels + contrast ≥ 4.5:1,
  auto-refresh every 30s
- **NEVER placeholder text** ("Project Name", "Your App") — always real data, embedded as
  JS constants

Full rules + data injection pattern: `references/playground-details.md`
§ HTML Generation Rules.

## Output

1. Save to `.genius/outputs/PROJECT-DASHBOARD.html` (master) or type-specific name
2. Print the file path and size
3. Update `.genius/outputs/state.json` (jq command: `references/playground-details.md`
   § Output Commands)
4. Tell the user the dashboard path and to open it in a browser

Mode compatibility (CLI/IDE/OpenClaw/Codex: file-based output everywhere) and the
suggested-trigger snippet for other skills: § Compatibility, § Suggested trigger.

## Handoff

- → **genius-specs / genius-architect / genius-qa / genius-deployer**: Generate an updated dashboard after major artifacts change
- → **genius-designer**: Revisit the presentation layer if the dashboard needs stronger visual treatment
- → **genius-start**: Surface the latest dashboard path during session resume

## Next Step

Open the generated dashboard, confirm the data reflects the latest project state, and regenerate after the next major artifact change.

## Definition of Done

- [ ] Requested playground HTML is generated at the documented path
- [ ] The file renders current project data, not placeholders
- [ ] Output path and refresh instructions are shown to the user
- [ ] `.genius/outputs/state.json` reflects the generation result
- [ ] Any referenced dashboard remains consistent with the new artifact
