# genius-dev — Reference Details

Loaded on demand from `SKILL.md`. Full state/memory field shapes, quality
standards, and optional MCP patterns for the coding dispatcher.

---

## Unified Dashboard Integration (full detail)

**DO NOT launch separate HTML files.** Update the unified state instead.

### On Phase Start
Update `.genius/outputs/state.json`:
```json
{
  "currentPhase": "dev",
  "phases": {
    "dev": {
      "status": "in-progress",
      "data": {
        "currentTask": "...",
        "completedTasks": [],
        "progress": 0
      }
    }
  }
}
```

### During Development
Update `phases.dev.data` with progress:
- Add completed tasks to `completedTasks` array
- Update `progress` percentage
- Update `currentTask` description

### On Phase Complete
Update state.json with:
- `phases.dev.status` = `"complete"`
- `phases.dev.data.progress` = `100`
- `currentPhase` = `"qa"`

---

## Memory Integration (full field shapes)

### On Implementation Start
Read `@.genius/memory/BRIEFING.md` for project context, patterns, and past decisions.
Check for previously rejected approaches before proposing solutions.

### On Decision Made
Append to `.genius/memory/decisions.json`:
```json
{"id": "d-XXX", "decision": "DEV: [choice]", "reason": "[why]", "timestamp": "ISO-date", "tags": ["decision", "implementation"]}
```

### On Error Encountered
Append to `.genius/memory/errors.json`:
```json
{"id": "e-XXX", "error": "[approach] failed: [error]", "solution": "[what worked instead]", "timestamp": "ISO-date", "tags": ["rejected", "implementation"]}
```

### On Feature Complete
Append to `.genius/memory/progress.json`:
```json
{"id": "t-XXX", "task": "IMPLEMENTED: [feature]", "status": "completed", "timestamp": "ISO-date"}
```

---

## The Six Pillars of Excellence

1. **Think Different** — Question every assumption
2. **Obsess Over Details** — Every variable name matters
3. **Plan Like Da Vinci** — Understand the full picture before coding
4. **Craft, Don't Code** — Code should read like prose
5. **Iterate Relentlessly** — First version is never good enough
6. **Simplify Ruthlessly** — Elegance = nothing left to take away

---

## Code Quality Standards (full)

### TypeScript
- NO `any` types — use proper interfaces
- Proper error handling with try/catch
- Use optional chaining for safety
- Define clear interfaces

### React/Next.js
- Functional components only
- Proper loading and error states
- Use appropriate hooks
- Implement error boundaries

### General
- No hardcoded values — use constants/config
- No console.logs in production code
- Meaningful variable names
- Single responsibility principle

## Quality Checklist (full)

Before marking ANY task complete:

- [ ] TypeScript compiles without errors
- [ ] No `any` types used
- [ ] Error handling implemented
- [ ] Loading states present (if UI)
- [ ] No hardcoded secrets
- [ ] No console.logs
- [ ] Code is readable and well-named
- [ ] Tests written (if applicable)

---

## MCP Elicitation Pattern (Claude Code ≥ 2.1.76, March 2026)

MCP servers can now request **structured input mid-task** without blocking the agent workflow.

### What is it?
When an MCP tool needs user input (API key, confirmation, configuration), it can:
1. Display an **interactive form** (fields, dropdowns, checkboxes) via a dialog
2. Or **open a browser URL** to collect data externally
The agent receives the result and continues — no interruption, no back-and-forth prompts.

### Hooks available
- `Elicitation` — fires before the elicitation dialog is shown; can override/pre-fill values
- `ElicitationResult` — fires after the user submits; can validate or transform the response

### When to use it in genius-dev tasks
- Setting up a new integration that needs credentials → the MCP server shows a form, gets the key, stores it
- Collecting user preferences for a feature before generating code
- Confirming a destructive operation (delete, reset) without stopping the build flow

### Example pattern (server-side)
```typescript
// In your MCP server tool handler:
const { fields } = await server.elicit({
  message: "Configure your Stripe integration",
  requestedSchema: {
    type: "object",
    properties: {
      apiKey: { type: "string", description: "Stripe secret key (sk_...)" },
      webhookSecret: { type: "string", description: "Webhook endpoint secret" },
    },
    required: ["apiKey"]
  }
});
// `fields` now contains validated user input
```

### Compatibility
- Requires Claude Code ≥ 2.1.76 (released March 14, 2026)
- Works with any MCP server using the `@modelcontextprotocol/sdk` package
- Hooks are configured in `.claude/settings.json` under `hooks.Elicitation`

---

## Cloudflare Code Mode MCP (Optional)

If `GENIUS_MCP_CODE_MODE=true` is set and a Cloudflare Code Mode MCP server is configured, you can use this pattern for API integrations:

### Instead of searching through hundreds of MCP tool definitions:

1. `get_docs("stripe create payment intent")` → get only what you need
2. `run_code("...")` → test in a sandboxed Workers environment
3. Write the final implementation based on the tested code

### Why this matters:
- Fixed ~1K token cost (vs 500K+ for full API schemas)
- Safe execution in isolated sandbox
- Progressive discovery — only load docs you actually need

**Enable:** Add `cloudflare-code-mode` to your `mcpServers` in `.claude/settings.json`
**Guide:** See `docs/cloudflare-mcp-guide.md` for setup instructions
