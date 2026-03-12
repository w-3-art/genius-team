# Track 3 — Playground Design Quality

## Objective
Playgrounds should look professional and adopt the project's design system
(colors, fonts, spacing) once genius-designer has defined it.

## Metric
```
lighthouse_score  = avg(performance, accessibility, best_practices) / 100
design_coherence  = uses_project_colors + uses_project_fonts + responsive_check (0-3, normalized)
final_score       = lighthouse_score * 0.5 + design_coherence * 0.5
```

## Target Files (ONLY these)
- `playgrounds/templates/*.html` (CSS/JS only, not data sections)
- `genius-designer/SKILL.md` (output format for design tokens)
- `genius-playground-generator/SKILL.md` (template generation instructions)

## What to Optimize
1. **Base template quality**: Better default CSS (modern, clean, responsive)
2. **Design token injection**: After genius-designer runs, playgrounds should
   automatically adopt project colors/fonts via CSS variables
3. **Responsive design**: All playgrounds must work on mobile
4. **Lighthouse scores**: Target ≥ 85 on all 3 categories

## Experiment Ideas
- Replace current CSS with a minimal design system (CSS variables for theming)
- Add a `design-tokens.css` file that genius-designer populates
- All playground templates `@import` design-tokens.css
- Test different CSS frameworks: none vs minimal (open-props) vs tailwind-lite
- Optimize HTML structure for Lighthouse (semantic tags, lazy loading, etc.)
- Add dark mode support via prefers-color-scheme

## Evaluation
1. Generate a playground with default template
2. Run Lighthouse CI (headless Chrome)
3. Check if project design tokens are applied (parse CSS variables)
4. Check mobile viewport rendering (screenshot at 375px width)
