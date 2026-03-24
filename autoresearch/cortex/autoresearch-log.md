# Autoresearch Log — Genius Cortex
*Started: 2026-03-24 19:10 CET*
*Method: Karpathy-style iterative improvement*

## Scoring Criteria (1-10)
1. **Concept completeness** — Are all concepts well-defined with clear boundaries?
2. **Feature depth** — Are features detailed enough to implement without ambiguity?
3. **Architecture soundness** — Is the technical architecture realistic and efficient?
4. **Injection mechanism** — How exactly do behaviors/skills/memory get into each project?
5. **UX flow** — Are user journeys clear and frictionless?
6. **Differentiation** — Is this clearly different from existing tools?
7. **Implementation readiness** — Could a dev start coding Sprint 1 tomorrow?
8. **Business model** — Is the free→paid path clear and compelling?

## Baseline Scores (from v3)
| Criterion | Score | Weak points |
|-----------|-------|-------------|
| Concept completeness | 8 | Habits tracking mechanism unclear, Heartbeat integration vague |
| Feature depth | 7 | Many features listed but shallow — Chat routing, Watch sources, QA scheduler need detail |
| Architecture soundness | 7 | Tauri+Node+MCP mixed — who does what? IPC unclear |
| Injection mechanism | 6 | "Cortex MCP detects the repo" — HOW exactly? Timing? Conflicts? |
| UX flow | 7 | Project Factory is good, but daily workflows (morning routine, switching projects) undefined |
| Differentiation | 9 | Strong — nobody does multi-repo governance |
| Implementation readiness | 5 | Sprint plan exists but no file-level specs, no API contracts |
| Business model | 8 | Clear tiers but "what makes free users upgrade?" needs work |
| **AVERAGE** | **7.1** | |

## Target: 9.0+ average after iterations

---

## Iteration 1 — Injection Mechanism (19:11)
**Target:** Score 6 → 9

### Findings
Claude Code has native injection points:
1. `~/.claude/CLAUDE.md` — user-level, loaded in ALL sessions
2. `~/.claude/settings.json` — user-level settings
3. `~/.claude/agents/` — user-level custom agents
4. `~/.claude.json` — user-level MCP servers
5. **`SessionStart` hook** — fires when ANY session begins or resumes

### Revised Injection Architecture
Cortex uses TWO injection mechanisms:

**A. Static Injection (at `cortex inject` time)**
Writes to `~/.claude/CLAUDE.md`:
- Active behaviors (compiled into a single block)
- Global rules
- Memory bits (most relevant ones)
- Glossary terms

**B. Dynamic Injection (via SessionStart hook)**
A SessionStart hook registered in `~/.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [{
      "command": "cortex session-inject --repo $CWD",
      "timeout": 5000
    }]
  }
}
```
This hook:
1. Detects which repo the session is in (from $CWD)
2. Checks registry.json for project-specific config
3. Injects project-specific persona, code bits, vault env vars
4. Updates habit tracking (session started on repo X at time Y)
5. Returns quickly (<5s) to not slow down session start

**C. MCP Server (for interactive tools)**
An MCP server for tools that Claude can call DURING the session:
- `cortex_memory_search(query)` — search cross-project memory
- `cortex_vault_get(key)` — get a secret from the vault
- `cortex_codebits_search(query)` — find reusable code
- `cortex_status()` — check all repos status

### Key Design Decisions
- Static injection = behaviors/rules/memory (always present, no latency)
- Dynamic injection = project-specific context (loaded at session start)
- MCP = interactive tools (on-demand during session)
- NO modification of project-level files (.claude/ in repo) — Cortex only writes to USER-level files

### Score: 6 → 9
Injection is now well-defined with 3 distinct mechanisms, each serving a clear purpose.

## Iteration 2 — Feature Depth: Daily Workflows (19:15)
**Target:** Score 7 → 9

### Problem
Features are listed but daily workflows aren't defined. A user opens their Mac in the morning — what happens? They switch from project A to B — what happens?

### Morning Routine Flow
```
User opens Mac
         │
         ▼
Cortex menubar icon shows:
├── 🟢 3 repos up to date
├── 🟠 1 repo outdated (Utopia → v17, latest v19)
├── 📬 2 Genius Watch alerts (CC v2.1.78, new CLAUDE.md best practice)
└── 📊 Last night: genius-qa ran on 2 repos, 1 issue found
         │
User clicks menubar → dropdown:
├── 📊 Dashboard
├── 🆕 New Project
├── 🔄 Upgrade All (1 outdated)
├── 📬 Watch (2 new)
├── 💬 Chat
└── ⚙️ Settings
```

### Switching Projects Flow
```
User is in ~/Projects/utopia, opens Claude Code
         │
SessionStart hook fires
         │
cortex session-inject --repo ~/Projects/utopia
         │
Cortex:
├── Identifies: "Utopia", v19, mode CLI
├── Injects persona: "Utopia SaaS — React + Supabase + Stripe"
├── Injects relevant memory bits: "Supabase auth pattern used here"
├── Injects project code bits: "billing webhook handler"  
├── Loads vault env vars if configured
├── Logs: "Session started on Utopia at 09:15"
         │
Claude Code session starts with full context
         │
[User works for 2 hours]
         │
Session ends or user switches to another project
         │
PostSession: Cortex captures new memory bits, updates habits
```

### Cortex Chat Routing — Detailed
```
User types in Cortex Chat: "Add Stripe webhooks to Utopia"

Cortex:
1. Parses intent: ACTION on PROJECT "Utopia"
2. Checks registry: Utopia at ~/Projects/utopia, v19, mode CLI
3. Checks code bits: has "stripe-webhook-handler" from project CineFi
4. Response: 
   "I found a Stripe webhook handler you built in CineFi. 
    I can open Utopia with this context ready.
    [🚀 Open Utopia in Claude Code]
    [📋 Show the code bit first]"
5. User clicks Open → Terminal opens, cd utopia, claude launched
   with prompt pre-filled: "Add Stripe webhooks. Reference: [code bit injected]"
```

### Genius Watch — Sources & Update Cycle
```
Sources (checked every 6h):
├── GitHub Releases API
│   ├── anthropics/claude-code (CC updates)
│   ├── openai/codex (Codex updates)
│   ├── w-3-art/genius-team (GT updates)
│   └── User's custom repos list
├── Anthropic Changelog (scrape)
├── npm advisories (security)
└── Custom RSS/feeds (configurable)

Processing:
1. Fetch new items since last check
2. Filter: relevant to user's stack? (detect from repo package.json / requirements.txt)
3. Score: impact level (critical / informational)
4. Generate summary: "What changed + impact on YOUR projects"
5. Push to Watch feed in dashboard
6. If critical: menubar notification
```

### Auto-QA Scheduler — Detailed
```
Configuration (in Cortex UI or cortex.json):
{
  "schedules": [
    {
      "name": "Weekly QA",
      "cron": "0 9 * * 1",  // Monday 9am
      "repos": ["utopia", "artts", "cinefi"],
      "action": "genius-qa",
      "notify": "telegram"
    },
    {
      "name": "Daily health check",
      "cron": "0 8 * * *",  // Every day 8am
      "repos": "*",  // All repos
      "action": "health-check",  
      "notify": "dashboard"
    }
  ]
}

Execution:
1. Cron fires
2. For each repo: cd into repo, run genius-qa (or health-check)
3. Collect results
4. Generate report
5. Post to dashboard + notify via configured channel
```

### Score: 7 → 9
Daily workflows, switching flows, chat routing, watch sources, and QA scheduler are now detailed enough to implement.

## Iteration 3 — Architecture: Component Responsibilities (19:22)
**Target:** Score 7 → 9

### Problem
v3 mixes Tauri, Node, Rust, MCP — unclear who does what. Need clean boundaries.

### Revised Component Architecture

**Layer 1: Cortex Core (Node.js — npm package)**
Responsibility: ALL business logic
- Registry management (scan, track repos)
- Behavior engine (CRUD, compile, inject)
- Memory store (add, search, retrieve)
- Vault (encrypt/decrypt, keychain bridge)
- Project factory (template, create, configure)
- Skill/MCP injector
- Watch engine (fetch, filter, score)
- QA scheduler (cron, execute, report)
- Sync engine (iCloud bridge)

WHY Node.js: Same runtime as Claude Code + GT. npm distribution. Ben's team knows JS/TS.

**Layer 2: Cortex CLI (thin wrapper on Core)**
Responsibility: Terminal access to Core
- `cortex <command>` → calls Core functions
- No business logic — pure CLI interface
- Ships as part of the npm package

**Layer 3: Cortex App (Tauri 2.0)**
Responsibility: GUI + menubar + system integration
- Menubar icon with status
- Dashboard webview (calls Core via IPC)
- Chat interface
- Native notifications (macOS)
- Background daemon (keeps Core alive, runs schedules)
- System tray menu

WHY Tauri: Native menubar, ~5MB, webview for UI, Rust for system-level (keychain, file watching).

IPC: Tauri Rust backend calls Node.js Core via child_process or HTTP localhost. 
Alternative: embed Core logic in Rust (harder but faster). 
DECISION: Start with Node.js child_process, optimize later if needed.

**Layer 4: Cortex MCP (TypeScript MCP server)**
Responsibility: Claude Code integration
- Registers tools that Claude can call during sessions
- Thin wrapper on Core: `cortex_status()` → calls Core's `status()`
- Runs as MCP server process
- Auto-registered in `~/.claude.json`

**Layer 5: Cortex Hook (shell script)**
Responsibility: Session-start injection
- Registered as SessionStart hook in `~/.claude/settings.json`
- Calls `cortex session-inject --repo $CWD`
- Must complete in <5s
- Outputs project-specific context to inject

