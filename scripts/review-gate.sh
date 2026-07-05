#!/usr/bin/env bash
# review-gate.sh — LP-09: the existing review IS the gate (review pass = gate crossed).
#
# Deterministic pass/fail wrapper around the genius-code-review /
# genius-reviewer output so a workflow loop step can gate on it:
#   PASS (exit 0)  — the most recent .genius/reviews/review-*.md exists and
#                    contains no blocking verdict (REQUEST_CHANGES / REJECT).
#   FAIL (exit 1)  — no review report yet, or the latest one blocks.
#
# Usage: bash scripts/review-gate.sh [reviews_dir]   (default: .genius/reviews)
# Used as the `review` step gate in the gt-product-pipeline workflow contract
# (templates/loops/gt-product-pipeline/CONTRACT.md, run by genius-workflow-loop).

set -euo pipefail

REVIEWS_DIR="${1:-.genius/reviews}"

latest=$(ls -t "$REVIEWS_DIR"/review-*.md 2>/dev/null | head -1 || true)

if [ -z "$latest" ]; then
  echo "review-gate: FAIL — no review report found in $REVIEWS_DIR (run genius-code-review first)"
  exit 1
fi

if grep -qE 'REQUEST_CHANGES|REJECT' "$latest"; then
  echo "review-gate: FAIL — latest review blocks ($latest contains REQUEST_CHANGES/REJECT)"
  exit 1
fi

echo "review-gate: PASS — latest review approves ($latest)"
exit 0
