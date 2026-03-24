# Genius Cortex — Proposition v2 (Autoresearch Iteration 2)
*Architecture technique détaillée + Behaviors concrets*

---

## Positionnement vs Concurrence

| | Conductor | Codex App | Overstory | **Genius Cortex** |
|---|---|---|---|---|
| Focus | Parallel agents | Desktop super-app | Multi-agent orchestration | **Multi-repo governance** |
| Scope | 1 repo, many agents | 1 session | 1 repo, many agents | **Many repos, shared brain** |
| Memory | None | Per-session | None | **Cross-repo behaviors** |
| Version mgmt | None | None | None | **Monitor + auto-upgrade** |
| Target | Power devs | All OpenAI users | Advanced devs | **Vibe coders + teams** |

**Différenciateur Cortex :** personne ne fait de la gouvernance multi-repos + mémoire partagée. Conductor gère des agents en parallèle sur UN repo. Cortex gère ton PORTEFEUILLE de projets.

---

## Architecture Finale — Hybrid (CLI + Dashboard + MCP)

```
┌─────────────────────────────────────────────────┐
│              Genius Cortex                       │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐ │
│  │  cortex   │  │ Dashboard│  │  MCP Server   │ │
│  │  CLI      │  │ Web UI   │  │  (CC plugin)  │ │
│  └────┬─────┘  └────┬─────┘  └──────┬────────┘ │
│       │              │               │           │
│       └──────────────┼───────────────┘           │
│                      │                           │
│              ┌───────┴────────┐                  │
│              │   Cortex Core  │                  │
│              │   (Node.js)    │                  │
│              └───────┬────────┘                  │
│                      │                           │
│  ┌──────────┐  ┌─────┴─────┐  ┌──────────────┐ │
│  │ Behaviors│  │  Registry  │  │   Memory     │ │
│  │ Engine   │  │  (repos)   │  │   Store      │ │
│  └──────────┘  └───────────┘  └──────────────┘ │
└─────────────────────────────────────────────────┘
         │                 │
    ┌────┴────┐      ┌────┴────┐
    │ Repo A  │      │ Repo B  │    ...
    │ (GT v19)│      │ (GT v18)│
    └─────────┘      └─────────┘
```

### File Structure

```
~/.genius-cortex/
├── config.json                    # Global config
│   {
│     "repos_dir": "~/Projects",
│     "scan_patterns": ["**/CLAUDE.md", "**/.genius/state.json"],
│     "check_interval_hours": 6,
│     "notifications": "channels",  // "channels" | "native" | "none"
│     "dashboard_port": 4200
│   }
├── registry.json                  # Known repos + state
│   [
│     {
│       "path": "/Users/ben/Projects/my-app",
│       "name": "my-app",
│       "gt_version": "19.0.0",
│       "latest_gt": "19.0.0",
│       "last_activity": "2026-03-24T09:00:00Z",
│       "mode": "cli",
│       "health": "ok"
│     }
│   ]
├── behaviors/
│   ├── _index.json                # Active behaviors list
│   ├── prove-before-fix.md
│   ├── post-fix-audit.md
│   ├── read-before-write.md
│   ├── test-the-fix.md
│   ├── ask-dont-assume.md
│   ├── minimal-change.md
│   └── explain-then-code.md
├── memory/
│   ├── reflexes.md                # Cross-project dev reflexes
│   ├── preferences.md             # User preferences
│   ├── learnings.md               # Lessons learned
│   └── contacts.md                # Shared context about people/clients
├── dashboard/
│   ├── index.html                 # Single-page dashboard
│   ├── styles.css
│   └── app.js
└── mcp/
    ├── server.ts                  # MCP server for Claude Code
    └── package.json
```

---

## CLI Commands (MVP)

```bash
# Installation
npm install -g genius-cortex

# Initialize
cortex init                          # Creates ~/.genius-cortex/
cortex init --repos-dir ~/Projects   # Set repos directory

# Repo Management
cortex scan                          # Find all GT repos in repos_dir
cortex scan ~/other-folder           # Scan specific folder
cortex status                        # Show all repos + versions + health
cortex status my-app                 # Show specific repo

# Upgrades
cortex check                         # Check for GT updates
cortex upgrade my-app                # Upgrade specific repo
cortex upgrade --all                 # Upgrade all repos
cortex upgrade --all --dry-run       # Preview upgrades

# Behaviors
cortex behaviors list                # Show all behaviors (active/inactive)
cortex behaviors add <name>          # Create new behavior (opens $EDITOR)
cortex behaviors enable <name>       # Activate a behavior
cortex behaviors disable <name>      # Deactivate without deleting
cortex behaviors export              # Export all behaviors as JSON
cortex behaviors import <url|file>   # Import behaviors
cortex behaviors inject              # Write active behaviors to ~/.claude/CLAUDE.md

# Memory
cortex memory add "lesson learned"   # Add to cross-project memory
cortex memory search "supabase"      # Search memory
cortex memory show                   # Show all memory

# Dashboard
cortex dashboard                     # Start dashboard on localhost:4200
cortex dashboard --port 5000         # Custom port

# MCP
cortex mcp install                   # Add Cortex MCP to Claude Code config
cortex mcp start                     # Start MCP server
```

