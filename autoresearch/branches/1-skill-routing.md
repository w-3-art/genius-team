# Track 1 — Skill Triggering Accuracy

## Objective
Maximize the % of user prompts that trigger the correct skill.

## Metric
```
accuracy = correct_skill_triggered / total_tasks
```

## Target Files (ONLY these)
- `.claude/skills/genius-team/SKILL.md` (the router)
- Description fields in all 42 `.claude/skills/*/SKILL.md`
- Do NOT modify skill logic/instructions, only descriptions and trigger phrases

## Current Baseline
Unknown — first run will establish it.

## What to Optimize
1. **Router prompt** (`genius-team/SKILL.md`): How it decides which skill to delegate to
2. **Skill descriptions**: The `description:` field that Claude uses to match user intent
3. **Trigger phrases**: Explicit examples of when each skill should activate
4. **Negative triggers**: When a skill should NOT activate (disambiguation)

## Experiment Ideas
- Add more trigger phrase examples to underperforming skills
- Add disambiguation rules for commonly confused skill pairs (e.g., genius-dev vs genius-dev-frontend)
- Test different router prompt structures (list vs decision tree vs scoring)
- Add "if in doubt, ask" rules for ambiguous requests
- Test whether shorter/longer descriptions affect matching

## Evaluation
For each task in benchmarks/tasks.json:
1. Present the prompt to Claude with Genius Team loaded
2. Check which skill was activated (from Claude's output/tool use)
3. Compare to `expected_skill`
4. Score: match=1, wrong_skill=0, no_skill_used=-0.5

## Endurance Check
Run full 30-task sequence. Measure accuracy at:
- Tasks 1-10 (baseline): must be ≥ 90%
- Tasks 10-20 (drift zone): must be ≥ 85%
- Tasks 20-30 (post-compaction): must be ≥ 85%
