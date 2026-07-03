# Trigger Routing — Regression Baseline (P4-04)

This is a **regression** baseline, not an LLM benchmark. `scripts/trigger-evals.sh`
routes each user phrase in `autoresearch/trigger-evals.jsonl` with a local,
deterministic heuristic (IDF keyword overlap against every `SKILL.md`
description, top-1) and scores how many cases route as expected.

The score is measured once, frozen here, and enforced in CI: the build fails if
the routing score drops **below `baseline − 5`**. It exists to catch description
edits that silently break skill routing (e.g. a new skill whose keywords steal
another skill's phrases), not to grade an LLM.

<!-- FLOOR: 73 -->

## Frozen baseline — 2026-07-03

| Metric | Value |
| --- | --- |
| Skills profiled | 57 |
| Eval cases | 224 (167 should-trigger, 57 should-not) |
| should-trigger passes | 120 / 167 |
| should-not passes | 56 / 57 |
| **Routing score** | **176 / 224 = 78.6%** |
| CI floor (`baseline − 5`) | **73%** |

Re-measure with:

```
scripts/trigger-evals.sh --no-gate
```

## Reading the score

The heuristic is intentionally simple, so the baseline sits at ~79%, not 100%.
The remaining misroutes are genuine, expected collisions between **dispatcher**
skills and their **specialists** — e.g. the single word `"code"` routes to
`genius-architect` rather than `genius-dev`, `"React component"` is absorbed by
the `genius-dev` dispatcher instead of `genius-dev-frontend`, and `"Solidity"`
leans toward `genius-crypto` over `genius-dev-web3`. A real router disambiguates
these through workflow hierarchy and context; this eval deliberately does not,
so that any *further* erosion of routing precision trips the floor.

If a future change legitimately shifts routing, re-run the measurement, update
this table, and move the `<!-- FLOOR: N -->` marker (which the runner and CI
read) to the new `baseline − 5`.
