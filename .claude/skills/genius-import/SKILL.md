---
name: genius-import
description: >-
  Import an existing project into Genius Team. Scans repo structure, generates draft brief,
  architecture snapshot, and initializes all .genius/ files (state.json, mode.json, workflows.json).
  Use when user says "import this project", "add genius team to this project", "genius import",
  or when /genius-start detects a project without .genius/ directory.
  Do NOT use for new projects (use genius-interviewer).
user-invocable: true
context: fork
---

# Genius Import — Adopt Existing Projects

**Scan any codebase and bring it into Genius Team, no matter what stage it's at.**

## What It Does

1. **Scans** the repo: package.json, file structure, README, git history, existing docs
2. **Generates** a draft project brief based on what it finds
3. **Creates** architecture snapshot from the actual code structure
4. **Produces** a "what's missing" report (no specs? no tests? no docs?)
5. **Initializes** all .genius/ files:
   - `state.json` — set to the correct phase based on existing artifacts
   - `mode.json` — ask user or default to builder
   - `workflows.json` — standard registry
   - `memory/BRIEFING.md` — generated from scan results

## Migration Logic

Detect existing artifacts and set state accordingly:
- Has DISCOVERY.xml → phase: spec_ready
- Has SPECIFICATIONS.xml → phase: design_ready  
- Has ARCHITECTURE.md → phase: arch_ready
- Has .claude/plan.md with tasks → phase: execution
- Has none of these → phase: init (fresh start)

Set `origin: "imported"` in state.json — validators will WARN instead of BLOCK.

## Rules
- NEVER delete existing files
- NEVER overwrite existing .genius/ files without asking
- Always show the draft brief and ask for confirmation
- If unsure about the phase, ASK the user