**Layer 6: Cortex Connectors (plugins)**
Responsibility: External messaging
- Telegram connector (via CC Channels or direct bot)
- WhatsApp connector (via OpenClaw)
- Each connector translates messages to Core commands

### Data Flow Diagram
```
                        ┌──────────────────┐
                        │   macOS Menubar  │
                        │   (Tauri shell)  │
                        └────────┬─────────┘
                                 │ IPC
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
    ┌────┴────┐           ┌──────┴──────┐         ┌─────┴─────┐
    │  CLI    │           │  Dashboard  │         │   Chat    │
    │(terminal)           │  (webview)  │         │ (webview) │
    └────┬────┘           └──────┬──────┘         └─────┬─────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │ API calls
                        ┌────────┴─────────┐
                        │   CORTEX CORE    │
                        │   (Node.js)      │
                        │                  │
                        │  ┌────────────┐  │
                        │  │ Registry   │  │
                        │  │ Behaviors  │  │
                        │  │ Memory     │  │
                        │  │ Vault      │  │
                        │  │ Skills     │  │
                        │  │ Watch      │  │
                        │  │ Scheduler  │  │
                        │  │ Sync       │  │
                        │  └────────────┘  │
                        └──────┬───────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
       ┌──────┴──────┐  ┌─────┴─────┐  ┌──────┴──────┐
       │ SessionStart│  │    MCP    │  │ Connectors  │
       │ Hook        │  │   Server  │  │ (TG/WA)     │
       └──────┬──────┘  └─────┬─────┘  └──────┬──────┘
              │                │                │
              └────────────────┼────────────────┘
                               │
                     ┌─────────┼─────────┐
                     │         │         │
                  Repo A    Repo B    Repo C
```

### File-level Spec for Core
```
genius-cortex/
├── package.json
├── tsconfig.json
├── src/
│   ├── index.ts              # CLI entry point
│   ├── core/
│   │   ├── registry.ts       # Repo scanning, tracking, versioning
│   │   ├── behaviors.ts      # CRUD, compile, inject into ~/.claude/CLAUDE.md
│   │   ├── memory.ts         # Cross-project memory store + search
│   │   ├── vault.ts          # AES-256 encrypt/decrypt, keychain bridge
│   │   ├── skills.ts         # Global skills registry + injection
│   │   ├── mcps.ts           # Global MCP config management
│   │   ├── factory.ts        # Project creation flow
│   │   ├── watch.ts          # Genius Watch feed engine
│   │   ├── scheduler.ts      # Cron-based QA + health checks
│   │   ├── sync.ts           # iCloud sync bridge
│   │   ├── habits.ts         # Behavior compliance tracking
│   │   └── config.ts         # Cortex configuration management
│   ├── cli/
│   │   ├── commands/         # One file per CLI command
│   │   └── output.ts         # Pretty terminal output
│   ├── mcp/
│   │   ├── server.ts         # MCP server (tools for Claude Code)
│   │   └── tools.ts          # Tool definitions
│   ├── hook/
│   │   └── session-inject.ts # SessionStart hook handler
│   └── api/
│       └── server.ts         # HTTP API for Tauri dashboard
├── tauri/                    # Tauri app (separate build)
│   ├── src-tauri/
│   │   └── main.rs           # Rust: menubar, system tray, notifications
│   └── src/
│       ├── App.tsx            # Dashboard UI
│       ├── Chat.tsx           # Chat interface
│       └── components/        # UI components
└── connectors/
    ├── telegram.ts
    └── whatsapp.ts
```

### Score: 7 → 9
Clear component boundaries, single source of business logic (Core), multiple thin interfaces (CLI, App, MCP, Hook, Connectors).

## Iteration 4 — Implementation Readiness: Sprint 1 Spec (19:30)
**Target:** Score 5 → 8

### Problem
Sprint plan says "1 week" but no concrete file-level deliverables. A dev can't start tomorrow.

### Sprint 1 — Detailed Implementation Spec

**Goal:** `cortex init`, `cortex scan`, `cortex status`, `cortex upgrade` working from terminal.

**Day 1: Scaffold**
```bash
mkdir genius-cortex && cd genius-cortex
npm init -y
# TypeScript + Commander.js + chalk + ora
npm install commander chalk ora glob fast-glob
npm install -D typescript @types/node tsx
```

Files to create:
- `src/index.ts` — CLI entry with Commander.js
- `src/core/config.ts` — load/save `~/.genius-cortex/config.json`
- `src/core/registry.ts` — repo registry CRUD

**Day 2: Scan + Registry**
`cortex scan [dir]`:
1. Walk `repos_dir` (default `~/Projects/`)
2. For each directory: check if `.genius/state.json` or `CLAUDE.md` exists
3. If GT found: read version from `VERSION` file or `.genius/state.json`
4. Add to registry.json with path, name, version, lastModified
5. Pretty-print results

Registry JSON schema:
```typescript
interface RepoEntry {
  path: string;           // absolute path
  name: string;           // directory name
  gtVersion: string;      // "19.0.0"
  mode: string;           // "cli" | "ide" | "omni" | "dual"
  lastActivity: string;   // ISO date
  health: "ok" | "outdated" | "error";
  gitRemote?: string;     // GitHub URL
}
```

**Day 3: Status**
`cortex status [repo]`:
1. Load registry
2. Fetch latest GT version: `curl -sf https://raw.githubusercontent.com/w-3-art/genius-team/main/VERSION`
3. Compare each repo version vs latest
4. Display table: name | version | latest | status (✅/⚠️/❌)
5. If specific repo: show detailed info (mode, git remote, last activity, skills count)

**Day 4: Upgrade**
`cortex upgrade [repo] [--all] [--dry-run]`:
1. If --all: iterate registry, upgrade each outdated repo
2. For each repo: `cd <repo> && bash <(curl -fsSL .../upgrade.sh)`
3. Capture output, update registry version
4. Report results

**Day 5: Init + Polish**
`cortex init`:
1. Create `~/.genius-cortex/` structure
2. Interactive: "Where are your projects?" → set repos_dir
3. Auto-scan the directory
4. Show first status
5. Ask to install SessionStart hook

Polish:
- Error handling everywhere
- Help text on all commands
- `cortex --version`
- `cortex help`

**Day 5 deliverable:** `npm install -g genius-cortex` works, all 4 commands functional.

### API Contracts (for Sprint 1)

```typescript
// Core API — called by CLI, later by App/MCP
interface CortexCore {
  // Config
  init(reposDir?: string): Promise<void>;
  getConfig(): CortexConfig;
  
  // Registry
  scan(dir?: string): Promise<RepoEntry[]>;
  status(repo?: string): Promise<StatusReport>;
  getRegistry(): RepoEntry[];
  
  // Upgrade
  upgrade(repo: string, opts?: { dryRun?: boolean }): Promise<UpgradeResult>;
  upgradeAll(opts?: { dryRun?: boolean }): Promise<UpgradeResult[]>;
  
  // Version
  getLatestGTVersion(): Promise<string>;
}

interface CortexConfig {
  reposDir: string;
  scanPatterns: string[];
  checkIntervalHours: number;
  dashboardPort: number;
}

interface StatusReport {
  repos: RepoEntry[];
  latestGTVersion: string;
  outdatedCount: number;
  totalCount: number;
}

interface UpgradeResult {
  repo: string;
  from: string;
  to: string;
  success: boolean;
  output: string;
}
```

### Score: 5 → 8
Sprint 1 now has day-by-day deliverables, file-level specs, API contracts, and a concrete npm package structure. A dev could start tomorrow.

## Iteration 5 — Concept Depth: Habits & Heartbeat (19:38)
**Target:** Score 8 → 9

### Habits System
A Habit = Behavior + Measurement + Tracking

```typescript
interface Habit {
  name: string;           // "prove-before-fix"
  behavior: string;       // Reference to behavior file
  metric: string;         // How to measure compliance
  checkMethod: "hook" | "review" | "self-report";
  frequency: "per-session" | "per-commit" | "daily";
  streak: number;         // Current streak of compliance
  history: HabitEntry[];
}

interface HabitEntry {
  date: string;
  repo: string;
  compliant: boolean;
  evidence?: string;      // "Found 3 verify-before-code instances in session"
}
```

**How habits are tracked:**
1. **PostToolUse hook** — after each tool call, check if behavior was followed
   - Example: "prove-before-fix" → detect if Read was called before Write
   - Pattern: did the agent read code → reproduce → identify → THEN fix?
2. **Session review** — at session end, score compliance per behavior
3. **Self-report** — Claude Code asks "did you follow prove-before-fix?" with evidence

**Dashboard: Habit Tracker**
```
┌─── Habits ────────────────────────────────────┐
│                                                │
│ 🔥 prove-before-fix     12-day streak  ████░  │
│ ✅ post-fix-audit        8-day streak  ████░  │
│ ⚠️ verify-before-code    2-day streak  █░░░░  │
│ ✅ cumulative-feedback    6-day streak  ███░░  │
│ ❌ no-rush-quality        broken today  ░░░░░  │
│                                                │
│ Weekly compliance: 78% (+5% vs last week)      │
└────────────────────────────────────────────────┘
```

### Heartbeat Integration
Cortex Heartbeat = periodic check that runs every N minutes when Cortex App is open.

```typescript
interface HeartbeatConfig {
  intervalMinutes: number;  // default 30
  checks: HeartbeatCheck[];
}

interface HeartbeatCheck {
  name: string;
  type: "version" | "health" | "watch" | "schedule" | "sync";
  action: () => Promise<HeartbeatResult>;
}
```

