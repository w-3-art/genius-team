---
name: genius-auto
description: >-
  Configures Claude Code Auto Mode safety rules per skill type. Sets up automatic approval
  policies for safe actions while keeping destructive operations gated. Use when user says
  "configure auto mode", "setup auto approve", "auto mode settings", "automatic permissions",
  "hands-free mode", "unattended mode".
  Do NOT use for CI/CD pipelines (use genius-ci).
  Do NOT use for scheduled tasks (use genius-scheduler).
  Do NOT use for deployment (use genius-deployer).
context: fork
agent: genius-auto
user-invocable: false
allowed-tools:
  - Read(*)
  - Glob(*)
  - Grep(*)
  - Write(*)
  - Edit(*)
  - Bash(jq *)
  - Bash(cat *)
---

# Genius Auto v20.0 — Auto Mode Configuration

**Configures Claude Code Auto Mode with skill-aware safety policies. Safe actions auto-approve, dangerous ones stay gated.**

## Memory Integration

### On Start
Read `@.genius/memory/BRIEFING.md` for project context and current mode.

### On Configuration Complete
Append to `.genius/memory/decisions.json`:
```json
{"id": "d-XXX", "decision": "AUTO-MODE: configured [profile] for [mode]", "reason": "[rationale]", "timestamp": "ISO-date", "tags": ["auto-mode", "configuration"]}
```

---

## Safety Profiles

Each Genius Team skill type gets a safety profile controlling what Auto Mode can approve without human confirmation.

### Profile: Permissive (Content & Analysis Skills)
**Skills:** genius-interviewer, genius-specs, genius-marketer, genius-copywriter, genius-content, genius-docs, genius-product-market-analyst
Auto-approve: File reads, searches, glob, writing to `.genius/` outputs, markdown/XML artifacts, web searches/fetches.
Require approval: Writing to `src/`, git operations, build/deploy commands.

### Profile: Standard (Development Skills)
**Skills:** genius-dev, genius-dev-frontend, genius-dev-backend, genius-dev-mobile, genius-dev-database, genius-dev-api, genius-architect, genius-designer
Auto-approve: File reads/writes, lint/typecheck/test, npm install, git add/commit.
Require approval: Git push/force, deploy commands, CI/CD config changes, production DB migrations.

### Profile: Restrictive (Infrastructure Skills)
**Skills:** genius-deployer, genius-security, genius-ci
Auto-approve: File reads, `.genius/` outputs, dry-run commands.
Require approval: ALL deployment, production DB, git push, env vars, secrets.

### Profile: Monitor (QA & Review Skills)
**Skills:** genius-qa, genius-qa-micro, genius-reviewer, genius-code-review
Auto-approve: File reads, test suites, lint/typecheck, reports to `.genius/`.
Require approval: Code modifications, git operations.

---

## Configuration Protocol

1. Detect current mode from configs/
2. Generate `.genius/auto-mode.json` with per-skill rules and global deny list
3. Update settings.json with conditional hooks (`if` field)
4. Present to user for approval before activation

---

## Handoffs

### From genius-start
Receives: Mode detection, initial setup request

### To genius-orchestrator
Provides: Auto mode config applied, ready for unattended execution

---

## Definition of Done

- [ ] Current mode detected from configs/
- [ ] Safety profiles assigned to all active skills
- [ ] `.genius/auto-mode.json` generated with per-skill rules
- [ ] Global deny list includes all destructive operations
- [ ] User approved the configuration before activation
- [ ] settings.json updated with conditional hooks (if approved)