---

## Behaviors — Concrets (tirés des patterns réels de Ben)

### 1. prove-before-fix.md
```markdown
---
name: prove-before-fix
category: debugging
priority: critical
source: Ben's feedback — "je n'aime pas quand on part sur des hypothèses"
---

## Rule
When debugging, NEVER start fixing based on assumptions.

### Process
1. READ the relevant code and error messages
2. REPRODUCE the issue with a concrete test or command
3. IDENTIFY the root cause with evidence (stack trace, logs, test output)
4. EXPLAIN the cause before proposing a fix
5. Only THEN implement the fix

### Anti-pattern
❌ "I think the problem might be in the auth middleware, let me change it"
✅ "The stack trace shows `TypeError: user.id is undefined` at auth.ts:45. The user object comes from `getSession()` which returns null when the token is expired. Here's the reproduction: [command]. Fix: add null check before accessing user.id."
```

### 2. post-fix-audit.md
```markdown
---
name: post-fix-audit
category: debugging
priority: critical
source: Ben's feedback — "après avoir corrigé, on refait un mini audit"
---

## Rule
After EVERY fix, run a verification audit.

### Process
1. Apply the fix
2. Re-run the original failing test/reproduction
3. Run related tests to check for regressions
4. Review the diff — is the change minimal and clean?
5. Only mark as done when ALL checks pass

### Anti-pattern
❌ "Fixed! Moving on."
✅ "Fixed. Verified: original issue resolved ✓, related tests pass ✓, no regressions ✓, diff is minimal (3 lines changed) ✓"
```

### 3. no-rush-quality.md
```markdown
---
name: no-rush-quality
category: workflow
priority: high
source: Ben's feedback — "surtout ne rush pas", "prends le temps"
---

## Rule
Never rush. Quality over speed. Every time.

### Process
1. Understand the full scope BEFORE starting
2. Research if needed — don't guess
3. Build incrementally, test each step
4. Review your own work before delivering
5. If something feels wrong, stop and reassess

### Anti-pattern
❌ Delivering 7 versions in 2 hours (quantity over quality)
✅ Delivering 1 excellent version after proper research and iteration
```

### 4. verify-before-code.md
```markdown
---
name: verify-before-code
category: development
priority: critical
source: Memory 2026-03-15 — "toujours vérifier avant de coder"
---

## Rule
Before implementing anything, verify how the existing system works.

### Process
1. READ existing code that relates to what you're about to build
2. UNDERSTAND the current architecture and patterns
3. CHECK if similar functionality already exists
4. TEST the current behavior before modifying it
5. Only THEN start writing new code

### Anti-pattern
❌ Inventing a flow without checking how it currently works
✅ Reading the existing implementation, understanding the patterns, then building on top
```

### 5. cumulative-feedback.md
```markdown
---
name: cumulative-feedback
category: workflow
priority: critical
source: Ben's feedback — "tu te concentres sur les derniers feedbacks et t'oublies le reste"
---

## Rule
ALL feedback is cumulative. New feedback adds to previous feedback — it never replaces it.

### Process
1. When receiving new feedback, re-read ALL previous feedback
2. List ALL constraints that apply simultaneously
3. Check that your plan addresses ALL constraints, not just the latest ones
4. If constraints conflict, ask for clarification — don't silently drop old ones

### Anti-pattern
❌ Applying only the latest feedback, forgetting 5 previous rounds of input
✅ Maintaining a running list of all constraints and checking each one before delivering
```

---

## Injection Mechanism — How Behaviors Get Into Claude Code

### The Chain
```
cortex behaviors inject
    ↓
Reads ~/.genius-cortex/behaviors/*.md (active only)
    ↓
Generates a compiled block:
    ↓
Writes to ~/.claude/CLAUDE.md (user-level)
    ↓
Claude Code auto-loads ~/.claude/CLAUDE.md on EVERY session
    ↓
All behaviors active in ALL projects automatically
```

### Generated ~/.claude/CLAUDE.md Section
```markdown
<!-- GENIUS CORTEX BEHAVIORS — Auto-generated, do not edit manually -->
<!-- Last injected: 2026-03-24T09:00:00Z -->
<!-- Active behaviors: 5 -->

## 🧠 Cortex Behaviors

### [CRITICAL] Prove Before Fix
When debugging, NEVER start fixing based on assumptions. READ → REPRODUCE → IDENTIFY → EXPLAIN → only then FIX.

### [CRITICAL] Post-Fix Audit  
After EVERY fix: re-run failing test, run related tests, check regressions, review diff.

### [CRITICAL] Verify Before Code
Before implementing, READ existing code, UNDERSTAND patterns, CHECK if similar exists, TEST current behavior.

### [HIGH] No Rush Quality
Never rush. Understand scope → research → build incrementally → review → deliver.

### [CRITICAL] Cumulative Feedback
ALL feedback is cumulative. New feedback ADDS to previous — never replaces. Maintain running constraint list.

<!-- END CORTEX BEHAVIORS -->
```

