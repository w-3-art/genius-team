---
name: genius-code-review
description: >-
  Multi-agent PR code review. Dispatches 3 parallel reviewers: bugs finder, security
  auditor, and code quality reviewer. Produces a single consolidated review report.
  Inspired by Anthropic's Code Review system (84% bug detection on large PRs).
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

# Genius Code Review v17 — Multi-Agent PR Reviewer

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

In Claude Code Agent Teams (multi-agent mode), spawn all 3 simultaneously:

### Reviewer 1: Bug Finder

**Focus**: Logic errors, incorrect assumptions, edge cases, null/undefined handling, race conditions, data corruption risks.

Review checklist:
- [ ] Off-by-one errors in loops, array access, pagination
- [ ] Null / undefined dereference (missing guards)
- [ ] Race conditions (concurrent writes, missing locks)
- [ ] Incorrect error handling (errors swallowed silently)
- [ ] Wrong HTTP status codes or API responses
- [ ] State mutation bugs (shared mutable state, stale closures)
- [ ] Async/await misuse (missing await, unhandled promise rejections)
- [ ] Data type mismatches (string vs number, timestamps vs strings)
- [ ] Boundary conditions (empty arrays, empty strings, zero values)
- [ ] Infinite loops or recursion without proper termination

Output format: `BUGS.md` with severity + line reference + explanation + fix suggestion.

### Reviewer 2: Security Scanner

**Focus**: Vulnerabilities, exposed secrets, injection vectors, auth flaws, insecure data handling.

Review checklist:
- [ ] SQL injection (raw queries, unparameterized inputs)
- [ ] XSS vulnerabilities (unescaped user content in HTML)
- [ ] Hardcoded secrets, API keys, passwords in code
- [ ] Missing authentication/authorization checks
- [ ] Insecure direct object references (IDOR)
- [ ] Missing input validation and sanitization
- [ ] Insecure deserialization
- [ ] Path traversal vulnerabilities
- [ ] Missing HTTPS enforcement
- [ ] Overly permissive CORS configuration
- [ ] Sensitive data logged (PII, tokens in logs)
- [ ] Missing rate limiting on auth endpoints
- [ ] Weak cryptography (MD5, SHA1 for passwords)
- [ ] Missing webhook signature verification

Output format: `SECURITY.md` with OWASP category + severity + file:line + remediation.

### Reviewer 3: Code Quality Reviewer

**Focus**: Maintainability, readability, design patterns, performance, test coverage gaps.

Review checklist:
- [ ] Code duplication (DRY violations)
- [ ] Functions/methods that do too much (SRP)
- [ ] Missing or inadequate test coverage for new code
- [ ] Poor naming (unclear variable/function names)
- [ ] Magic numbers/strings (should be named constants)
- [ ] Complex conditionals that could be simplified
- [ ] Performance issues (N+1 queries, missing indexes, large data in memory)
- [ ] Missing error handling in happy-path code
- [ ] Inconsistent code style with the rest of the codebase
- [ ] Dead code (unreachable code, unused imports)
- [ ] Missing documentation for complex logic
- [ ] API breaking changes without versioning

Output format: `QUALITY.md` with category + impact + file:line + suggestion.

---

## Step 3: Consolidate into Final Report

Merge all three reviewer outputs into a single ranked report:

```markdown
# Code Review Report
**PR**: [branch name or PR title]
**Date**: [date]
**Files changed**: X | **Lines added**: +Y | **Lines removed**: -Z

---

## 🔴 CRITICAL
Issues that must be fixed before merge.

### [C1] SQL Injection in user search endpoint
- **File**: `src/api/users.ts:47`
- **Reviewer**: Security Scanner
- **Category**: OWASP A03:2021 Injection
- **Issue**: Raw string interpolation in SQL query: `db.query(\`SELECT * FROM users WHERE name = '${name}'\`)`
- **Fix**: Use parameterized queries: `db.query('SELECT * FROM users WHERE name = $1', [name])`

---

## 🟠 HIGH
Significant bugs or security issues that should be fixed.

### [H1] Missing null check causes crash on empty cart
- **File**: `src/checkout/cart.ts:23`
- **Reviewer**: Bug Finder
- **Issue**: `cart.items[0].price` throws when cart is empty
- **Fix**: Add guard: `if (!cart.items.length) return 0;`

---

## 🟡 MEDIUM
Issues that affect quality or introduce technical debt.

---

## 🟢 LOW
Minor improvements, style suggestions, documentation gaps.

---

## Summary

| Severity | Count | Must Fix Before Merge |
|----------|-------|----------------------|
| 🔴 CRITICAL | X | Yes |
| 🟠 HIGH | X | Recommended |
| 🟡 MEDIUM | X | Optional |
| 🟢 LOW | X | Optional |

**Verdict**: ✅ Approved / ⚠️ Approved with changes / ❌ Changes required
```

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

When not running in Agent Teams mode, perform all 3 reviews sequentially:
1. First pass: bugs (read diff with bug-finder mindset)
2. Second pass: security (re-read with attacker mindset)
3. Third pass: quality (re-read with maintainer mindset)
4. Consolidate findings into the standard report format

This is slower but still far better than a single-pass review.

---

## Output

Update `.genius/outputs/state.json` on completion:

```bash
jq --arg ts "$(date -Iseconds)" '.skill = "genius-code-review" | .status = "complete" | .updatedAt = $ts' .genius/outputs/state.json > .genius/outputs/state.json.tmp && mv .genius/outputs/state.json.tmp .genius/outputs/state.json 2>/dev/null || true
```

---

## Handoff

- → **genius-security**: Deep security audit if CRITICAL issues found
- → **genius-qa-micro**: Generate tests to cover bug scenarios found
- → **genius-reviewer**: Ongoing code quality coaching (non-PR specific)

---

## Playground Update (MANDATORY)

After completing your task:
1. **DO NOT create a new HTML file** — update the existing genius-dashboard tab
2. Open `.genius/DASHBOARD.html` and update YOUR tab's data section with real project data
3. If your tab doesn't exist yet, add it to the dashboard (hidden tabs become visible on first real data)
4. Remove any mock/placeholder data from your tab
5. Tell the user: `📊 Dashboard updated → open .genius/DASHBOARD.html`


---

## Output Quality Requirements

The review report MUST include for EVERY issue found:
1. **File + line number**: e.g., `src/auth.js:42`
2. **Severity**: Critical (blocks deploy) / High (should fix) / Medium (should fix) / Low (optional)
3. **Category**: Bug / Security / Performance / Maintainability / Style
4. **Description**: What is wrong and why it matters
5. **Fix**: Exact code example showing the corrected version

Summary section must include: total issues by severity, overall assessment, go/no-go recommendation.

If 0 issues found: provide positive confirmation with specific strengths observed.

## Definition of Done

- [ ] Review covers changed files and user-stated scope
- [ ] Findings include file references, severity, and actionable fixes
- [ ] Security, regression, and test gaps evaluated where relevant
- [ ] Overall go/no-go recommendation is explicit
- [ ] Dashboard tab or status output updated if the workflow expects it