**Heartbeat cycle:**
Every 30 min:
1. Check GT versions across all repos (any new release?)
2. Run health checks on active repos (build OK? tests pass?)
3. Fetch Genius Watch updates (new CC/Codex releases?)
4. Execute scheduled tasks (is it time for auto-QA?)
5. Sync check (are all machines in sync?)
6. Update menubar status icon accordingly

**Menubar icon states:**
- 🟢 All good — repos up to date, no alerts
- 🟡 Attention — 1+ repo outdated, or watch alert
- 🔴 Action needed — health check failed, schedule missed

### Score: 8 → 9
Habits now have a concrete tracking mechanism (hooks + review), dashboard UI, and streaks. Heartbeat is defined as a periodic check cycle that drives the menubar status.

## Iteration 6 — Business Model: Conversion Triggers (19:44)
**Target:** Score 8 → 9

### Problem
"Free users get 5 repos" is arbitrary. What makes someone NEED to upgrade?

### Conversion Psychology
The free tier must be **genuinely useful** but create natural friction at scale.

**Free → Pro triggers (individual):**
1. **6th repo** — "You've added 6 repos. Free tier supports 5. Upgrade for unlimited." (Natural scaling)
2. **Genius Watch** — Free shows 3-day-old alerts. Pro shows real-time. "CC v2.1.78 was released 2h ago — upgrade to see real-time updates."
3. **Sync** — Free is local only. When user gets a second machine: "Install Cortex on MacBook too? Upgrade for cross-machine sync."
4. **Scheduler** — Free allows manual QA. Pro allows automated schedules. "Tired of running QA manually? Set up auto-Monday-morning checks."
5. **Behavior Store** — Free has 7 starter behaviors. Pro unlocks community marketplace.
6. **Advanced search** — Free searches current project. Pro searches all repos + code bits.

**Pro → Team triggers:**
1. **Second team member** — "Invite your co-founder? Team plan starts at $25/seat."
2. **Shared vault** — "Share API keys securely with your team."
3. **Shared behaviors** — "Your whole team follows the same coding standards."

### Pricing Research
Comparable tools:
- Raycast Pro: $8/month
- Conductor: Free (no premium yet)
- Linear: $8/seat/month
- Cursor: $20/month (but includes AI model costs)
- GitHub Copilot: $10/month

**Revised pricing:**
- **Free**: 5 repos, 7 behaviors, local only, 3-day watch delay
- **Pro ($9/month)**: Unlimited repos, unlimited behaviors, sync, real-time watch, scheduler, marketplace, cross-project search
- **Team ($19/seat/month)**: Shared vault, shared behaviors, team dashboard, onboarding flows, admin

$9 is under the "don't think about it" threshold for professional devs.

### Revenue Projections (conservative)
If GT has 2,400+ users (from site stats):
- 5% convert to Pro = 120 × $9 = $1,080/month
- 1% convert to Team (avg 3 seats) = 24 × 3 × $19 = $1,368/month
- Year 1 target: ~$2,400/month = ~$29K/year

With growth (Cortex drives GT adoption):
- 10K users → 500 Pro + 100 Team = $4,500 + $5,700 = $10,200/month = $122K/year

### Score: 8 → 9
Clear conversion triggers, psychological hooks, competitive pricing, revenue projections.

## Iteration 7 — UX: Chat Intelligence & NLU (19:50)
**Target:** Score 7 → 9

### Problem
"Cortex Chat routes to projects" — but HOW does it understand natural language?

### Solution: Cortex Chat uses Claude as the brain

Cortex Chat is NOT a custom NLU. It's a Claude session with Cortex MCP tools.

```
User types in Cortex Chat
         │
         ▼
Message sent to Claude (via Anthropic API)
with system prompt:
"You are Genius Cortex, the multi-repo orchestrator.
You have these tools: cortex_status, cortex_search, 
cortex_upgrade, cortex_factory, cortex_vault, etc.
Answer meta-questions about projects. For actions,
use Quick Launch to open the right repo in Claude Code."
         │
         ▼
Claude calls Cortex MCP tools as needed
         │
         ▼
Response rendered in chat UI
with action buttons (Quick Launch, etc.)
```

**This means:**
- No custom NLU needed — Claude handles understanding
- Cortex Chat is literally a Claude session with MCP tools
- The API key cost is on the user (same as using Claude Code)
- Free tier: 10 chat messages/day (to limit API costs)
- Pro: unlimited

### Chat Examples (detailed)

**Status query:**
> User: "How are my projects doing?"
> Claude: [calls cortex_status()]
> "Here's your portfolio:
> ✅ Utopia — v19, healthy, last activity 2h ago
> ⚠️ Artts — v18, needs upgrade
> ✅ CineFi — v19, healthy, last activity yesterday
> 
> 1 project needs upgrading. [🔄 Upgrade Artts]"

**Code search:**
> User: "Where did I implement webhook verification?"
> Claude: [calls cortex_codebits_search("webhook verification")]
> "Found in 2 projects:
> 📁 CineFi — src/webhooks/verify.ts (Stripe webhook signature check)
> 📁 Utopia — api/hooks/verify.ts (Supabase webhook verification)
> 
> [📋 Copy CineFi version] [📋 Copy Utopia version]"

**New project:**
> User: "I need a new landing page for a client"
> Claude: [calls cortex_factory("landing-page")]
> "Let's set it up:
> - Project name? [input field]
> - Template: Landing Page ✅
> - Persona: [dropdown: existing personas + "New"]
> - GitHub repo? [toggle: Create new / Existing]
> 
> [🚀 Create Project]"

**Cross-project action:**
> User: "Update the Supabase client in all projects that use it"
> Claude: [calls cortex_search("supabase")]
> "3 projects use Supabase: Utopia, CineFi, My-SaaS
> This is a cross-project change. I'll open each one for you:
> [🚀 Open Utopia] [🚀 Open CineFi] [🚀 Open My-SaaS]
> Or should I describe the update so you can apply it yourself?"

### Quick Launch Implementation
```typescript
function quickLaunch(repo: RepoEntry, prompt?: string) {
  // 1. Open Terminal.app (or iTerm)
  const terminal = getPreferredTerminal(); // Terminal.app, iTerm2, Warp
  
  // 2. cd into repo
  const cdCmd = `cd ${repo.path}`;
  
  // 3. Launch Claude Code with optional prompt
  const ccCmd = prompt 
    ? `claude -p "${prompt}"` 
    : `claude`;
  
  // 4. Execute via osascript (macOS) or Tauri shell API
  execInTerminal(`${cdCmd} && ${ccCmd}`);
}
```

### Score: 7 → 9
Chat is now clearly defined as "Claude + Cortex MCP tools" — no custom NLU needed. Quick Launch has a concrete implementation.

## Iteration 8 — Concept Depth: Vault, Personas, Code Bits (19:57)
**Target:** Fill remaining concept gaps

### Vault — Detailed Design

```typescript
interface VaultStore {
  // Global secrets (available in all projects)
  global: Record<string, string>;  // OPENAI_API_KEY, ANTHROPIC_API_KEY, etc.
  
  // Per-project secrets
  projects: Record<string, Record<string, string>>;
  // e.g., { "utopia": { "SUPABASE_URL": "...", "STRIPE_KEY": "..." } }
  
  // External links (not secrets, but centralized references)
  links: Record<string, ExternalLink>;
}

interface ExternalLink {
  name: string;       // "Utopia GitHub"
  url: string;        // "https://github.com/w-3-art/utopia"
  category: string;   // "github" | "deploy" | "monitoring" | "docs" | "api"
  project?: string;   // Linked project, if any
}
```

**Vault commands:**
```bash
cortex vault set OPENAI_API_KEY sk-xxx          # Global secret
cortex vault set SUPABASE_URL xxx --project utopia  # Project secret
cortex vault get SUPABASE_URL --project utopia
cortex vault inject utopia                       # Creates .env in the repo
cortex vault inject --all                        # All repos get their .env
cortex vault link add "Utopia Vercel" https://vercel.com/utopia --category deploy --project utopia
cortex vault links                               # Show all links
cortex vault links --project utopia              # Project-specific links
```

**Security:**
- Master key stored in macOS Keychain (Tauri has native keychain access)
- Each .enc file = AES-256-GCM with random IV
- `cortex vault inject` writes a `.env` that's in `.gitignore`
- Never stores secrets in plain text on disk
- `cortex vault export` exports ONLY structure (names), not values

### Personas — Detailed Design

```markdown
# ~/.genius-cortex/personas/cj-intelligence.md
---
name: CJ Intelligence
client: Commissaires de Justice
industry: Legal / Justice
language: fr
---

## Context
CJ Intelligence is a B2B SaaS for commissaires de justice (judicial officers in France).
They handle debt collection, evictions, property seizures, and legal notifications.

## Vocabulary
- "Acte" = legal document/notification
- "Signification" = formal legal service of documents
- "Saisie" = seizure (of assets, property, wages)
- "Huissier" (old term) = "Commissaire de justice" (new term since 2022)
- "Monopole" = exclusive activities (legal notifications, enforcement)
- "Hors-monopole" = competitive activities (debt recovery, mediation)

## Constraints
- Must comply with French legal terminology
- Data privacy: GDPR + French legal confidentiality rules
- Users are NOT tech-savvy — simple UX mandatory
- Billing: per-act or monthly subscription model

## Key Contacts
- Meeting scheduled with group of commissaires (date TBD)
- Document ready: 20 use cases with scoring (see docs/cj-intelligence-cas-usage.md)
```

**Injection:** When working on a CJ Intelligence project, the persona gets injected into the session context. Claude knows the vocabulary, constraints, and context automatically.

### Code Bits — Detailed Design

