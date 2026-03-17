# Autoresearch Program — Genius Team Website

## Objective
Build 3 visually stunning, radically different landing pages for genius.w3art.io.
Each page must score high on ALL criteria simultaneously.

## ALL FEEDBACKS TO RESPECT (accumulated from the entire day)

### Visual (non-negotiable)
- Rendu à **plusieurs dizaines de milliers d'euros**
- GSAP + ScrollTrigger + Lenis smooth scroll
- Scroll animations **riches** (NOT just fade-ins) — clip-path, parallax, blur-to-sharp, sticky, card stacking, etc.
- Dark theme with depth and visual tension
- Premium 2026 standard (NOT 2020)
- Cursor glow, ambient effects, depth layers
- Each page must have a **radically different identity**: different palette, different font, different layout, different animations
- "Minimalisme RICHE" = dense premium content, NOT empty space
- NO huge gaps, NO empty sections, NO trous
- Target audience: NON-TECHNICAL people

### Structure
- Clarity before creativity
- 1 idea per section
- 6 categories for agents (Ideation 5, Build 7, Quality 5, Growth 5, Ops 4, AI Engine 5) — NOT 42 flat badges
- Wizard modal: <script src="wizard.js"></script> + GeniusWizard.init() + buttons call GeniusWizard.open()
- Prop-nav at bottom linking /proposition1, /proposition2, /proposition3

### Messaging (CRITICAL — the founder cares deeply about this)
- Headline: "Anyone can build"
- Genius Team = **the ideal AI toolkit to become a coder in the AI era**
- Agents HELP / GUIDE / ACCOMPANY — they do NOT do everything alone
- It's a **vibe coding** tool — you stay in control
- It's NOT a magic wand, NOT "describe and we build for you"
- NOT a dream seller — honest about what it does
- Sub examples: "The AI toolkit that turns anyone into a builder", "Your AI coding crew — 42 specialists that guide every step", "Learn to build with AI at your side"

### From the brand audit
- Input field as central product element (placeholder: "What do you want to build?")
- 3 suggestions max (clickable, auto-fill input): "Booking app for yoga studio", "Marketplace for vintage watches", "Landing page for my brand"
- CTA: "Get Started" or "Start Building"  
- Trust line: ✔ No code needed ✔ Free & open source ✔ Learn as you build
- References: Linear, Stripe, Notion, Vercel, clay.global
- 3 floating cards max: Design / Code / Deploy
- Interactions: click suggestion→fill input, focus→glow, hover→lift, transitions 150-200ms

### Errors to AVOID
- Multicolor gradients that look like 2020 SaaS
- Particles, robots, laptop mockups, futuristic effects
- AI jargon
- "Dribbble decorative" design
- Explaining instead of showing
- Same layout/palette with minor variations between versions

## 3 Distinct Identities

### Page 1 — "Cinematic Amber"
- Palette: Amber #F59E0B / Coral #F97316 on #0A0A0A
- Font: Sora
- Unique effects: Iris clip-path reveal on scroll, parallax multi-layer, cursor glow, glassmorphism cards
- Layout: Full-screen hero with background glow, staggered card grid, sticky workflow

### Page 2 — "Neon Violet"  
- Palette: Magenta #EC4899 / Violet #8B5CF6 on #0C0015
- Font: Plus Jakarta Sans
- Unique effects: Floating animated orbs, card-stack sections, neon glow borders, horizontal scroll pills
- Layout: Centered bold typography, cards that stack/unstack on scroll

### Page 3 — "Premium Gold"
- Palette: Gold #D4A574 / Warm white #F5F0EB on #0F0F0F  
- Font: DM Sans
- Unique effects: Timeline with animated vertical line, alternating left/right nodes, progress bars, editorial spacing
- Layout: Timeline-driven narrative, larger typography with generous tracking

## Measurement Criteria (score 1-10 each)
1. **Visual impact** — Does it look like a €50K+ site? Depth, polish, animation quality
2. **Clarity** — Can a non-tech person understand "AI toolkit to learn to code" in <3 seconds?
3. **Density** — No empty space, no trous, every section has real content
4. **Uniqueness** — Is this page truly different from the other 2?
5. **Messaging** — Vibe coding, honest, no magic promises
6. **Interactions** — Scroll effects, hover states, micro-animations, cursor glow
7. **Responsive** — Works on mobile, tablet, desktop
8. **Technical** — No JS errors, clean HTML, proper accessibility

## Iteration Rules
- Each iteration: modify ONE aspect, re-check all 8 criteria
- Keep if improved, revert if not
- Log every iteration in autoresearch/website/log.md
- Commit best versions regularly to git
- Target: 3 pages each scoring 8+/10 on ALL criteria

## Files
- /Users/benbot/genius-team/docs/proposition1.html
- /Users/benbot/genius-team/docs/proposition2.html  
- /Users/benbot/genius-team/docs/proposition3.html
- /Users/benbot/genius-team/docs/wizard.js (shared, do not modify)
- Images available: img/hero-brain.jpg, img/app-mockup.jpg, img/workflow-steps.jpg, img/holographic-ui.jpg, img/agent-constellation.jpg, img/skill-categories.jpg, img/before-after.jpg
