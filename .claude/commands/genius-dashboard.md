---
description: Generate or refresh the GT v22 dashboard from canonical runtime outputs
---

# /genius-dashboard

Refresh the project dashboard from the canonical GT v22 output layer.

## Execution

### Step 1: Discover runtime outputs

Run:

```bash
find .genius/outputs -maxdepth 1 -name '*.html' | sort
cat .genius/outputs/state.json 2>/dev/null
```

Use `.genius/outputs/*.html` as the runtime output source.

Do **not** use `.genius/playgrounds/`.
Do **not** treat root `.genius/*.html` as the main model.

### Step 2: Generate the canonical hub

Run:

```bash
export PATH="$PWD/.genius/bin:$PATH"
genius-dashboard
```

If you cannot use the wrapper, reproduce the same effect:

- read outputs from `.genius/outputs/*.html`
- generate `.genius/DASHBOARD.html`
- update `.genius/outputs/state.json`

### Step 3: Confirm

Show:

- dashboard path
- number of runtime outputs found
- output filenames included

### Step 4: Give the open instruction

Always end with:

```text
Dashboard ready:
  open .genius/DASHBOARD.html
```