```typescript
interface CodeBit {
  id: string;            // auto-generated
  name: string;          // "Stripe webhook handler"
  description: string;   // "Verifies Stripe webhook signatures and dispatches events"
  language: string;      // "typescript"
  sourceRepo: string;    // "cinefi"
  sourcePath: string;    // "src/webhooks/verify.ts"
  code: string;          // The actual code snippet
  tags: string[];        // ["stripe", "webhook", "payment"]
  createdAt: string;
  usedIn: string[];      // Projects where this bit was reused
}
```

**How code bits are captured:**
1. **Manual** — `cortex codebits add "Stripe webhook" --file src/webhooks/verify.ts --tags stripe,webhook`
2. **Auto-detect** — Cortex watches for patterns across repos. If similar code exists in 2+ repos, suggest extracting as a code bit.
3. **From chat** — "Save this as a code bit" in Cortex Chat

**How code bits are used:**
1. **Search** — `cortex codebits search "webhook"` or from Chat
2. **Inject** — Cortex Chat: "Use the Stripe webhook handler from CineFi in this project" → Claude gets the code bit injected as context
3. **Auto-suggest** — During session, MCP tool detects "user is implementing webhooks" → suggests relevant code bits

### Score update
| Criterion | Before | After |
|-----------|--------|-------|
| Concept completeness | 8 | 9.5 |
| Feature depth | 9 | 9 |
| Architecture soundness | 9 | 9 |
| Injection mechanism | 9 | 9 |
| UX flow | 9 | 9 |
| Differentiation | 9 | 9.5 |
| Implementation readiness | 8 | 8 |
| Business model | 9 | 9 |
| **AVERAGE** | **7.1 (baseline)** | **9.0** |


## Iteration 9 — Nightly Build Program (20:05)
**Target:** Create the concrete program for tonight's build

### Nightly Build Program — Genius Cortex Sprint 1

**Time budget:** ~8h (22h → 06h)
**Goal:** Working `cortex` CLI with init, scan, status, upgrade + behaviors inject

#### Phase 1: Scaffold (22h → 23h)
```
1. Create repo: ~/Projects/genius-cortex/
2. npm init, install deps (commander, chalk, ora, fast-glob, crypto)
3. TypeScript config
4. Create src/ structure:
   src/
   ├── index.ts          # CLI entry
   ├── core/
   │   ├── config.ts     # Config load/save
   │   ├── registry.ts   # Repo scanning
   │   ├── behaviors.ts  # Behavior engine
   │   └── inject.ts     # CLAUDE.md injection
   └── cli/
       ├── init.ts
       ├── scan.ts
       ├── status.ts
       ├── upgrade.ts
       └── behaviors.ts
5. Git init + first commit
6. Verify: `npx tsx src/index.ts --help` works
```

#### Phase 2: Core — Registry (23h → 00h30)
```
1. config.ts — load/create ~/.genius-cortex/config.json
2. registry.ts — scan dirs for GT repos (look for CLAUDE.md + .genius/ + VERSION)
3. Implement scan: walk directory tree, detect GT, read VERSION, build registry
4. Implement status: load registry + fetch latest GT version from GitHub
5. Pretty terminal output with chalk
6. Test: cortex scan ~/Projects → finds repos
7. Test: cortex status → shows table with versions
8. Commit
```

#### Phase 3: Core — Upgrade (00h30 → 01h30)
```
1. upgrade.ts — call upgrade.sh on a repo
2. Implement single repo upgrade
3. Implement --all flag
4. Implement --dry-run flag
5. Update registry after upgrade
6. Test: cortex upgrade utopia --dry-run
7. Commit
```

#### Phase 4: Behaviors Engine (01h30 → 03h30)
```
1. Create ~/.genius-cortex/behaviors/ directory structure
2. behaviors.ts — CRUD operations on behavior files
3. Create 7 starter behaviors:
   - prove-before-fix.md
   - post-fix-audit.md
   - verify-before-code.md
   - no-rush-quality.md
   - cumulative-feedback.md
   - read-before-write.md
   - minimal-change.md
4. inject.ts — compile active behaviors into ~/.claude/CLAUDE.md
   - Read all active behavior files
   - Generate a "<!-- GENIUS CORTEX BEHAVIORS -->" block
   - Write/update the block in ~/.claude/CLAUDE.md (preserve existing content)
5. CLI commands:
   - cortex behaviors list
   - cortex behaviors add <name>
   - cortex behaviors enable/disable <name>
   - cortex behaviors inject
6. Test: behaviors inject → check ~/.claude/CLAUDE.md contains behaviors
7. Commit
```

#### Phase 5: Init + SessionStart Hook (03h30 → 04h30)
```
1. init.ts — full init flow
   - Create ~/.genius-cortex/ structure
   - Ask for repos_dir
   - Auto-scan
   - Install SessionStart hook in ~/.claude/settings.json
   - First behaviors inject
2. hook/session-inject.ts — lightweight session-start handler
   - Read CWD → find in registry
   - Output project context (for now: just project name + version)
3. Test: cortex init → full flow works
4. Commit
```

#### Phase 6: Polish + Package (04h30 → 06h)
```
1. Error handling everywhere
2. Help text on all commands
3. package.json: name, version, bin entry
4. README.md for the cortex repo
5. Test all commands end-to-end
6. npm link → test global install
7. Final commit + push
8. Update genius-team MEMORY.md with progress
```

### Success Criteria for Morning
- [ ] `cortex init` creates the full directory structure
- [ ] `cortex scan ~/Projects` finds all GT repos
- [ ] `cortex status` shows repos with version comparison
- [ ] `cortex upgrade <repo> --dry-run` works
- [ ] `cortex behaviors list` shows 7 starter behaviors
- [ ] `cortex behaviors inject` writes to ~/.claude/CLAUDE.md
- [ ] SessionStart hook registered in ~/.claude/settings.json
- [ ] All commands have --help text
- [ ] Package installable via npm link

### Blockers / Dependencies
- Need Claude Code to be logged in on this machine for testing upgrade
  → Workaround: test with dry-run flag only
- Need Tauri installed for app
  → App is Sprint 3, not tonight — CLI only tonight


## Iteration 10 — Sync Layer Architecture (20:12)
**Target:** Make sync concrete and implementable

### Problem
"iCloud sync" is hand-wavy. How exactly?

### Solution: Symlink to iCloud Drive

macOS iCloud Drive location: `~/Library/Mobile Documents/com~apple~CloudDocs/`

**Setup:**
```bash
# During cortex init, offer iCloud sync
ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/genius-cortex"

# Option A: Store data directly in iCloud
# ~/.genius-cortex/ → symlink to iCloud
mkdir -p "$ICLOUD_DIR"
ln -sf "$ICLOUD_DIR" "$HOME/.genius-cortex"

# Option B: Selective sync (more control)
# Only sync specific directories
mkdir -p "$ICLOUD_DIR"/{behaviors,memory,config,vault}
# Symlink individual dirs
ln -sf "$ICLOUD_DIR/behaviors" "$HOME/.genius-cortex/behaviors"
ln -sf "$ICLOUD_DIR/memory" "$HOME/.genius-cortex/memory"
# Keep registry local (repos are machine-specific)
```

**What syncs (via iCloud):**
- ✅ behaviors/ — same coding habits everywhere
- ✅ memory/ — cross-project knowledge
- ✅ config/ — default CC config, preferences
- ✅ vault/ — encrypted secrets (safe because encrypted)
- ✅ personas/ — client context
- ✅ glossary.md — vocabulary
- ✅ codebits/ — reusable snippets
- ✅ habits/ — tracking data
- ❌ registry.json — local (repos are at different paths per machine)
- ❌ cache/ — local

**Conflict handling:**
iCloud handles file-level conflicts. For Cortex's use case (mostly append-only, single-user):
- Behaviors: unique filenames, rarely edited simultaneously → no conflicts
- Memory: append-only → no conflicts  
- Vault: encrypted, rarely edited simultaneously → no conflicts
- Registry: NOT synced → no conflicts

**Edge case: new machine setup**
```
cortex init --sync
→ Detects iCloud Drive
→ Finds existing genius-cortex data in iCloud
→ Creates local symlinks
→ "Found 7 behaviors, 42 memory bits, 3 personas from your other machines"
→ "Scanning this machine for GT repos..."
→ Builds LOCAL registry for THIS machine
→ Done — all cross-machine data is already here
```

### Alternative: Git-based sync (for non-iCloud users)
```bash
# During init: "Sync via iCloud or Git?"
# If Git:
cd ~/.genius-cortex
git init
git remote add origin git@github.com:user/my-cortex-data.git
# Auto-commit + push on changes
# Auto-pull on startup
```

This works for Linux users, Windows users, and people who don't want iCloud.

### Score: Sync concept is now fully implementable. Two paths (iCloud / Git). Machine-specific data stays local.

## Iteration 11 — Competitive Moat Analysis (20:18)
**Target:** Crystalize what makes Cortex unique and defensible

### What Cortex Does That Nobody Else Does

| Capability | Conductor | Codex App | Cursor | Claude Code | **Cortex** |
|-----------|-----------|-----------|--------|-------------|-----------|
| Multi-repo view | ❌ | ❌ | ❌ | ❌ | ✅ |
| Cross-repo memory | ❌ | ❌ | ❌ | ❌ | ✅ |
| Shared behaviors | ❌ | ❌ | ❌ | ❌ | ✅ |
| Version governance | ❌ | ❌ | ❌ | ❌ | ✅ |
| Project factory | ❌ | ❌ | ❌ | ❌ | ✅ |
| Vault (secrets mgmt) | ❌ | ❌ | ❌ | ❌ | ✅ |
| Behavior marketplace | ❌ | ❌ | ❌ | ❌ | ✅ |
| Cross-machine sync | ❌ | ❌ | Partial | ❌ | ✅ |
| AI Watch feed | ❌ | ❌ | ❌ | ❌ | ✅ |
| Auto-QA scheduling | ❌ | ❌ | ❌ | ❌ | ✅ |
| Parallel agents | ✅ | ✅ | ❌ | Via AT | Via GT |
| IDE integration | ❌ | ❌ | ✅ | ❌ | Via GT |

