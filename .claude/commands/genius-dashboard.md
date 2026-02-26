---
description: Generate or refresh the master dashboard aggregating all project playgrounds
---

# /genius-dashboard

Generate (or refresh) a single-page master dashboard that shows ALL project playgrounds as tabs.

## What it does

1. Scans `.genius/*.html` for existing playground files
2. Generates `.genius/DASHBOARD.html` — a tabbed single-page hub
3. Announces the path and how to open it

## Execution

### Step 1: Discover playgrounds

```bash
ls .genius/*.html 2>/dev/null | grep -v DASHBOARD.html | sort
```

List each file found with a short description (infer from filename):
- `DISCOVERY.html` → 🔍 Product Discovery
- `DESIGN-SYSTEM.html` → 🎨 Design System
- `SPECS.html` → 📋 Specifications
- `COPY-SYSTEM.html` → ✍️ Copywriting
- `ARCHITECTURE.html` → 🏗️ Architecture
- `MARKET.html` → 📊 Market Analysis
- `PROGRESS.html` → 📈 Sprint Progress
- `QA.html` → ✅ QA Report
- `SECURITY.html` → 🔒 Security Audit
- Any other `*.html` → 📄 name from file

### Step 2: Generate .genius/DASHBOARD.html

Generate a single HTML file with this structure:
- Top header: project name (from state.json or dirname) + "Genius Team Dashboard"
- Tab bar: one tab per playground discovered, with icon + label
- Content area: iframe showing the selected playground
- Tab switching via JavaScript (no frameworks)
- Dark theme matching Genius Team style (`#0a0a0f` bg, `#7c3aed` purple accent)
- Mobile-friendly (stacked tabs on small screens)

**Exact template to use:**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>[PROJECT_NAME] — Genius Team Dashboard</title>
<style>
  *{box-sizing:border-box;margin:0;padding:0}
  body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#0a0a0f;color:#e2e8f0;height:100vh;display:flex;flex-direction:column}
  header{padding:12px 20px;background:#13131a;border-bottom:1px solid #1e1e2e;display:flex;align-items:center;gap:12px;flex-shrink:0}
  header h1{font-size:1rem;font-weight:600;background:linear-gradient(135deg,#7c3aed,#06b6d4);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
  header span{font-size:.8rem;color:#64748b}
  .tabs{display:flex;gap:4px;padding:8px 12px;background:#0d0d14;border-bottom:1px solid #1e1e2e;overflow-x:auto;flex-shrink:0;scrollbar-width:none}
  .tabs::-webkit-scrollbar{display:none}
  .tab{padding:6px 14px;border-radius:6px;border:1px solid #1e1e2e;background:#13131a;color:#94a3b8;font-size:.82rem;cursor:pointer;white-space:nowrap;transition:all .15s;display:flex;align-items:center;gap:6px}
  .tab:hover{background:#1e1e2e;color:#e2e8f0}
  .tab.active{background:linear-gradient(135deg,rgba(124,58,237,.3),rgba(6,182,212,.2));border-color:#7c3aed;color:#e2e8f0}
  .content{flex:1;overflow:hidden}
  iframe{width:100%;height:100%;border:none}
  .empty{display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;gap:12px;color:#64748b}
  .empty h2{font-size:1.1rem;color:#94a3b8}
  @media(max-width:600px){header{padding:8px 12px}header h1{font-size:.9rem}.tab{padding:5px 10px;font-size:.75rem}}
</style>
</head>
<body>
<header>
  <div>
    <h1>🧠 [PROJECT_NAME] — Genius Team Dashboard</h1>
    <span>[PLAYGROUND_COUNT] playgrounds · v13.0</span>
  </div>
</header>
<div class="tabs" id="tabs">[TAB_HTML]</div>
<div class="content"><iframe id="frame" src="[FIRST_SRC]" title="Playground"></iframe></div>
<script>
function show(src,el){
  document.getElementById('frame').src=src;
  document.querySelectorAll('.tab').forEach(t=>t.classList.remove('active'));
  el.classList.add('active');
}
</script>
</body>
</html>
```

**Fill in the template:**
- `[PROJECT_NAME]` → value of `name` from `.genius/state.json`, or the current directory name
- `[PLAYGROUND_COUNT]` → number of playground files found
- `[TAB_HTML]` → one `<button class="tab" onclick="show('FILENAME.html', this)">ICON LABEL</button>` per file
- `[FIRST_SRC]` → first playground file path (to load by default)
- First tab should have `class="tab active"`

### Step 3: Confirm and give instructions

```
✅ Dashboard generated: .genius/DASHBOARD.html
   [n] playgrounds loaded

📂 Open it:
   • Finder: open .genius/DASHBOARD.html
   • Terminal: open .genius/DASHBOARD.html
   • VS Code: right-click → Open with Live Server

Playgrounds included:
   [list each tab with icon + name]
```

Then open it:
```bash
open .genius/DASHBOARD.html 2>/dev/null || echo "📂 Open: $(pwd)/.genius/DASHBOARD.html"
```

## Notes

- Re-running `/genius-dashboard` always refreshes the file with latest playgrounds
- If no `.genius/*.html` files exist yet → explain that playgrounds are generated as each skill completes
- The iframe loads files from the local filesystem — works without any server
