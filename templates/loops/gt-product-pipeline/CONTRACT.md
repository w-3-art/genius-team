# Loop Contract: GT product pipeline (Interview → Specs → Architecture → Dev → Review → Deploy)

<!-- LP-09 workflow-loop contract TEMPLATE (LP-02 format + ## Workflow table).
     Copy to .genius/loops/gt-product-pipeline/CONTRACT.md, adapt the gates to
     the project (dev gate = YOUR test command), get HUMAN approval, then run
     it with the genius-workflow-loop skill. Validated by
     `bash scripts/loop-kernel.sh contract_validate <loop_dir>`. -->

- slug: gt-product-pipeline
- created: 2026-07-05
- author: human
- autonomy_level: L2   # every new loop starts L1/L2 (genius-auto Autonomy Ladder). At L1/L2 EVERY step below is a human checkpoint. Promotion to L3 (auto-advance through checkpoint=auto steps) requires a week of read/approved runs — "level four is earned, not assumed."

## Goal (stopping condition — a contract, not "make it better")
Every step of the product pipeline has passed its deterministic gate and every
human checkpoint has an explicit recorded approval; the workflow STATE is `done`.

## Gate (objective pass/fail — the ONLY measure of done)
```bash
bash scripts/guard-validate.sh
```
- Interpretation: PASS when exit code == 0 (final/global gate — mirrors the last workflow step).
- Timeout: 300s — exceeding it counts as FAIL (silent-death guard). Applies to every step gate below.

## Workflow (step gates — the existing guard/review IS the gate)
<!-- Rules: one row per step, executed top to bottom. Gate cells must be a real
     command WITHOUT a literal `|` (wrap complex gates in a script, like
     scripts/review-gate.sh). checkpoint=human HALTs after the step's gate
     passes until `workflow_approve` records a per-step approval. -->

| step | gate | checkpoint |
|---|---|---|
| interview | test -s DISCOVERY.xml | auto |
| specs | bash scripts/validate-spec.sh | human |
| architecture | bash scripts/validate-architecture.sh | human |
| dev | npm test | auto |
| review | bash scripts/review-gate.sh | human |
| deploy | bash scripts/guard-validate.sh | human |

<!-- Checkpoint map (consistent with the 3 existing GT checkpoints + the L3
     boundaries of GUARD-POLICY.md §6):
     - specs (human)        = existing checkpoint 1 "After Specs".
     - architecture (human) = existing checkpoint 3 "After Architect". If your
       pipeline runs the full ideation chain with genius-designer, insert a row
       `| design | test -s design-config.json | human |` after specs
       (= existing checkpoint 2 "After Designer").
     - review (human)       = L3 boundary BEFORE DEPLOY: a human reads the review
       packet before anything ships. Never bypassable, even at L4.
     - deploy (human)       = L3 boundary BEFORE PUSH/PUBLISH/RELEASE: final
       human-read gate; the P4-08 boundary hooks (genius-guard-boundary.sh)
       enforce the same frontier independently. -->

## Proof of completion (defined BEFORE work; immutable)
STATE.md shows `status: done` with `last_gate_exit: 0`, one approval file per
human checkpoint exists under `.genius/loops/gt-product-pipeline/approvals/`,
and `loop_report` shows every step crossed via its gate (no self-declared pass).

## Blast radius (do-not-touch boundary)
- allowed_files:
  - DISCOVERY.xml
  - SPECIFICATIONS.xml
  - ARCHITECTURE.md
  - src/**
  - tests/**
  - .genius/loops/gt-product-pipeline/**
- allowed_commands:
  - bash scripts/loop-kernel.sh
  - bash scripts/validate-spec.sh
  - bash scripts/validate-architecture.sh
  - bash scripts/review-gate.sh
  - bash scripts/guard-validate.sh
  - npm test
- forbidden: everything not listed above (no pushes, no publish, no unrelated refactors).

## Brakes (hard caps)
- max_iterations: 24
- token_budget: 500k   # REQUIRED — Cortex refuses to register a loop without it (no budget, no loop)
- token_per_iteration: 25k   # worst-case shown by Cortex = token_per_iteration × max_iterations
- no_progress_after: 3 iterations with no change in gate result → HALT+report
- flip_flop: HALT if any file oscillates between two states across iterations

## Checker (separate from maker)
genius-code-review (multi-agent, read-only) counter-verifies the dev/review steps;
its verdict is what scripts/review-gate.sh gates on. The skill that produced a
change never signs off on it.

## State
- path: .genius/loops/gt-product-pipeline/STATE.md
- protocol: read at run start, write at run end (done | in-progress | blocked | next);
  the kernel tracks `step:` and `awaiting:` metadata for the workflow position.

## Budget
- max_wall_time: 4h
- max_iterations: 24   # mirrors brakes