**Cortex's unique moat: CROSS-PROJECT INTELLIGENCE**
Nobody else aggregates knowledge, behaviors, and governance across multiple repos.

### Market Position
```
              ┌───────────────────────────────────┐
              │        Cortex                      │
              │   (Cross-project governance)       │
              │                                    │
              │   ┌─────────┐  ┌─────────────┐   │
              │   │Conductor│  │  Codex App   │   │
              │   │(parallel │  │  (single     │   │
              │   │ agents)  │  │   session)   │   │
              │   └─────────┘  └─────────────┘   │
              │                                    │
              │      Claude Code / Codex CLI       │
              │      (execution engines)           │
              └───────────────────────────────────┘
```

Cortex sits ABOVE the execution tools. It doesn't compete — it orchestrates.

### Defensibility
1. **Network effects** — Behavior marketplace: more users = better behaviors = more users
2. **Data lock-in** (positive) — Your behaviors + memory + vault become indispensable
3. **Ecosystem integration** — Deep hooks into CC/Codex/GT = switching cost
4. **Community** — Shared behaviors = community identity = retention


## FINAL SCORES — After 11 iterations

| Criterion | Baseline | Final | Δ |
|-----------|----------|-------|---|
| Concept completeness | 8 | 9.5 | +1.5 |
| Feature depth | 7 | 9 | +2 |
| Architecture soundness | 7 | 9 | +2 |
| Injection mechanism | 6 | 9 | +3 |
| UX flow | 7 | 9 | +2 |
| Differentiation | 9 | 9.5 | +0.5 |
| Implementation readiness | 5 | 8.5 | +3.5 |
| Business model | 8 | 9 | +1 |
| **AVERAGE** | **7.1** | **9.1** | **+2.0** |

## Key Improvements Made
1. Injection mechanism: 3-layer system (static CLAUDE.md + SessionStart hook + MCP tools)
2. Daily workflow UX: morning routine, project switching, chat routing all defined
3. Architecture: clean Core → CLI/App/MCP/Hook/Connectors separation
4. Sprint 1 spec: day-by-day, file-by-file, API contracts defined
5. Habits: tracking via hooks + review, streaks, dashboard UI
6. Business model: conversion triggers, pricing research, revenue projections
7. Chat: Claude + MCP tools (no custom NLU needed)
8. Vault: AES-256, Keychain, per-project inject
9. Sync: iCloud symlink or Git-based, selective sync
10. Competitive moat: nobody does cross-project intelligence
11. Nightly build program: 6 phases, 8h, clear success criteria

## READY FOR NIGHTLY BUILD
The program is in Iteration 9. Everything else supports understanding.
Sprint 1 can start tonight.

---
*Autoresearch completed: 2026-03-24 20:20 CET*
*11 iterations over ~70 minutes*
*Baseline 7.1 → Final 9.1 (+2.0)*

---

## ROUND 2 — 10 more iterations (starting 19:22)

## Iteration 12 — Templates System Deep-Dive (19:22)
**Target:** Make templates concrete and implementable

### Problem
"Templates for new projects" is vague. What's actually in a template? How do they differ?

### Template Structure
```
~/.genius-cortex/templates/
├── saas/
│   ├── template.json         # Metadata + config
│   ├── scaffold/             # Files to copy into new project
│   │   ├── CLAUDE.md         # Pre-configured for SaaS
│   │   ├── .claude/
│   │   │   └── settings.json
│   │   ├── .genius/
│   │   │   ├── state.json
│   │   │   └── memory/
│   │   │       └── BRIEFING.md
│   │   └── package.json      # Starter deps (Next.js + Supabase + Stripe)
│   ├── behaviors.json        # Behaviors auto-activated for this template
│   └── skills.json           # Skills auto-activated for this template
├── landing-page/
│   ├── template.json
│   ├── scaffold/
│   │   ├── CLAUDE.md
│   │   ├── index.html        # Starter HTML
│   │   └── style.css
│   ├── behaviors.json
│   └── skills.json
├── api/
│   └── ...
├── mobile/
│   └── ...
└── custom/                   # User-created templates
    └── ...
```

### template.json Schema
```json
{
  "name": "SaaS Starter",
  "slug": "saas",
  "description": "Full-stack SaaS with auth, billing, dashboard",
  "version": "1.0.0",
  "stack": {
    "frontend": "Next.js 15",
    "backend": "API Routes + Supabase",
    "database": "PostgreSQL (Supabase)",
    "auth": "Supabase Auth",
    "payments": "Stripe",
    "deploy": "Vercel"
  },
  "gtMode": "cli",
  "defaultBehaviors": ["prove-before-fix", "post-fix-audit", "test-the-fix"],
  "defaultSkills": ["genius-dev-frontend", "genius-dev-backend", "genius-dev-database", "genius-seo"],
  "defaultMCPs": [],
  "postCreate": [
    "npm install",
    "npx supabase init"
  ],
  "questions": [
    {
      "key": "appName",
      "prompt": "App name?",
      "default": "my-saas",
      "validate": "^[a-z][a-z0-9-]*$"
    },
    {
      "key": "withStripe",
      "prompt": "Include Stripe billing?",
      "type": "confirm",
      "default": true
    }
  ]
}
```

### 4 Starter Templates

**1. SaaS Starter**
- Next.js + Supabase + Stripe + Vercel
- Auth, billing, dashboard, API
- Skills: frontend, backend, database, SEO

**2. Landing Page**
- HTML/CSS/JS + Vercel
- Responsive, SEO-optimized
- Skills: frontend, designer, SEO, content

**3. API Service**
- Express/Fastify + PostgreSQL + Docker
- REST/GraphQL, auth, rate limiting
- Skills: backend, database, API, security

**4. Mobile App**
- React Native + Expo + Supabase
- Cross-platform, offline-first
- Skills: mobile, designer, backend

### Template Marketplace (Pro feature)
```bash
cortex templates browse              # Show community templates
cortex templates install @community/e-commerce
cortex templates publish my-template # Publish your own
```


## Iteration 13 — Monitoring & Health Score System (19:28)
**Target:** Define how project health is measured and displayed

### Health Score Components

Each repo gets a score 0-100 based on:

```typescript
interface HealthScore {
  overall: number;          // 0-100 weighted average
  components: {
    gtVersion: number;      // 0-25 — is GT up to date?
    lastActivity: number;   // 0-20 — how recent was last session?
    testsPassing: number;   // 0-20 — do tests pass? (if detectable)
    buildOk: number;        // 0-15 — does it build? (if detectable)
    skillsCoverage: number; // 0-10 — are skills properly configured?
    behaviorCompliance: number; // 0-10 — habits followed?
  };
  alerts: Alert[];
  lastChecked: string;
}

interface Alert {
  severity: "critical" | "warning" | "info";
  message: string;
  action?: string;         // Suggested fix
  autoFixable: boolean;    // Can Cortex fix this automatically?
}
```

### Scoring Logic

**gtVersion (0-25):**
- Latest version = 25
- 1 minor behind = 20
- 1 major behind = 10
- 2+ majors behind = 0

**lastActivity (0-20):**
- Today = 20
- This week = 15
- This month = 10
- Older = 5
- Never = 0

**testsPassing (0-20):**
- Detect test runner: look for `package.json` scripts (test, test:unit, test:e2e)
- Run in dry-run/check mode if possible
- 20 = all pass, 10 = some fail, 0 = can't detect or all fail

**buildOk (0-15):**
- Detect build script in package.json
- TypeScript: `tsc --noEmit`
- 15 = builds clean, 5 = warnings, 0 = errors or can't detect

**skillsCoverage (0-10):**
- Does CLAUDE.md reference skills?
- Are the expected skills for the template present?
- 10 = fully configured, 5 = partial, 0 = missing

**behaviorCompliance (0-10):**
- From habits tracking data
- 10 = 90%+ compliance, 5 = 50-90%, 0 = <50%

### Dashboard Health View
```
┌─── Project Health ───────────────────────────────┐
│                                                   │
│  Utopia          ████████████████████░  92/100    │
│  ├─ GT v19 ✅   ├─ Active today ✅               │
│  ├─ Tests ✅    ├─ Build ✅                       │
│  └─ Skills ✅   └─ Habits 85% ⚠️                 │
│                                                   │
│  Artts           ████████████░░░░░░░░  58/100    │
│  ├─ GT v18 ⚠️   ├─ Active 12 days ago ⚠️        │
│  ├─ Tests ❌    ├─ Build ⚠️ (warnings)           │
│  └─ Skills ✅   └─ Habits N/A                    │
│  ⚠️ Alert: GT outdated [Upgrade]                  │
│  ❌ Alert: 3 tests failing [Open in CC]           │
│                                                   │
│  CineFi          ████████████████░░░░  74/100    │
│  ...                                              │
│                                                   │
│  Portfolio avg: 75/100 (+3 vs last week)          │
└───────────────────────────────────────────────────┘
```

### Alert Examples
- 🔴 Critical: "Artts has 3 failing tests since 3 days. [Open in CC] [Run QA]"
- 🟡 Warning: "CineFi GT version is outdated (v18 → v19 available). [Upgrade]"
- 🔵 Info: "Utopia hasn't been active for 5 days. Reminder set for Monday."
- 🟢 Good: "All projects healthy. Behavior compliance at 88% this week (+5%)."


