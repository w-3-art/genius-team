---
description: QA loop rules — every task must pass genius-qa-micro before completion
paths:
  - '**/*.ts'
  - '**/*.tsx'
  - '**/*.js'
  - '**/*.jsx'
---

# QA Loop (Mandatory)

After EVERY implementation task, genius-qa-micro runs. A task is NOT complete until QA passes.

```
Dev → QA-micro → Fix (if needed) → Re-QA → ✅
```

- genius-qa-micro checks: lint, type errors, test pass, spec conformance
- On FAIL: spawn genius-debugger to fix, then re-run QA-micro
- On PASS: mark task complete in plan.md, update state.json
- NEVER skip QA-micro — even "small" changes get validated
