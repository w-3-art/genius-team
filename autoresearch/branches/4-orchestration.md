# Track 4 — Orchestration Chain Completion

## Objective
When building a project, skills should chain automatically without the user
having to manually invoke the next step. genius-orchestrator should drive
the flow from interview → specs → design → dev → qa → deploy.

## Metric
```
chain_completion = skills_auto_triggered / skills_expected_in_sequence
manual_interventions = times_user_had_to_say_next_or_continue
final_score = chain_completion - (manual_interventions * 0.1)
```

## Target Files (ONLY these)
- `.claude/skills/genius-orchestrator/SKILL.md`
- `.claude/skills/genius-team/SKILL.md` (router handoff logic)
- `configs/*/settings.json` (hooks that trigger next steps)
- `postCompactionSections` content in all 4 settings.json

## What to Optimize
1. **Orchestrator logic**: When skill A completes, which skill B should auto-start?
2. **Transition prompts**: How does the orchestrator hand off between skills?
3. **User checkpoints**: Where should it pause for approval vs auto-continue?
4. **PostCompaction persistence**: Does the orchestration state survive compaction?

## Experiment Ideas
- Define explicit skill chains: interview → PMA → specs → architect → designer → dev-*
- Add "next_skill" field to each SKILL.md output section
- Test orchestrator as explicit state machine vs free-form reasoning
- Add phase tracking in .genius/state.json that orchestrator reads
- Test hooks: Stop hook that checks "is there a logical next skill?" and suggests it
- Add /continue command awareness: after compaction, /continue should resume the chain

## Endurance Check
Run full 30-task sequence:
- Count how many skill transitions happened automatically
- Count how many times the user had to manually invoke a skill
- Post-compaction: does the orchestrator remember where in the chain it was?
