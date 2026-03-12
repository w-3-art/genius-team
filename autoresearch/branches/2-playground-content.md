# Track 2 — Playground Content Accuracy

## Objective
When a skill completes work, it must update the correct playground tab in
genius-dashboard with real project data — never create orphan files, never
leave mock data in active tabs.

## Metric
```
content_accuracy = (tabs_with_real_data / tabs_that_should_have_data)
orphan_penalty   = orphan_playground_files_created * -0.2
final_score      = content_accuracy + orphan_penalty
```

## Target Files (ONLY these)
- Output/completion instructions in each `.claude/skills/*/SKILL.md`
- `playgrounds/templates/genius-dashboard.html` (tab visibility logic)
- `.claude/commands/playground-update.md`

## What to Optimize
1. **Skill completion instructions**: Each SKILL.md should end with "update the
   corresponding playground tab in genius-dashboard.html with real data"
2. **Tab visibility**: Tabs for skills not yet executed should be hidden
3. **Data format**: Standardize how skills output data for playground consumption
4. **Anti-orphan rules**: Explicit instruction to NEVER create a new playground
   file — always update the existing dashboard tab

## Experiment Ideas
- Add explicit "## Output" section to each SKILL.md with playground update instructions
- Test different phrasings: "update the dashboard" vs "call /playground-update" vs inline JS data replacement
- Add a validation step: after updating, check that genius-dashboard.html was modified
- Test whether a post-task hook in settings.json can auto-trigger playground updates
- Add "hidden by default" logic: tabs start hidden, skills un-hide their tab on completion

## Endurance Check
At each checkpoint in the 30-task sequence:
- Count tabs with real data vs expected
- Count orphan playground files
- Verify no mock data remains in completed tabs
Post-compaction: does the playground update behavior persist?
