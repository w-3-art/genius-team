# 🔬 Genius Team Autoresearch

Autonomous optimization of Genius Team using the [Karpathy autoresearch](https://github.com/karpathy/autoresearch) pattern.

## Concept

Instead of manually tweaking skills and prompts, we let AI agents optimize
Genius Team overnight through systematic experimentation:

**modify → test → measure → keep/revert → repeat**

## 6 Optimization Tracks

| Track | Metric | What it optimizes |
|-------|--------|-------------------|
| 1 | Skill Triggering Accuracy | Router + skill descriptions → right skill called every time |
| 2 | Playground Content Accuracy | Real data in dashboards, no orphan files, no mock data |
| 3 | Playground Design Quality | Lighthouse scores, design coherence, responsive |
| 4 | Orchestration Chain Completion | Skills auto-chain without manual intervention |
| 5 | Skill Output Quality | Code builds, analyses are specific, content is ready-to-use |
| 6 | Context Efficiency | Fewer tokens per task, same quality |

Each track runs on its own branch (`autoresearch/track-N-*`), modifies only
its assigned files, and merges results independently.

## Endurance Constraint

All improvements must survive 30-task sessions including context compaction:

- **Phase 1** (tasks 1-10): baseline ≥ 90%
- **Phase 2** (tasks 10-20): drift zone ≥ 85%
- **Phase 3** (tasks 20-30): post-compaction ≥ 85%

## Quick Start

```bash
# Run quick benchmark (5 tasks)
bash autoresearch/benchmarks/run-benchmark.sh 1 --quick

# Run full endurance test (30 tasks)
bash autoresearch/benchmarks/run-benchmark.sh 1 --endurance

# View results
cat autoresearch/experiments/track-1/*.json | jq '.accuracy'
```

## Structure

```
autoresearch/
├── program.md              # Master instructions for optimization agents
├── README.md               # This file
├── benchmarks/
│   ├── tasks.json          # 30-task SaaS project sequence + 5 quick tests
│   └── run-benchmark.sh    # Benchmark runner (manual eval for now)
├── branches/
│   ├── 1-skill-routing.md      # Track 1 program
│   ├── 2-playground-content.md # Track 2 program
│   ├── 3-playground-design.md  # Track 3 program
│   ├── 4-orchestration.md      # Track 4 program
│   ├── 5-skill-quality.md      # Track 5 program
│   └── 6-context-efficiency.md # Track 6 program
├── metrics/
│   └── baseline.json       # Baseline measurements
└── experiments/            # Experiment logs (per track)
```

## Roadmap

- [x] Framework structure
- [x] 30-task benchmark sequence
- [x] 6 track definitions with metrics
- [x] Benchmark runner (manual mode)
- [ ] Establish baselines (first benchmark run)
- [ ] Automated evaluation via Claude API
- [ ] Parallel branch execution
- [ ] Results merge process
- [ ] CI integration for regression testing
