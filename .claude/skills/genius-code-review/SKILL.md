---
name: genius-code-review
description: >-
  Multi-agent PR code review. Dispatches 3 parallel reviewers: bugs finder, security
  auditor, and code quality reviewer. Produces a single consolidated review report.
  Inspired by Anthropic's Code Review system (84% bug detection on large PRs).
  Also the end-of-loop adversarial CHECKER of the build-test-fix pair (maker ≠ checker):
  genius-orchestrator dispatches it after the objective gate passes, before advancing to the
  next task.
  Use when user says "review this PR", "code review", "review pull request",
  "audit the code changes", "multi-agent review".
  Do NOT use for general code quality suggestions — use genius-reviewer for that.
context: fork
agent: genius-code-review
user-invocable: true
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Glob(*)
  - Grep(*)
  - Bash(git diff*)
  - Bash(git status*)
  - Bash(git log*)
  - Bash(git show*)
hooks:
  PostToolUse:
    - type: command
      command: "bash -c 'echo \"[$(date +%H:%M:%S)] CODE-REVIEW: $TOOL_NAME\" >> .genius/review.log 2>/dev/null || true'"
  Stop:
    - type: command
      command: "bash -c 'echo \"CODE-REVIEW COMPLETE: $(date)\" >> .genius/review.log 2>/dev/null || true'"
      once: true
---

# Genius Code Review v22 — Multi-Agent PR Reviewer

**Three reviewers. One report. Zero bugs missed.**

Inspired by Anthropic's multi-agent code review research showing **84% bug detection** on large PRs — versus ~20% for single-pass review.

---

## Mode Compatibility

| Mode | Behavior |
|------|----------|
| **CLI** | Full parallel review; diff extracted via `git diff`; report written to `.genius/reviews/` |
| **IDE** (VS Code/Cursor) | Same as CLI; open report in editor panel after completion |
| **Omni** | Each reviewer agent uses the best available model for its specialty |
| **Dual** | Claude leads bugs + security; Codex handles code quality patterns review |

---

## Architecture: 3 Parallel Reviewers

```
                  ┌─────────────────────┐
                  │   genius-code-review │
                  │   (orchestrator)     │
                  └──────────┬──────────┘
                             │ dispatch in parallel
           ┌─────────────────┼─────────────────┐
           ▼                 ▼                 ▼
    ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐
    │ bugs-finder │  │  security-   │  │ quality-reviewer │
    │             │  │  scanner     │  │                  │
    └──────┬──────┘  └──────┬───────┘  └────────┬────────┘
           └────────────────┼──────────────────┘
                            │ merge findings
                    ┌───────▼──────────┐
                    │ Consolidated     │
                    │ Review Report    │
                    └──────────────────┘
```

---

## Step 1: Get the Diff

```bash
# PR diff (against main)
git diff main...HEAD > /tmp/pr.diff

# Or specific commit
git show <commit-sha> > /tmp/pr.diff

# Or staged changes
git diff --staged > /tmp/pr.diff

# Stats overview
git diff main...HEAD --stat
```

Read the diff to understand scope: files changed, lines added/removed, nature of changes.

---

## Step 2: Dispatch 3 Reviewers in Parallel

In Agent Teams mode, spawn all 3 simultaneously:

**Reviewer 1 — Bug Finder**: Logic errors, edge cases, null handling, race conditions, async misuse, boundary conditions, type mismatches, error handling. Output: `BUGS.md` (severity + file:line + explanation + fix).

**Reviewer 2 — Security Scanner**: SQL injection, XSS, hardcoded secrets, missing auth, IDOR, input validation, path traversal, CORS, rate limiting, weak crypto, webhook verification. Output: `SECURITY.md` (OWASP category + severity + file:line + remediation).

**Reviewer 3 — Code Quality**: DRY violations, SRP, test coverage, naming, magic numbers, complexity, N+1 queries, dead code, missing docs, breaking changes. Output: `QUALITY.md` (category + impact + file:line + suggestion).

---

## Step 3: Consolidate into Final Report

Merge all three reviewer outputs into a ranked report with these sections:
- Header: PR name, date, files/lines changed
- **🔴 CRITICAL** — must fix before merge (each: `[C1]` ID, file:line, reviewer, category, issue, fix)
- **🟠 HIGH** — significant bugs/security (same format with `[H1]` IDs)
- **🟡 MEDIUM** — quality/tech debt issues
- **🟢 LOW** — minor improvements, style, docs
- **Summary table**: severity × count × must-fix-before-merge
- **Verdict**: ✅ Approved / ⚠️ Approved with changes / ❌ Changes required

---

## Step 4: Save and Deliver Report

```bash
# Save report
mkdir -p .genius/reviews
REPORT_PATH=".genius/reviews/review-$(date +%Y%m%d-%H%M%S).md"
# Write consolidated report to $REPORT_PATH

echo "Review saved: $REPORT_PATH"
cat $REPORT_PATH
```

---

## CLI / Non-Multi-Agent Mode

Without Agent Teams, run three sequential passes: bugs, security, and maintainability. Consolidate them into the standard report format.

---

## Output

Mark `.genius/outputs/state.json` complete for `genius-code-review` with a fresh timestamp.

---

## Role: end-of-loop adversarial checker (build-test-fix)

In the orchestrator's build-test-fix pair, a green gate from genius-qa-micro is necessary but
**not sufficient** — a passing test suite can still ship the wrong change. This skill is the
independent checker that runs AFTER the gate passes and BEFORE the task is marked done. Maker
(genius-dev) and checker (this skill) are deliberately separate.

- Review only the loop's diff (`git diff` of the task's changes), adversarially: does the
  change actually satisfy the task, within its blast radius, without new bugs/security holes?
- Emit an explicit verdict the orchestrator can branch on:
  **✅ Approved** → task advances to `[x]`.
  **⚠️ Approved with changes** / **❌ Changes required** → back to genius-dev inside the loop
  budget; if the cap is hit while still rejected, the orchestrator HALTs and reports to the Lead.
- Stay read-only on source (diff + report only). Never "fix and pass" — that would collapse
  maker and checker back into one.

---

## Handoff

- → **genius-orchestrator**: verdict (approve / changes-required) gates task completion in the loop
- → **genius-security**: Deep security audit if CRITICAL issues found
- → **genius-qa-micro**: Generate tests to cover bug scenarios found
- → **genius-reviewer**: Ongoing code quality coaching (non-PR specific)

---

## Playground Update

Refresh the existing dashboard tab with real review data and tell the user to open `.genius/DASHBOARD.html`.


---

## Output Quality Requirements

Every issue must include file:line, severity, category, description, and a concrete fix. The summary must include counts by severity, an overall assessment, and a go/no-go call. If no issues are found, say so and name the observed strengths.

## Definition of Done

- [ ] Review covers changed files and user-stated scope
- [ ] Findings include file references, severity, and actionable fixes
- [ ] Security, regression, and test gaps evaluated where relevant
- [ ] Overall go/no-go recommendation is explicit
- [ ] Dashboard tab or status output updated if the workflow expects it
