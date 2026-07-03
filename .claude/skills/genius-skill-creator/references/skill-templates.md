# genius-skill-creator — Templates & Examples (progressive disclosure)

Loaded on demand from `SKILL.md`. Contains the analysis commands, frontmatter and
body templates, directory scaffolding commands, CLAUDE.md registration steps, and a
concrete example. `SKILL.md` keeps the workflow and validation checklist.

---

## Workflow Analysis Commands (Step 1)

```bash
# Read existing skills for patterns
ls .claude/skills/
cat .claude/skills/*/SKILL.md | grep -A3 "^## "  # Scan section headers

# Check CLAUDE.md for existing skill references
grep -i "skill\|when.*use\|invoke" CLAUDE.md

# Look for repeated patterns in recent work
git log --oneline -20
```

---

## Frontmatter Template (Step 2)

Follow the Anthropic Claude Code skill specification exactly:

```yaml
---
name: genius-{kebab-case-name}           # Always genius- prefix for Genius Team skills
description: >-
  [ONE SENTENCE WHAT IT DOES]. Use when [TRIGGER PHRASES/CONDITIONS].
  Do NOT use for [ANTI-TRIGGERS — what it should NOT handle].
context: fork                             # fork = isolated agent context
agent: genius-{kebab-case-name}          # matches name
user-invocable: true                     # true if user can directly invoke; false if orchestrator-only
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Glob(*)
  - Grep(*)
  - Bash(npm *)                          # only include tools the skill actually needs
hooks:
  PostToolUse:
    - type: command
      command: "bash -c 'echo \"[$(date +%H:%M:%S)] {SKILLNAME}: $TOOL_NAME\" >> .genius/{name}.log 2>/dev/null || true'"
  Stop:
    - type: command
      command: "bash -c 'echo \"{SKILLNAME} COMPLETE: $(date)\" >> .genius/{name}.log 2>/dev/null || true'"
      once: true
---
```

---

## SKILL.md Body Template (Step 3)

Follow **progressive disclosure** — most important info first, details later.

```markdown
---
[frontmatter]
---

# {Skill Name} v22 — {Tagline}

**{One powerful sentence describing the skill's value.}**

---

## Mode Compatibility

| Mode | Behavior |
|------|----------|
| **CLI** | [how it runs in terminal] |
| **IDE** | [how it runs in VS Code/Cursor] |
| **Omni** | [multi-provider behavior] |
| **Dual** | [Claude+Codex split] |

---

## Core Principles

1. **[Principle 1]**: [brief explanation]
2. **[Principle 2]**: [brief explanation]
3. **[Principle 3]**: [brief explanation]

---

## [Main Section 1]

[Content — code examples, commands, patterns]

---

## [Main Section 2]

[Content]

---

## Output

Update `.genius/outputs/state.json` on completion:
\`\`\`bash
jq --arg ts "$(date -Iseconds)" '.skill = "genius-{name}" | .status = "complete" | .updatedAt = $ts' .genius/outputs/state.json > .genius/outputs/state.json.tmp && mv .genius/outputs/state.json.tmp .genius/outputs/state.json 2>/dev/null || true
\`\`\`

---

## Handoff

- → **[other-skill]**: [when/why to hand off]
```

**Constraints**: keep it concise, runnable, and purpose-driven.

---

## Directory Scaffolding (Step 4)

```bash
SKILL_NAME="genius-my-skill"
SKILL_DIR=".claude/skills/${SKILL_NAME}"

mkdir -p "${SKILL_DIR}"
mkdir -p "${SKILL_DIR}/references"  # For supporting docs, templates, examples

# Create the SKILL.md
# Write the drafted content to SKILL_DIR/SKILL.md

# Optionally add reference files
# cp some-template.md "${SKILL_DIR}/references/template.md"
```

Directory structure:
```
.claude/skills/genius-my-skill/
├── SKILL.md              # Required — the skill definition
└── references/           # Optional — supporting files
    ├── template.md       # Reusable templates
    ├── examples.md       # Example outputs
    └── checklist.md      # Validation checklists
```

---

## CLAUDE.md Registration (Step 5)

After creating the skill, update `CLAUDE.md` to mention it:

```bash
# Find the skills section in CLAUDE.md
grep -n "skills\|Skills\|## " CLAUDE.md | head -20
```

Add an entry like:
```markdown
## Project Skills

- **genius-my-skill**: [One line description]. Invoke when [trigger].
```

---

## Concrete Example

Use a short, project-specific skill such as `genius-stripe-payments` when a payment workflow repeats often.

Example frontmatter:
```yaml
name: genius-stripe-payments
description: >-
  Stripe payment integration skill. Use when work involves "add Stripe",
  "subscription billing", or "checkout flow". Do NOT use for other providers.
```

Reference file `.claude/skills/genius-stripe-payments/references/setup-checklist.md`:
```markdown
# Stripe Setup Checklist
- [ ] STRIPE_SECRET_KEY in .env
- [ ] STRIPE_PUBLISHABLE_KEY in .env
- [ ] STRIPE_WEBHOOK_SECRET in .env
- [ ] Webhook endpoint registered in Stripe dashboard
- [ ] Products/prices created in Stripe dashboard
```
