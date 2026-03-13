# Track 6 — Context Efficiency

## Objective
Minimize token consumption per skill execution while maintaining output quality.
Skills should load only relevant context, not dump entire files unnecessarily.

## Metric
```
tokens_per_task   = total_tokens_used / tasks_completed
quality_maintained = skill_quality_score ≥ baseline (from Track 5)
final_score       = 1 / tokens_per_task * quality_maintained
```
Higher is better (fewer tokens + same quality = better score).

## Target Files (ONLY these)
- Context loading instructions in each `.claude/skills/*/SKILL.md`
- `postCompactionSections` in `configs/*/settings.json`
- Save-token mode instructions in `genius-save-token/SKILL.md`

## What to Optimize
1. **Context loading**: Skills should read only what they need, not "read all files"
2. **SKILL.md size**: Shorter, denser instructions = less context consumed per invocation
3. **PostCompaction content**: Minimal but sufficient — what's the smallest set of
   instructions that maintains accuracy post-compaction?
4. **Save-token mode**: Optimize aggressive token saving without quality loss

## Experiment Ideas
- Measure current token usage per skill (baseline)
- Trim verbose SKILL.md instructions — test if shorter versions maintain quality
- Replace "read the entire codebase" with "read only relevant files for this task"
- Test different postCompactionSections content: minimal vs detailed
- Add "context budget" to skills: "use at most N tokens for context loading"
- Test lazy loading: only read files when actually needed, not upfront

## Evaluation
1. Run 5 quick tasks, measure total tokens in/out
2. Run same tasks with optimized skills, measure again
3. Compare quality scores (must not decrease by more than 5%)
4. Calculate efficiency gain: (baseline_tokens - optimized_tokens) / baseline_tokens

## Constraint
Quality MUST NOT decrease. This track optimizes efficiency, not at the expense
of output quality. If quality drops > 5%, the experiment is a failure.
