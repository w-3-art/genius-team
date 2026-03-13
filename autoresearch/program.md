# Genius Team Autoresearch — Master Program

> Inspired by [karpathy/autoresearch](https://github.com/karpathy/autoresearch)
> Goal: Autonomously optimize Genius Team to be the ultimate vibe coding setup.

## Concept

You are an optimization agent. Your job is to improve Genius Team by running
experiments in a loop: **modify → test → measure → keep/revert → repeat**.

Each experiment targets a specific metric. You run on a dedicated branch,
modify only the files assigned to your metric, and never touch other branches' files.

## The 6 Optimization Tracks

Each track runs independently on its own branch:

| # | Branch | Metric | Target Files |
|---|--------|--------|-------------|
| 1 | `autoresearch/skill-routing` | Skill Triggering Accuracy | `genius-team/SKILL.md`, all skill descriptions |
| 2 | `autoresearch/playground-content` | Playground Content Accuracy | SKILL.md output instructions, `genius-dashboard.html` |
| 3 | `autoresearch/playground-design` | Playground Design Quality | `playgrounds/templates/*.html`, CSS/JS |
| 4 | `autoresearch/orchestration` | Orchestration Chain Completion | `genius-orchestrator/SKILL.md`, hooks, settings.json |
| 5 | `autoresearch/skill-quality` | Skill Output Quality | Individual SKILL.md instructions |
| 6 | `autoresearch/context-efficiency` | Context Efficiency | SKILL.md sizes, context loading instructions |

## Endurance Constraint (ALL tracks)

Every improvement MUST survive the full session lifecycle:

```
Phase 1 — Baseline (tasks 1→10)     : accuracy should be ≥ 90%
Phase 2 — Drift zone (tasks 10→20)  : accuracy should stay ≥ 85%
Phase 3 — Post-compaction (tasks 20→30): accuracy must be ≥ 85%
```

If your change scores well on isolated tasks but drops below 85% post-compaction,
it's a FAIL — revert and try a different approach.

## Experiment Loop

```
for each experiment:
  1. Read current metric baseline from metrics/<track>.json
  2. Make ONE targeted change (small, testable)
  3. Run benchmark: autoresearch/benchmarks/run-benchmark.sh <track>
  4. Collect results
  5. If improvement ≥ 2% AND endurance test passes:
       → commit with message "experiment/<track>-NNN: +X% <description>"
       → update metrics/<track>.json
     Else:
       → git checkout -- <modified files>
       → log attempt in experiments/<track>/NNN-failed.md
  6. Repeat
```

## Rules

- ONE change per experiment (isolate variables)
- NEVER modify files outside your track's scope
- ALWAYS run endurance test every 10 fast iterations
- Log EVERYTHING: what you changed, why, result, metric delta
- If stuck after 5 consecutive failures, try a fundamentally different approach
- Cost budget: track token usage per experiment in the log
