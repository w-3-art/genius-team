# genius-designer — Design Details (progressive disclosure)

Loaded on demand from `SKILL.md`. Contains the full playground HTML requirements,
state.json / memory JSON field shapes, playground control inventory, preset and
design-tokens.css specifications, the checkpoint message template, and the
design-config.json schema. `SKILL.md` keeps only the workflow summary.

---

## Playground HTML Requirements (full spec)

`.genius/outputs/design-playground.html` is the **PRIMARY OUTPUT**. Not the config, not the state — the HTML.

- Self-contained, zero external dependencies
- Dark background (#0F0F0F)
- 3 tabs or cards: Option A, Option B, Option C
- Each option shows:
  - **Live color swatches** (actual colored rectangles, not hex codes)
  - **Typography samples** (load Google Fonts via `<link>`, show real text in the font)
  - **Button examples** with the actual border-radius and colors
  - **A mini mockup** showing how a dashboard/form would look with these colors
- User clicks between options to compare
- At the bottom: "Which option do you prefer? Tell Claude: I prefer option 1/2/3"

---

## Unified Dashboard Integration (state.json field shapes)

### On Phase Start
Update `.genius/outputs/state.json`:
```json
{
  "currentPhase": "design",
  "phases": {
    "design": {
      "status": "in-progress",
      "data": { ... }
    }
  }
}
```

### On Phase Complete
Update state.json with:
- `phases.design.status` = `"complete"`
- `phases.design.data` = design system tokens and choices
- `currentPhase` = `"dev"`

---

## Memory Integration (JSON entry shapes)

### During Design
Append to `.genius/memory/decisions.json`:
```json
{"id": "d-XXX", "decision": "DESIGN: [choice]", "reason": "[why]", "timestamp": "ISO-date", "tags": ["design", "decision"]}
```

### On Complete
Append to `.genius/memory/decisions.json`:
```json
{"id": "d-XXX", "decision": "DESIGN SYSTEM COMPLETE: [preset name] | Primary: [color] | Font: [font]", "reason": "user selected via playground", "timestamp": "ISO-date", "tags": ["design", "complete"]}
```

---

## Playground Controls (unified dashboard)

The unified dashboard shows the design phase where users can:
- **Colors**: Adjust primary, secondary, accent, and neutral colors with live preview
- **Typography**: Choose font family, base size, scale ratio, and weights
- **Spacing**: Set base unit that scales automatically (×1, ×2, ×3, ×4, ×6, ×8, ×12, ×16)
- **Border Radius**: Adjust roundness of components
- **Shadows**: Control intensity and blur for depth effects
- **Preview**: Toggle light/dark mode to see components in action
- **Export**: Copy as Prompt spec, CSS Variables, or Tailwind config

### Updating state.json with Design Presets

Write 3+ presets to `phases.design.data.presets` in state.json. Each preset has: primary, secondary, accent, neutralLight, neutralDark (hex colors), fontFamily, fontSize, scaleRatio, spacingBase, borderRadius, shadowIntensity, shadowBlur. Name presets descriptively: `modernMinimal`, `boldEnergetic`, `warmOrganic`, `techProfessional`.

### Output: design-tokens.css (MANDATORY)

After user approval, write `playgrounds/templates/design-tokens.css` with `:root` CSS custom properties using the ACTUAL chosen colors. Required tokens: `--color-primary`, `--color-secondary`, `--color-accent`, `--color-bg-*`, `--color-text-*`, `--font-family`, `--font-size-base`, `--spacing-unit`, `--border-radius`, `--color-success/warning/error/info`. All playground templates import this file for brand consistency.

### DO NOT Create Separate HTML Files

The unified dashboard reads from state.json. No need to:
- ❌ Copy templates
- ❌ Create DESIGN-SYSTEM.html
- ❌ Open separate URLs

---

## Checkpoint Message Template

```
🎨 DESIGN SYSTEM READY

Check the **Design** tab in your Project Dashboard (already open at http://localhost:8888/project-dashboard.html).

I've prepared 3 design directions for [Project Name]:

• 🎯 [Option 1 Name] — [Brief description: e.g., "Clean and modern with purple accents"]
• 🎨 [Option 2 Name] — [Brief description: e.g., "Bold and energetic with warm colors"]
• ✨ [Option 3 Name] — [Brief description: e.g., "Professional and trustworthy blues"]

**In the dashboard you can:**
- Switch between preset options
- Fine-tune any color, font, spacing, or shadow
- Toggle light/dark mode preview
- See live component previews (buttons, inputs, cards)
- Export as CSS Variables or Tailwind config

**When you're happy with your design:**
Copy the "Prompt" output and paste it here so I can save your final configuration.
```

---

## design-config.json Schema

After parsing the user's exported prompt, save to `.genius/design-config.json`:

```json
{
  "colors": {
    "primary": "#XXXXXX",
    "secondary": "#XXXXXX",
    "accent": "#XXXXXX",
    "neutralLight": "#XXXXXX",
    "neutralDark": "#XXXXXX"
  },
  "typography": {
    "fontFamily": "Font Name",
    "baseSize": 16,
    "scaleRatio": 1.25,
    "weights": [400, 500, 600, 700]
  },
  "spacing": {
    "baseUnit": 4
  },
  "borderRadius": 8,
  "shadows": {
    "intensity": 0.1,
    "blur": 16
  }
}
```
