---
description: >-
  Analyze project progress and update playground templates with real data, then
  suggest creating new playgrounds for gaps not yet covered. Use when user says
  "/playground-update", "update my playgrounds", "refresh playgrounds", or
  "what playgrounds should I use". Can also be triggered automatically after
  /continue when significant project progress is detected.
---

# /playground-update

Analyze everything that has happened in this project and:
1. Update existing playground templates with real project data
2. Identify important project aspects that have no playground yet
3. Propose generating new custom playgrounds for those gaps

---

## Step 1 — Scan Project State

```bash
# What phase are we in?
cat .genius/state.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'Phase: {d.get(\"currentPhase\",\"unknown\")} | Skills run: {d.get(\"completedSkills\",[])} | Stack: {d.get(\"techStack\",{})}') " 2>/dev/null || cat .genius/state.json 2>/dev/null

# What outputs exist?
echo "=== Outputs ===" && ls .genius/outputs/ 2>/dev/null
echo "=== Memory ===" && ls .genius/memory/ 2>/dev/null
echo "=== Artifacts ===" && ls *.xml .genius/*.xml 2>/dev/null | head -10

# What playgrounds have already been used?
ls playgrounds/data/*.json 2>/dev/null | head -5
cat .genius/playground.log 2>/dev/null | tail -10
```

---

## Step 2 — Analyze Gaps

Based on the scan above, identify:

### A) Templates that should be updated with real project data

For each playground that EXISTS and has related project data:

| Playground | What to update |
|-----------|---------------|
| `project-canvas.html` | If SPECIFICATIONS.xml exists → pre-fill vision/scope from real specs |
| `market-simulator.html` | If MARKET-ANALYSIS.xml exists → pre-fill TAM/SAM/SOM/competitors from real data |
| `architecture-explorer.html` | If ARCHITECTURE.md exists → highlight chosen stack, pre-select patterns |
| `stack-configurator.html` | If ARCHITECTURE.md exists → mark actual chosen stack |
| `design-system-builder.html` | If DESIGN-SYSTEM.html exists → extract real color tokens |
| `progress-dashboard.html` | If .claude/plan.md exists → show real task completion from plan |
| `deploy-checklist.html` | If ARCHITECTURE.md exists → populate with real deploy platform/steps |
| `seo-dashboard.html` | If .genius/seo-report.md exists → fill with real scores/issues |
| `analytics-wizard.html` | If stack has analytics → pre-select platform, suggest events |
| `performance-monitor.html` | If URLs exist → suggest real endpoints to test |

### B) Missing playgrounds — propose new ones

Think about what matters for THIS specific project that has no template:

- **If it's a SaaS** → suggest: Pricing Calculator, Churn Risk Dashboard, MRR Tracker
- **If it's e-commerce** → suggest: Conversion Funnel, Cart Abandonment, Revenue Dashboard
- **If it's a mobile app** → suggest: App Store Metrics, Crash Dashboard, Session Tracker
- **If it's Web3** → suggest: Token Distribution, Liquidity Monitor, Wallet Analytics
- **If it's API/backend** → suggest: API Response Time Monitor, Error Rate Dashboard, Rate Limit Tracker
- **If it's content/blog** → suggest: Content Calendar, SEO Topic Cluster, Traffic Dashboard
- **General gaps** → if no playground covers security, performance budgets, or user retention → propose those

---

## Step 3 — Update Existing Templates

For each template that CAN be updated with real data:

1. Read the current template HTML
2. Find the JavaScript data section (usually a `const DATA = {...}` or `const STATE = {...}` block)
3. Replace placeholder values with actual project values
4. Add a `<!-- Updated by /playground-update: TIMESTAMP -->` comment
5. Print: `✅ Updated: playgrounds/templates/FILENAME.html`

**Important rules:**
- Only update DATA values, never change the HTML/CSS/JS structure
- Keep the template functional if no data is available for a field (use defaults)
- Never break the template — test that it still opens after editing

---

## Step 4 — Propose New Playgrounds

For each gap identified in Step 2B, output a structured proposal:

```
💡 Suggested new playground: [NAME]
   Why: [1 sentence — what project aspect it would visualize]
   Key metrics: [3-5 bullet points of what it would show]
   Command to create: /genius-playground [type]
   
   Create it? (yes/no)
```

If the user says yes to any → use **genius-playground-generator** to build it:
- Generate as `.genius/outputs/[name].html`
- Use real project data where available
- Follow the genius-playground-generator spec (dark theme, zero deps, interactive)

---

## Step 5 — Output Summary

```
📊 /playground-update complete

✅ Updated X templates with real project data:
   - market-simulator.html (TAM/SAM from MARKET-ANALYSIS.xml)
   - progress-dashboard.html (X/Y tasks from .claude/plan.md)
   
💡 X new playgrounds suggested:
   1. [Name] — [why]
   2. [Name] — [why]
   
Type "yes" to generate all suggestions, or pick by number.
```

---

## Auto-trigger from /continue

When called after `/continue`, add this check at the end of the continue flow:

```
🎮 Playground tip: Run /playground-update to sync your playgrounds with 
   project progress — templates will be pre-filled with real data from 
   your specs, architecture, and completed work.
```

Only show this if:
- At least 1 major skill has been completed (genius-specs, genius-architect, genius-deployer, genius-seo, etc.)
- The last playground update was more than 2 sessions ago (check .genius/playground.log)
- The project is past the Interview phase
