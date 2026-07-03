# genius-omni-router — Routing Details (progressive disclosure)

Loaded on demand from `SKILL.md`. Contains the full per-category routing rationale,
health-check script, route command examples, output capture pattern, and cost
tracking guidance. `SKILL.md` keeps the routing table and decision flow.

---

## Routing Rationale (per category)

### 🏗️ Architecture & Planning → **Claude Code** (always)
- System design, component architecture, API design
- Technical decision-making, trade-off analysis
- Project planning, task decomposition
- **Why:** Requires deep reasoning and holistic understanding
- **No fallback needed** — Claude Code is the primary

### 💻 Code Implementation → **Codex CLI** (fallback: Claude Code)
- Writing new functions, classes, modules
- Refactoring existing code
- Generating boilerplate, CRUD operations
- **Why:** Fast, cost-effective for straightforward coding tasks
- **Route command:** `codex "implement function X that does Y"`
- **When to keep on Claude Code:** Complex logic, security-sensitive code, code requiring deep architectural context

### 🔍 Code Review → **Claude Code** (always)
- PR reviews, security audits, quality checks
- Bug hunting, performance analysis
- **Why:** Requires deep reasoning about correctness and edge cases
- **No fallback needed**

### 📝 Documentation → **Kimi CLI** (fallback: Claude Code)
- README generation, API docs, user guides
- Code documentation, JSDoc/docstrings
- Summarizing large codebases
- **Why:** Excellent at long-context understanding and clear writing
- **Route command:** `kimi "write documentation for module X based on the source files in src/"`
- **When to keep on Claude Code:** Documentation requiring architectural decisions

### 🔬 Research & Analysis → **Gemini CLI** (fallback: Claude Code)
- Technology comparisons, library evaluation
- Analyzing large datasets or codebases
- Multi-modal analysis (images, diagrams)
- **Why:** Strong research capabilities and multi-modal understanding
- **Route command:** `gemini "research the best approach for implementing X, compare options A vs B vs C"`
- **When to keep on Claude Code:** Research requiring immediate action or code changes

### ✅ QA & Testing → **Claude Code** (always)
- Test strategy, test writing, test review
- Bug reproduction, debugging
- CI/CD pipeline design
- **Why:** Testing requires understanding intent, edge cases, and system behavior
- **No fallback needed**

---

## Provider Health Check (script)

Before routing to any secondary provider, verify availability:

```bash
# Check all providers at once
for cmd in codex kimi gemini; do
  if command -v "$cmd" &>/dev/null; then
    echo "✓ $cmd: $($cmd --version 2>/dev/null | head -1)"
  else
    echo "✗ $cmd: not installed → fallback to Claude Code"
  fi
done

# Check auth status (each CLI has its own login mechanism)
# codex: uses OAuth via `codex login`
# kimi: uses `kimi auth login`
# gemini: uses Google OAuth via `gemini login`
```

**Rule:** A provider is "available" only if the CLI binary is installed AND the user is authenticated (logged in). Otherwise → Claude Code.

---

## How to Route (command examples)

When Claude Code decides to route a task to a secondary provider, use Bash:

```bash
# Codex example — code implementation
codex "Create a REST API endpoint for user authentication with JWT tokens. \
Use Express.js, include input validation and error handling."

# Kimi example — documentation
kimi "Generate comprehensive API documentation for the files in src/api/. \
Include endpoint descriptions, parameters, response formats, and examples."

# Gemini example — research
gemini "Compare Redis vs Memcached vs DragonflyDB for our session store. \
Consider: performance, memory efficiency, clustering, ecosystem. Recommend one."
```

### Capturing Output

Route via Bash and capture the output for integration:

```bash
# Route and capture
RESULT=$(codex "implement the getUserById function" 2>&1)
echo "$RESULT"
# Then Claude Code reviews and integrates the result
```

---

## Cost Tracking

Log provider usage for cost awareness:

```bash
# Append to routing log after each provider call
echo "[$(date +%H:%M:%S)] ROUTED: task_type=$TASK_TYPE provider=$PROVIDER" >> .genius/omni-router.log
```

### When Cost Optimization Matters
- For large projects with many implementation tasks → route boilerplate to Codex
- For projects with extensive documentation needs → route to Kimi
- For exploration/research-heavy phases → route to Gemini
- For small/quick tasks → keep on Claude Code (overhead of routing > savings)
