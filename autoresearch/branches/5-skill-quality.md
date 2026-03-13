# Track 5 — Skill Output Quality

## Objective
Each skill should produce high-quality, actionable output — not generic
boilerplate. Code should build. Analyses should be specific. Recommendations
should be implementable.

## Metric
```
For dev skills:    build_success + lint_clean + tests_pass (0-3, normalized)
For analysis skills: specificity_score (LLM-judged, 1-10) / 10
For content skills:  readability + actionability (LLM-judged, 1-10 each) / 20
final_score = avg across all tested skills
```

## Target Files (ONLY these)
- Instructions section in each `.claude/skills/*/SKILL.md`
- NOT descriptions (that's Track 1), NOT output format (that's Track 2)

## What to Optimize
1. **Dev skill instructions**: Produce code that builds first try
2. **Analysis skill instructions**: Be specific to the project, not generic
3. **Content skill instructions**: Write copy that's ready to use, not placeholder
4. **Error handling**: Skills should validate their own output before declaring done

## Experiment Ideas
- Add "self-check" step to dev skills: "run build before marking complete"
- Add "specificity requirement" to analysis skills: "reference actual project files/data"
- Add examples of good vs bad output in each SKILL.md
- Test different instruction styles: step-by-step vs goal-oriented vs constraint-based
- Add quality gates: "if output doesn't meet X criteria, iterate before completing"

## Evaluation
1. Run skill on a test task
2. For dev: attempt `npm run build` or equivalent
3. For analysis: LLM judge rates specificity (1-10)
4. For content: LLM judge rates readability + actionability (1-10 each)
