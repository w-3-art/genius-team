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