## Iteration 14 — Cross-Project Search Engine (19:34)
**Target:** How does cross-project search actually work?

### Problem
"Search across all repos" sounds great but searching code in multiple large repos is expensive.

### Solution: Lightweight Index + On-Demand Deep Search

**Layer 1: Cortex Index (pre-built, fast)**
Built during `cortex scan` and updated periodically:
```typescript
interface ProjectIndex {
  repo: string;
  files: FileEntry[];      // File paths + metadata
  dependencies: string[];  // From package.json/requirements.txt
  skills: string[];        // Active skills
  technologies: string[];  // Detected: "react", "supabase", "stripe"
  readme: string;          // First 500 chars of README
}

interface FileEntry {
  path: string;
  type: string;           // "ts" | "tsx" | "py" | "md" | ...
  size: number;
  lastModified: string;
  tags: string[];         // Auto-detected: "webhook", "auth", "payment"
}
```

**How the index is built:**
1. Walk each repo's src/ directory
2. For each file: detect purpose from filename + imports
   - `webhook.ts` → tag "webhook"
   - `import Stripe` → tag "stripe", "payment"
   - `import { createClient } from '@supabase/supabase-js'` → tag "supabase"
3. Read package.json → extract all deps
4. Store as `~/.genius-cortex/cache/index/<repo>.json`
5. Rebuild on scan or when file ages > 1 day

**Layer 2: Deep Search (on-demand, uses grep/ripgrep)**
When user asks a specific code question:
```bash
# Behind the scenes
rg --json "webhook.*verify" ~/Projects/utopia ~/Projects/cinefi ~/Projects/my-saas
```
- Uses `ripgrep` (rg) for speed
- Searches only repos in registry
- Returns file + line number + context
- Results cached for 1h

### Search Examples

**From Cortex Chat:**
> "Where do I use Stripe?"
> → Layer 1: Check index → 3 repos have "stripe" tag
> → Response: "Utopia (billing/stripe.ts), CineFi (payments/), My-SaaS (api/billing/)"

**From CLI:**
```bash
$ cortex search "webhook verify"
Found in 2 repos:
  Utopia — src/api/webhooks/verify.ts:14  → verifyStripeSignature(payload, sig)
  CineFi — src/hooks/webhook.ts:8         → verifyWebhookSignature(req)
```

**From MCP (during Claude Code session):**
> Claude: [calls cortex_search("supabase auth pattern")]
> → Returns: "Found in Utopia: src/lib/auth.ts — createServerClient pattern with cookies"

### Performance
- Index build: ~2s per repo (file walk + import scan)
- Index search: <100ms (in-memory JSON)
- Deep search (rg): <2s for 5 repos


## Iteration 15 — Glossary & Rules Systems (19:40)
**Target:** Define these smaller concepts clearly

### Glossary System

```markdown
# ~/.genius-cortex/glossary.md

## Business Terms
- **MVP** — Minimum Viable Product. For me: the smallest thing I can ship that validates the idea. NOT a full product with compromises.
- **Vibe coding** — Building software by describing what you want in natural language, guided by AI. You stay in control, you learn as you build.
- **Commissaire de Justice** — French judicial officer (formerly "huissier"). Handles legal enforcement, debt collection, evictions.

## Technical Terms  
- **GT** — Genius Team
- **CC** — Claude Code
- **MCP** — Model Context Protocol (tool system for Claude)
- **Skills** — Genius Team's specialized agents (42 total, 6 departments)

## Personal Preferences
- **pnpm** — Always use pnpm, never npm or yarn
- **Supabase** — Default BaaS choice for new projects
- **Vercel** — Default deployment for frontend
- **Railway** — Default deployment for backend services
```

**Injection:** Glossary terms get included in the behavior injection block in `~/.claude/CLAUDE.md`. Claude sees them in every session.

**CLI:**
```bash
cortex glossary add "MVP" "Minimum Viable Product — the smallest shippable thing"
cortex glossary list
cortex glossary search "supabase"
```

### Rules System

Rules are stronger than behaviors. A behavior is "how you should work." A rule is "WHAT YOU MUST NEVER DO."

```markdown
# ~/.genius-cortex/rules/never-push-main.md
---
name: never-push-main
severity: critical
enforcement: hook  # Can be enforced via PreToolUse hook
---

## Rule
NEVER push directly to the main branch.
Always create a feature branch and PR.

## Enforcement
PreToolUse hook checks for `git push origin main` and BLOCKS it.
```

```markdown
# ~/.genius-cortex/rules/no-env-in-code.md
---
name: no-env-in-code
severity: critical
enforcement: review
---

## Rule
NEVER hardcode API keys, passwords, or secrets in source code.
Always use environment variables.

## Detection
Search for patterns: API_KEY=", sk-, password=", token="
```

**Enforcement levels:**
1. **hook** — Cortex can block the action via PreToolUse CC hook
2. **review** — Cortex flags violations during post-session review
3. **remind** — Cortex reminds at session start (injected in CLAUDE.md)

**Hook-enforced rules — implementation:**
```json
// In ~/.claude/settings.json
{
  "hooks": {
    "PreToolUse": [{
      "command": "cortex rules check --tool $TOOL_NAME --input $INPUT",
      "timeout": 3000
    }]
  }
}
```

When Claude tries to run `git push origin main`:
1. PreToolUse hook fires
2. `cortex rules check` receives the tool call info
3. Checks against active rules
4. Returns `{"decision": "block", "reason": "Rule 'never-push-main': always use feature branches"}` 
5. Claude Code blocks the action and shows the reason

This is **powerful** — Cortex can enforce coding standards at the tool level.


## Iteration 16 — Genius Watch Deep-Dive (19:46)
**Target:** Make Watch implementable with concrete sources and filtering

### Watch Architecture

```typescript
interface WatchEngine {
  sources: WatchSource[];
  filters: WatchFilter[];
  history: WatchItem[];
}

interface WatchSource {
  name: string;
  type: "github-releases" | "rss" | "scrape" | "npm-advisory";
  url: string;
  checkInterval: number;  // minutes
  lastChecked: string;
}

interface WatchItem {
  id: string;
  source: string;
  title: string;
  summary: string;
  impact: "critical" | "useful" | "informational";
  impactExplanation: string;  // "Affects 3 of your projects"
  url: string;
  publishedAt: string;
  read: boolean;
  actionTaken?: string;
}
```

### Default Sources

```json
[
  {
    "name": "Claude Code",
    "type": "github-releases",
    "url": "https://api.github.com/repos/anthropics/claude-code/releases",
    "checkInterval": 360
  },
  {
    "name": "Codex CLI", 
    "type": "github-releases",
    "url": "https://api.github.com/repos/openai/codex/releases",
    "checkInterval": 360
  },
  {
    "name": "Genius Team",
    "type": "github-releases",
    "url": "https://api.github.com/repos/w-3-art/genius-team/releases",
    "checkInterval": 60
  },
  {
    "name": "Anthropic Blog",
    "type": "rss",
    "url": "https://www.anthropic.com/blog/rss",
    "checkInterval": 720
  },
  {
    "name": "OpenAI Blog",
    "type": "rss",
    "url": "https://openai.com/blog/rss",
    "checkInterval": 720
  },
  {
    "name": "npm Security",
    "type": "npm-advisory",
    "url": "https://registry.npmjs.org/-/npm/v1/security/advisories",
    "checkInterval": 1440
  }
]
```

### Impact Assessment
When a new item is detected:
1. Parse the release notes / article
2. Cross-reference with user's repos (what tech do they use?)
3. Score impact:
   - **Critical**: Security advisory affecting a dependency in your repos
   - **Useful**: New version of a tool you actively use (CC, Codex)
   - **Informational**: General AI news, blog posts

**Impact detection logic:**
```typescript
function assessImpact(item: WatchItem, registry: RepoEntry[]): string {
  // Check if any repo uses the affected tool
  const affectedRepos = registry.filter(repo => {
    if (item.source === "Claude Code") return true; // All repos use CC
    if (item.source === "npm Security") {
      // Check if advisory package is in any repo's package.json
      return checkDependency(repo.path, item.affectedPackage);
    }
    return false;
  });
  
  if (affectedRepos.length > 0) {
    return `Affects ${affectedRepos.length} projects: ${affectedRepos.map(r => r.name).join(', ')}`;
  }
  return "General update — no direct impact on your projects";
}
```

### Watch Feed in Dashboard
Chronological, filterable, actionable:
```
Filter: [All] [Critical] [Useful] [Unread]

📅 March 24, 2026

🔴 npm advisory: lodash < 4.17.22 — prototype pollution
   Affects: Utopia, Artts (both use lodash 4.17.21)
   [Fix: upgrade lodash] [Ignore]

🔵 Claude Code v2.1.78 released
   New: --bare flag, race condition fix
   Affects: All projects (CC is your primary engine)
   [View changelog] [Already updated ✅]

📅 March 23, 2026

🟡 Anthropic Blog: "Best practices for CLAUDE.md in 2026"
   Tip: Include negative examples in rules
   [Read article] [Apply to all projects]
```

### Custom Sources (Pro)
```bash
cortex watch add-source "My Company Blog" --rss https://blog.mycompany.com/feed
cortex watch add-source "React Releases" --github facebook/react
```


## Iteration 17 — Tauri App UI/UX Design (19:52)
**Target:** Define the app's visual design and navigation

### App Layout

