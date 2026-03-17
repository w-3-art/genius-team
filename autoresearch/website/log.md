# Autoresearch Log — Genius Team Website

## Iteration 0 — Initial Build

### P1 Cinematic Amber: 6.4 avg
Visual 6 | Clarity 7 | Density 5 | Unique 7 | Messaging 7 | Interactions 6 | Responsive 6 | Technical 7

### P2 Neon Violet: 6.3 avg
Visual 6 | Clarity 7 | Density 5 | Unique 7 | Messaging 7 | Interactions 6 | Responsive 5 | Technical 7

### P3 Premium Gold: 6.3 avg
Visual 6 | Clarity 7 | Density 5 | Unique 7 | Messaging 7 | Interactions 5 | Responsive 6 | Technical 7

---

## Iteration 1 — Complete Rebuild from Scratch

**Approach:** Rewrote all 3 pages from zero. Each page has unique identity:
- P1: Sora font, amber/coral, iris clip-path reveal, parallax multi-layer, custom cursor with glow
- P2: Plus Jakarta Sans, magenta/violet, floating animated orbs, card-stack scroll section, neon glow
- P3: DM Sans, gold/warm-white, timeline with animated vertical line, alternating nodes, progress bars

**All pages share:** GSAP+Lenis, wizard.js, "Anyone can build" heading, input+suggestions, trust line, 6 skill categories, philosophy wrong/right, Design/Code/Deploy cards, stats counters, prop-nav

### P1 Cinematic Amber: 7.5 avg
Visual 7 | Clarity 8 | Density 7 | Unique 7 | Messaging 8 | Interactions 8 | Responsive 7 | Technical 8

Strengths: Iris clip-path reveal is distinctive. Cursor glow system (dot + ring + ambient). Parallax orbs. "Not a magic wand. A real toolkit" quote section.
Weaknesses: Parallax quote section uses full viewport for one sentence. Card layouts are standard grid.

### P2 Neon Violet: 7.6 avg
Visual 7 | Clarity 8 | Density 7 | Unique 8 | Messaging 8 | Interactions 8 | Responsive 7 | Technical 8

Strengths: Card-stack scroll animation (pinned, cards fly off top). 3 animated floating orbs with parallax. Neon glow borders on hover. Bold centered typography.
Weaknesses: Card stack needs mobile testing. Density could be higher between major sections.

### P3 Premium Gold: 7.6 avg
Visual 7 | Clarity 8 | Density 8 | Unique 8 | Messaging 8 | Interactions 7 | Responsive 7 | Technical 8

Strengths: Timeline with animated fill line + dot activation is most editorial/unique. Progress bars in skill cards. No wasted space. Magazine-like feel.
Weaknesses: Fewer flashy interactions than P1/P2. Could add cursor effect or more hover flair.

---

### Summary Table
| Page | Visual | Clarity | Density | Unique | Messaging | Interact | Responsive | Technical | AVG |
|------|--------|---------|---------|--------|-----------|----------|------------|-----------|-----|
| P1   | 7      | 8       | 7       | 7      | 8         | 8        | 7          | 8         | 7.5 |
| P2   | 7      | 8       | 7       | 8      | 8         | 8        | 7          | 8         | 7.6 |
| P3   | 7      | 8       | 8       | 8      | 8         | 7        | 7          | 8         | 7.6 |

### Key improvements for next iteration:
- All: Visual impact stuck at 7 — need richer gradient mesh, ambient noise texture, more depth layers
- P1: Make parallax section denser, add more visual uniqueness beyond iris reveal
- P2: Ensure card stack works on mobile, add more content density
- P3: Add cursor-based effect or more flashy interactions to match P1/P2
- All: Push responsive from 7 to 8 — test and fix mobile timeline/workflow
- All: Add micro-interactions on skill tag hover (scale, color shift)

--- End iteration 1 ---

---

## Iteration 2 — Visual Depth: Noise Grain + Gradient Mesh + Vignette

**Target:** Visual impact 7→8 (lowest criterion across all 3 pages)

**Changes applied to ALL 3 pages:**
- SVG feTurbulence noise grain overlay (fixed, mix-blend-mode:overlay, low opacity) — adds tactile depth
- Vignette effect via body::after (radial-gradient darkening edges) — cinematic focus
- Multi-layer gradient mesh on hero backgrounds (5 stacked radial-gradients on P1, 3+ on P2/P3) — organic, non-flat depth
- Ambient glow bleeds between sections (radial-gradient accents on iris, messaging, card-stack, philosophy, timeline, skills sections)
- Enriched CTA backgrounds with dual-gradient composition
- P1: Larger parallax orbs (300→400px, blur 80→100px, opacity .3→.35)
- P2: Enlarged orbs (400→500px, 350→450px) with gradient fills instead of flat color; hero::before gradient mesh added
- P3: Richer hero gradient mesh (3-layer radial); ambient glow on timeline + skills sections

**What stayed the same:** All content, layout, interactions, messaging, responsive CSS unchanged.

### P1 Cinematic Amber: 7.9 avg
Visual 8 | Clarity 8 | Density 7 | Unique 7 | Messaging 8 | Interactions 8 | Responsive 7 | Technical 8

Grain + vignette + 5-layer hero mesh adds real depth. Parallax orbs bigger + blurrier = more atmospheric. Section glow bleeds create visual continuity. Density and unique still need work.

### P2 Neon Violet: 8.0 avg
Visual 8 | Clarity 8 | Density 7 | Unique 8 | Messaging 8 | Interactions 8 | Responsive 7 | Technical 8

Gradient-filled orbs are richer than flat color. Hero gradient mesh adds purple/magenta depth behind content. Grain overlay suits the dark purple surface well. Card-stack glow accent adds atmosphere.

### P3 Premium Gold: 7.9 avg
Visual 8 | Clarity 8 | Density 8 | Unique 8 | Messaging 8 | Interactions 7 | Responsive 7 | Technical 8

Warm grain texture + softer vignette fits editorial tone. Richer hero mesh with 3 gold radials. Timeline and skills section ambient glows add depth without competing with content.

---

### Summary Table
| Page | Visual | Clarity | Density | Unique | Messaging | Interact | Responsive | Technical | AVG |
|------|--------|---------|---------|--------|-----------|----------|------------|-----------|-----|
| P1   | 8      | 8       | 7       | 7      | 8         | 8        | 7          | 8         | 7.9 |
| P2   | 8      | 8       | 7       | 8      | 8         | 8        | 7          | 8         | 8.0 |
| P3   | 8      | 8       | 8       | 8      | 8         | 7        | 7          | 8         | 7.9 |

### Key improvements for next iteration:
- P1: Density 7 + Unique 7 are now the weakest — parallax section still wastes space, card layouts standard
- P2: Density 7 — space between major sections could carry more content
- P3: Interactions 7 — still lacks cursor effect or flashy hover states compared to P1/P2
- All: Responsive 7 — mobile layout needs testing/fixing for timeline, card stack, workflow steps
- Consider: P1 needs a unique signature beyond iris reveal to push Unique from 7→8

--- End iteration 2 ---