### Auto-injection Options
1. **Manual** : `cortex behaviors inject` (run when you update behaviors)
2. **Git hook** : auto-inject on `git checkout` / `git pull` 
3. **Claude Code hook** : inject on session start via CC's hook system
4. **Watch mode** : `cortex behaviors watch` (re-inject on file change)

---

## Dashboard — Design

### Home View
```
┌─────────────────────────────────────────────────┐
│  🧠 Genius Cortex                    ⟳ Refresh  │
├─────────────────────────────────────────────────┤
│                                                  │
│  📊 5 repos · 3 up to date · 2 outdated         │
│                                                  │
│  ┌─────────────┬──────┬──────────┬────────────┐ │
│  │ Repo        │ Ver  │ Latest   │ Action     │ │
│  ├─────────────┼──────┼──────────┼────────────┤ │
│  │ ✅ my-app   │ v19  │ v19      │ Open       │ │
│  │ ⚠️ utopia   │ v17  │ v19      │ Upgrade ↑  │ │
│  │ ✅ artts    │ v19  │ v19      │ Open       │ │
│  │ ⚠️ cinefi   │ v16  │ v19      │ Upgrade ↑  │ │
│  │ ✅ beatblox │ v19  │ v19      │ Open       │ │
│  └─────────────┴──────┴──────────┴────────────┘ │
│                                                  │
│  [Upgrade All Outdated]  [Scan for New Repos]    │
│                                                  │
│  ─── Active Behaviors (5) ───────────────────── │
│  🔴 prove-before-fix   🔴 post-fix-audit        │
│  🔴 verify-before-code 🟠 no-rush-quality       │
│  🔴 cumulative-feedback                         │
│  [Manage Behaviors]                              │
│                                                  │
└─────────────────────────────────────────────────┘
```

---

## MCP Server — Tools Exposed to Claude Code

```typescript
// Tools available when Cortex MCP is installed
cortex_status()           // Show all repos + versions
cortex_check_updates()    // Check for GT updates
cortex_upgrade(repo?)     // Upgrade one or all repos
cortex_behaviors_list()   // List active behaviors
cortex_behaviors_add(name, content)  // Add new behavior
cortex_memory_search(query)          // Search cross-project memory
cortex_memory_add(content)           // Add to memory
cortex_inject()           // Re-inject behaviors into ~/.claude/CLAUDE.md
```

Usage dans Claude Code :
```
> Check if all my Genius Team repos are up to date
[calls cortex_status] → shows 5 repos, 2 outdated
> Upgrade them all
[calls cortex_upgrade] → runs upgrade on 2 repos
```

---

## Implementation Plan (MVP)

### Phase 1 — Core CLI (1 week)
- `cortex init`, `cortex scan`, `cortex status`
- Registry management (find repos, track versions)
- `cortex check`, `cortex upgrade`
- npm package: `genius-cortex`

### Phase 2 — Behaviors (3-4 days)
- Behaviors CRUD (`add`, `enable`, `disable`, `list`)
- Injection into `~/.claude/CLAUDE.md`
- 7 starter behaviors (from Ben's patterns above)
- `cortex behaviors export/import`

### Phase 3 — Memory (2-3 days)
- Cross-project memory store
- `cortex memory add/search/show`
- Auto-injection of relevant memory on session start

### Phase 4 — Dashboard (3-4 days)
- Local web server on port 4200
- Single-page app showing repos, behaviors, memory
- Upgrade buttons
- Behaviors editor

### Phase 5 — MCP Server (2-3 days)
- MCP tools for Claude Code integration
- Auto-install into CC config
- Test from within CC sessions

**Total MVP : ~3 weeks**

---

## Scores (Autoresearch)

| Criterion | Score | Notes |
|-----------|-------|-------|
| Feature completeness | 9/10 | Covers all Ben's asks |
| Technical feasibility | 9/10 | Node.js, familiar stack |
| Differentiation | 9/10 | Nobody does multi-repo + behaviors |
| User experience | 8/10 | CLI + dashboard + MCP = 3 access points |
| Implementation effort | 7/10 | ~3 weeks for MVP |
| Scalability | 8/10 | File-based, no DB needed |
| Ecosystem fit | 9/10 | Fits perfectly with GT + OpenClaw + Channels |

**Overall: 8.4/10**

### What could push to 9+:
- Tauri menubar app instead of web dashboard (native feel)
- Behavior marketplace with community
- Auto-detection of behavior violations (lint-like)