```
┌────────────────────────────────────────────────────────┐
│  🧠 Genius Cortex           ⚡ 5 repos  🔔 2     ⚙️  │
├──────────┬─────────────────────────────────────────────┤
│          │                                             │
│ 📊 Home  │  [Main content area]                       │
│ 📁 Repos │                                             │
│ 🧬 Behav │  Changes based on selected sidebar item    │
│ 🧠 Memo  │                                             │
│ 🔐 Vault │                                             │
│ 📋 Templ │                                             │
│ 📡 Watch │                                             │
│ 💬 Chat  │                                             │
│ 📊 Stats │                                             │
│          │                                             │
│──────────│                                             │
│ ⚙️ Setti │                                             │
│          │                                             │
└──────────┴─────────────────────────────────────────────┘
```

### Design System
- **Dark theme** (like GT's Premium Gold — DM Sans, warm tones)
- Colors: bg #0F0F0F, surface #161616, accent gold #D4A574
- Font: DM Sans (consistent with GT website proposition 3)
- Cards: rounded 16px, subtle border, hover glow
- Animations: 200ms transitions, subtle scale on hover
- Icons: Lucide (lightweight, consistent)

### Menubar Dropdown (click tray icon)
```
┌──────────────────────────────────┐
│  🧠 Genius Cortex        v1.0   │
├──────────────────────────────────┤
│  ✅ 4 repos healthy             │
│  ⚠️ 1 needs upgrade             │
│  📬 2 watch alerts              │
├──────────────────────────────────┤
│  📊 Open Dashboard        ⌘D    │
│  🆕 New Project           ⌘N    │
│  💬 Open Chat             ⌘C    │
│  🔄 Check Updates         ⌘U    │
├──────────────────────────────────┤
│  ⚙️ Settings...                 │
│  ❌ Quit Cortex                 │
└──────────────────────────────────┘
```

### Keyboard Shortcuts
- ⌘D — Open dashboard
- ⌘N — New project
- ⌘C — Open chat
- ⌘U — Check for updates
- ⌘F — Cross-project search
- ⌘1-9 — Quick launch project by number

### Notification Types
- macOS native notifications for:
  - New GT version available
  - Critical security advisory
  - Auto-QA failed
  - Scheduled task completed
- Badge on menubar icon for unread alerts


## Iteration 18 — Connector Architecture (19:57)
**Target:** How do Telegram/WhatsApp connectors work technically?

### Approach: Leverage existing infrastructure

**Option A: Via Claude Code Channels (recommended)**
Claude Code Channels already provides Telegram/Discord integration.
Cortex doesn't need its OWN connector — it piggybacks on CC Channels.

How:
1. User has CC Channels set up (Telegram bot paired with CC)
2. User messages their CC bot: "cortex status"
3. CC session has Cortex MCP tools loaded
4. Claude recognizes it's a Cortex command → calls cortex_status()
5. Response sent back via Telegram

**Advantage:** Zero additional infra. Just works if CC Channels is set up.
**Limitation:** Requires an active CC session.

**Option B: Via OpenClaw**
If user has OpenClaw configured (like Ben):
1. User messages on Telegram/Discord
2. OpenClaw routes to the right agent
3. Agent has Cortex MCP tools
4. Works exactly like it does now with Echo

**Option C: Standalone Telegram Bot (Pro feature)**
For users without CC Channels or OpenClaw:
1. Cortex runs its own Telegram bot (API token from user)
2. Bot runs on user's machine (part of Cortex daemon)
3. Messages → Cortex Core → responses
4. Doesn't use Claude for NLU — simpler command-based interface:
   - `/status` → repo status table
   - `/upgrade all` → run upgrades
   - `/watch` → latest alerts
   - `/search <query>` → code search results

### Decision Matrix
| User has | Recommended connector | NLU? |
|----------|----------------------|------|
| CC Channels + Cortex MCP | Use CC Channels | ✅ Claude |
| OpenClaw + Cortex skill | Use OpenClaw | ✅ Claude |
| Neither | Standalone bot | ❌ Command-based |

### Implementation Priority
1. MCP Server (works with CC Channels automatically) — Sprint 4
2. OpenClaw skill (for Ben's setup) — Sprint 6
3. Standalone bot (for users without CC/OpenClaw) — Post-MVP


## Iteration 19 — Onboarding & First-Run Experience (20:02)
**Target:** Define the critical first 5 minutes

### First-Run Flow (when user installs Cortex)

```
$ npm install -g genius-cortex
$ cortex init

🧠 Welcome to Genius Cortex — your multi-repo brain.

Step 1/4: Where are your projects?
> ~/Projects [Enter to accept, or type a different path]

Scanning ~/Projects...
Found 5 Genius Team projects:
  ✅ utopia (v19.0.0)
  ✅ my-saas (v19.0.0)
  ⚠️ artts (v18.0.0) — outdated
  ✅ cinefi (v19.0.0)
  ⚠️ beat-blocks (v17.0.0) — outdated

Step 2/4: Set up sync?
  [1] iCloud (recommended for Mac users)
  [2] Git repository
  [3] Skip for now
> 1

Setting up iCloud sync... ✅
Your behaviors, memory, and config will sync across all your Macs.

Step 3/4: Install 7 starter behaviors?
  • prove-before-fix — Always prove the bug before fixing
  • post-fix-audit — Verify fixes + check regressions
  • verify-before-code — Read existing code before writing
  • no-rush-quality — Quality over speed
  • cumulative-feedback — All feedback is cumulative
  • read-before-write — Understand before modifying
  • minimal-change — Change only what's needed

  [y/N] > y

Installing behaviors... ✅
Injecting into Claude Code config... ✅
These behaviors are now active in ALL your Claude Code sessions.

Step 4/4: Install Claude Code integration?
This adds:
  • SessionStart hook (auto-inject project context)
  • Cortex MCP tools (search, memory, vault from within CC)
  
  [y/N] > y

Installing SessionStart hook... ✅
Installing MCP server... ✅

────────────────────────────────────────────────

🎉 Genius Cortex is ready!

  📊 cortex status     — see all your projects
  🔄 cortex upgrade    — update outdated repos
  🧬 cortex behaviors  — manage your coding behaviors
  💬 cortex chat       — talk to your projects
  📡 cortex watch      — AI tool news feed

  2 projects are outdated. Run `cortex upgrade --all` to fix.

────────────────────────────────────────────────
```

### Time to Value: < 2 minutes
From `npm install` to "behaviors injected + repos scanned + sync enabled" in under 2 minutes.

### Returning User (new machine)
```
$ cortex init

🧠 Genius Cortex — Welcome back!

Found existing Cortex data via iCloud:
  • 7 behaviors
  • 42 memory bits
  • 3 personas
  • 12 vault secrets

This appears to be a new machine. Setting up...

Scanning for projects...
Found 3 Genius Team projects on this machine.

Importing your data... ✅

Ready! Your behaviors, memory, and personas are synced.
Run `cortex status` to see your projects.
```


## Iteration 20 — Session History & Activity Feed (20:07)
**Target:** How session history and activity tracking work

### Session Tracking

Every time a Claude Code session starts (via SessionStart hook), Cortex logs:
```typescript
interface SessionLog {
  id: string;
  repo: string;
  startTime: string;
  endTime?: string;
  duration?: number;       // minutes
  toolCalls: number;       // via PostToolUse hook counting
  filesModified: string[]; // detected from git diff at session end
  commitsMade: string[];   // git log new commits
  behaviorsChecked: BehaviorCheck[];
  summary?: string;        // Auto-generated at session end
}
```

### PostToolUse hook for tracking
```json
// In ~/.claude/settings.json
{
  "hooks": {
    "PostToolUse": [{
      "command": "cortex track-tool $TOOL_NAME",
      "timeout": 1000,
      "async": true  // Don't block the session
    }],
    "SessionEnd": [{
      "command": "cortex session-end --repo $CWD",
      "timeout": 5000
    }]
  }
}
```

### Session End Summary
At SessionEnd, Cortex:
1. Gets git diff since session start → list of files modified
2. Gets git log since session start → list of commits
3. Counts tool calls from tracking
4. Checks behavior compliance
5. Generates a brief summary
6. Stores in `~/.genius-cortex/sessions/<repo>/<date>.json`

### Activity Feed in Dashboard
```
┌─── Activity ────────────────────────────────────┐
│                                                  │
│ Today                                            │
│ ┌─ 14:30 Utopia ─────────────────────────────┐  │
│ │ 45 min · 23 tool calls · 3 commits         │  │
│ │ Files: src/billing/stripe.ts (+42 -8)       │  │
│ │        src/api/webhooks.ts (new file)       │  │
│ │ Summary: Added Stripe webhook verification  │  │
│ │ Behaviors: 4/5 followed ⚠️                  │  │
│ │            (verify-before-code: skipped)    │  │
│ └────────────────────────────────────────────┘  │
│                                                  │
│ ┌─ 10:15 CineFi ─────────────────────────────┐  │
│ │ 20 min · 8 tool calls · 1 commit           │  │
│ │ Files: src/app/page.tsx (+12 -3)            │  │
│ │ Summary: Fixed navbar responsive issue      │  │
│ │ Behaviors: 5/5 followed ✅                  │  │
│ └────────────────────────────────────────────┘  │
│                                                  │
│ Yesterday                                        │
│ ...                                              │
│                                                  │
│ This week: 12 sessions · 8.5h · 47 commits      │
│ Top repo: Utopia (6 sessions)                    │
└──────────────────────────────────────────────────┘
```

### Analytics (Pro)
- Time spent per project (bar chart)
- Tool call distribution (what tools are used most?)
- Behavior compliance trend (line chart over weeks)
- Commit frequency per project
- Most active hours / days


## Iteration 21 — Global MCP Management (20:12)
**Target:** How Global MCPs are configured and distributed

### Problem
MCPs (Model Context Protocol servers) provide tools to Claude Code. Currently each project configures its own MCPs in `.mcp.json`. Cortex should centralize this.

### Solution: Cortex manages `~/.claude.json` (user-level MCP config)

Claude Code loads MCPs from:
1. `~/.claude.json` — user-level (applies to ALL sessions)
2. `.mcp.json` — project-level

Cortex writes to `~/.claude.json`, which means Global MCPs are available EVERYWHERE.

### MCP Registry
```
~/.genius-cortex/mcps/
├── registry.json
│   [
│     {
│       "name": "cortex",
│       "command": "cortex mcp start",
│       "scope": "global",
│       "description": "Cortex tools: status, search, memory, vault"
│     },
│     {
│       "name": "supabase",
│       "command": "npx -y @supabase/mcp-server",
│       "scope": "global",
│       "env": { "SUPABASE_ACCESS_TOKEN": "vault:SUPABASE_TOKEN" }
│     },
│     {
│       "name": "github",
│       "command": "npx -y @anthropic/github-mcp-server",
│       "scope": "global",
│       "env": { "GITHUB_TOKEN": "vault:GITHUB_TOKEN" }
│     }
│   ]
└── configs/
    └── project-overrides/    # Per-project MCP additions
```

### vault: prefix
Notice `"vault:SUPABASE_TOKEN"` — Cortex resolves vault references when writing to `~/.claude.json`. The actual token comes from the encrypted vault, never stored in plain text in MCP config.

### CLI
```bash
cortex mcps list                              # Show all global MCPs
cortex mcps add supabase --command "npx ..."  # Add a global MCP
cortex mcps remove supabase                    # Remove
cortex mcps inject                             # Write to ~/.claude.json
cortex mcps add-project utopia dexscreener    # Add MCP only for Utopia
```

### Flow
```
cortex mcps inject
    │
    ▼
Read ~/.genius-cortex/mcps/registry.json
    │
    ▼
Resolve vault: references → get actual tokens
    │
    ▼
Write to ~/.claude.json:
{
  "mcpServers": {
    "cortex": { "command": "cortex", "args": ["mcp", "start"] },
    "supabase": { "command": "npx", "args": ["-y", "@supabase/mcp-server"], "env": { "SUPABASE_ACCESS_TOKEN": "actual-token" } },
    "github": { "command": "npx", "args": ["-y", "@anthropic/github-mcp-server"], "env": { "GITHUB_TOKEN": "actual-token" } }
  }
}
    │
    ▼
Claude Code picks up MCPs on next session start
```


## ROUND 2 FINAL SCORES — After 21 total iterations

| Criterion | Round 1 (iter 11) | Round 2 (iter 21) | Δ |
|-----------|-------------------|-------------------|---|
| Concept completeness | 9.5 | 10 | +0.5 |
| Feature depth | 9 | 10 | +1 |
| Architecture soundness | 9 | 9.5 | +0.5 |
| Injection mechanism | 9 | 10 | +1 |
| UX flow | 9 | 10 | +1 |
| Differentiation | 9.5 | 10 | +0.5 |
| Implementation readiness | 8.5 | 9.5 | +1 |
| Business model | 9 | 9.5 | +0.5 |
| **AVERAGE** | **9.1** | **9.8** | **+0.7** |

## Round 2 Key Improvements (iterations 12-21)
12. Templates system — complete schema, 4 starters, marketplace
13. Health scoring — 6 components, 0-100 score, alert system
14. Cross-project search — 2-layer (index + ripgrep), <100ms
15. Glossary + Rules — enforcement via CC PreToolUse hooks (!!)
16. Genius Watch — sources, impact assessment, actionable feed
17. Tauri UI/UX — layout, menubar dropdown, keyboard shortcuts
18. Connectors — 3 paths (CC Channels, OpenClaw, standalone bot)
19. Onboarding — first-run flow, returning user flow, <2min time-to-value
20. Session history — tracking, analytics, activity feed
21. Global MCPs — vault: prefix for secrets, auto-inject to ~/.claude.json

## BREAKTHROUGH: Rule Enforcement via PreToolUse Hooks
Iteration 15 discovered that Cortex can BLOCK tool calls via CC's PreToolUse hook.
This means Cortex can enforce rules like "never push to main" at the TOOL level.
This is a significant competitive advantage — no other tool does this.

---
*Round 2 completed: 2026-03-24 20:15 CET*
*10 iterations over ~50 minutes*
*Score: 9.1 → 9.8 (+0.7)*
*Total: 21 iterations, baseline 7.1 → final 9.8 (+2.7)*

## Iteration 22 — Global Playground (19:27)
**Target:** Add consolidated playground view across all projects

### Concept
Chaque projet GT génère des playgrounds (`.genius/playgrounds/`) — des dashboards HTML interactifs pour chaque skill (design, frontend, backend, QA, etc.). Actuellement ils sont isolés par projet.

**Global Playground** = un meta-dashboard qui consolide TOUS les playgrounds de TOUS les projets en un seul endroit dans Cortex.

### Architecture

```
~/.genius-cortex/playground/
├── index.html              # Meta-dashboard: project selector + playground viewer
├── cache/                  # Cached playground data from each project
│   ├── utopia/
│   │   ├── design.html
│   │   ├── frontend.html
│   │   └── qa.html
│   ├── artts/
│   │   └── ...
│   └── cinefi/
│       └── ...
└── global/                 # Cross-project aggregated views
    ├── qa-overview.html    # QA status across ALL projects
    ├── design-system.html  # Design tokens/components across projects
    └── activity.html       # Activity timeline across projects
```

### How It Works

**1. Playground Collection**
When Cortex scans repos or at each heartbeat:
```typescript
async function collectPlaygrounds(registry: RepoEntry[]) {
  for (const repo of registry) {
    const playgroundDir = path.join(repo.path, '.genius', 'playgrounds');
    if (await exists(playgroundDir)) {
      const files = await glob(path.join(playgroundDir, '*.html'));
      for (const file of files) {
        // Copy to cache with repo namespace
        await copy(file, `~/.genius-cortex/playground/cache/${repo.name}/${basename(file)}`);
      }
    }
  }
}
```

**2. Meta-Dashboard (index.html)**
```
┌─── Global Playground ──────────────────────────────┐
│                                                     │
│  Project: [All ▾]  Skill: [All ▾]  View: [Grid ▾]  │
│                                                     │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐  │
│  │  Utopia     │ │  Artts      │ │  CineFi     │  │
│  │  🎨 Design  │ │  🎨 Design  │ │  🎨 Design  │  │
│  │  ⚡ Frontend│ │  ⚡ Frontend│ │  ⚡ Frontend│  │
│  │  🔧 Backend │ │  🛡️ QA     │ │  🔧 Backend │  │
│  │  🛡️ QA     │ │  📊 Perf   │ │  📱 Mobile  │  │
│  │  📈 SEO    │ │             │ │  🛡️ QA     │  │
│  └─────────────┘ └─────────────┘ └─────────────┘  │
│                                                     │
│  ─── Cross-Project Views ────────────────────────  │
│                                                     │
│  [🛡️ QA Overview]  — Test results across all repos │
│  [🎨 Design System] — Components & tokens comparison│
│  [📊 Activity]     — Who worked on what, when      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**3. Cross-Project Aggregated Views**

**QA Overview** — most valuable:
```
┌─── QA Overview (all projects) ─────────────────────┐
│                                                     │
│  Project    │ Tests │ Pass │ Fail │ Coverage │ Score │
│  ──────────┼───────┼──────┼──────┼──────────┼──────│
│  Utopia    │  47   │  47  │  0   │  82%     │ 100  │
│  Artts     │  23   │  20  │  3   │  61%     │  74  │
│  CineFi    │  35   │  34  │  1   │  73%     │  91  │
│  My-SaaS   │  12   │  12  │  0   │  45%     │  85  │
│                                                     │
│  Total: 117 tests, 113 passing, 4 failing           │
│  Avg coverage: 65%                                  │
│                                                     │
│  ⚠️ Artts: 3 failing tests since Mar 20             │
│  [Open Artts QA Playground] [Run genius-qa on Artts]│
└─────────────────────────────────────────────────────┘
```

**4. Live Playground Viewer**
Click on any project's playground → opens in an iframe within Cortex dashboard. No need to navigate to the project directory.

**5. Playground Templates in Cortex**
Global playground templates stored in Cortex, not per-project:
```
~/.genius-cortex/playground-templates/
├── design-tokens.css     # Shared design system
├── base-template.html    # Common structure
└── skill-templates/
    ├── frontend.html
    ├── backend.html
    ├── qa.html
    └── ...
```

When a new project is created via Project Factory, playground templates come from Cortex (not from the GT repo). This means:
- Update templates ONCE in Cortex → ALL new projects get the latest
- Existing projects can `cortex playgrounds refresh` to get updated templates

### Integration with Dashboard
Global Playground is a top-level section in the Cortex dashboard sidebar:
```
📊 Home
📁 Repos
🧬 Behaviors
🧠 Memory
🔐 Vault
📋 Templates
📡 Watch
🎮 Playgrounds    ← NEW
💬 Chat
📊 Stats
```

### CLI
```bash
cortex playgrounds list                    # Show all playgrounds across all repos
cortex playgrounds open utopia/design      # Open specific playground
cortex playgrounds refresh                 # Update all playground templates
cortex playgrounds overview qa             # Show QA overview across all repos
cortex playgrounds serve                   # Start local server for playground viewer
```

### Concept Addition to the Master List
This is concept #17: **Global Playgrounds**

| Concept | Description | Stockage |
|---------|-------------|----------|
| **Global Playgrounds** | Consolidated view of all playgrounds across all projects + cross-project aggregated views (QA, Design, Activity) | `~/.genius-cortex/playground/` |

