---
name: genius-skill-creator
description: >-
  Meta-skill that creates project-specific Claude Code skills based on recurring
  workflows discovered during project analysis. Creates a conformant SKILL.md
  following Anthropic's official guide (trigger phrases, progressive disclosure,
  references/ folder). Use when genius-specs or genius-architect identify a
  recurring workflow, or when user says "create a skill for X", "new project skill",
  "make a skill that handles Y". Do NOT use for general implementation tasks.
context: fork
agent: genius-skill-creator
user-invocable: true
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Glob(*)
  - Grep(*)
  - Bash(git diff*)
  - Bash(git status*)
hooks:
  PostToolUse:
    - type: command
      command: "bash -c 'echo \"[$(date +%H:%M:%S)] SKILL-CREATOR: $TOOL_NAME\" >> .genius/skill-creator.log 2>/dev/null || true'"
  Stop:
    - type: command
      command: "bash -c 'echo \"SKILL-CREATOR COMPLETE: $(date)\" >> .genius/skill-creator.log 2>/dev/null || true'"
      once: true
---

# Genius Skill Creator v22 — The Meta-Skill

**Skills that spawn skills. Automate the automator.**
Full templates, scaffolding commands, and a concrete example:
`references/skill-templates.md` (matching § per step).

## When to Create a Skill

Create a skill when you observe:
1. **Repetition**: The same workflow is being performed 3+ times
2. **Complexity**: The workflow has 5+ steps that need orchestration
3. **Specialization**: The workflow requires specific domain knowledge
4. **Handoff**: Multiple agents need to coordinate on this workflow

Examples: "every payment feature does X, Y, Z", "production deploys always take these 8
steps", "DB migrations always follow this exact pattern".

## Workflow

### Step 1 — Understand the workflow

Analyze existing skills, CLAUDE.md references, and recent git history (commands:
§ Workflow Analysis Commands), then answer:
1. **What does it do?** (one sentence, active voice)
2. **What triggers it?** (keywords, phrases, conditions)
3. **What does it NOT do?** (clear boundaries to prevent misuse)
4. **What tools does it need?** (Read, Write, Bash, etc.)
5. **What does it output?** (files, report, code, etc.)
6. **Who calls it?** (user-invocable: true/false)

### Step 2 — Draft the frontmatter

Follow the Anthropic spec exactly (full template: § Frontmatter Template).
**Naming**: kebab-case, `genius-` prefix, descriptive but concise
(`genius-stripe-payments`, `genius-i18n`). **Description**: start with the job, concrete
triggers, anti-triggers, under 3 sentences.

### Step 3 — Write the skill body

**Progressive disclosure** — most important info first, details later. Required sections:
Mode Compatibility table, Core Principles, main content sections, Output (state.json
update command), Handoff. Full body template: § SKILL.md Body Template. Keep it concise,
runnable, purpose-driven.

### Step 4 — Create the directory structure

`.claude/skills/genius-my-skill/` with `SKILL.md` (required) + `references/` (optional:
templates, examples, checklists). Scaffolding commands: § Directory Scaffolding.

### Step 5 — Register in CLAUDE.md

Add a one-line entry under the project skills section: name, description, trigger
(commands + entry format: § CLAUDE.md Registration). Concrete worked example
(`genius-stripe-payments` + its setup checklist): § Concrete Example.

## Validation Checklist

Before finalizing the skill, verify:

- [ ] Frontmatter has valid YAML (starts and ends with `---`)
- [ ] `name` is kebab-case with genius- prefix
- [ ] `description` has WHAT, WHEN (with trigger phrases), and NOT WHEN
- [ ] `allowed-tools` only includes tools the skill actually uses
- [ ] Body has Mode Compatibility table
- [ ] Body has Output section with state.json update command
- [ ] Body has Handoff section
- [ ] Total length < 5000 words
- [ ] CLAUDE.md updated with skill reference

## Output

Update `.genius/outputs/state.json` on completion:

```bash
jq --arg ts "$(date -Iseconds)" '.skill = "genius-skill-creator" | .status = "complete" | .updatedAt = $ts' .genius/outputs/state.json > .genius/outputs/state.json.tmp && mv .genius/outputs/state.json.tmp .genius/outputs/state.json 2>/dev/null || true
```

## Handoff

- → **genius-specs**: When the skill defines a complex workflow that needs formal specification
- → **genius-updater**: When a skill needs to be updated/versioned
- → **genius-orchestrator**: Register new skill in the routing logic

## Definition of Done

- [ ] New or updated skill has valid frontmatter and trigger guidance
- [ ] Required sections are present and internally consistent
- [ ] Referenced files, scripts, and handoffs resolve correctly
- [ ] Skill stays concise enough for practical use
- [ ] Registration or follow-up routing instructions are included
