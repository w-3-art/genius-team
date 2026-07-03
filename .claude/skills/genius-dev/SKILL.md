---
name: genius-dev
description: >-
  Smart coding dispatcher. Analyzes the task and routes to the right specialized
  sub-skill: genius-dev-frontend (UI/CSS/React), genius-dev-backend (API/auth/server),
  genius-dev-mobile (React Native/Expo), genius-dev-database (schema/migrations/queries),
  genius-dev-api (third-party integrations), genius-dev-web3 (smart contracts, Solidity,
  Vyper, Foundry, Hardhat, ethers/viem/wagmi, ERC-20/721/1155/4626). Handles full-stack
  or unclassified tasks directly.
  Use when user says "implement", "code", "build feature", "write code", "create component",
  "add feature", "build this", "make this work".
  Do NOT use for code review (use genius-reviewer or genius-code-review).
  Do NOT use for debugging existing bugs (use genius-debugger).
  Do NOT use for QA/testing (use genius-qa or genius-qa-micro).
  IMPORTANT: When the task clearly targets frontend, backend, mobile, database, API,
  or web3/smart-contracts, route DIRECTLY to the sub-skill instead of going through genius-dev.
  Do NOT use for QA, design, or architecture tasks.
context: fork
agent: genius-dev
user-invocable: false
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Glob(*)
  - Grep(*)
  - Bash(npm *)
  - Bash(npx *)
  - Bash(node *)
  - Bash(tsc *)
  - Bash(git diff*)
  - Bash(git status*)
hooks:
  PostToolUse:
    - type: command
      command: "bash -c 'echo \"[$(date +%H:%M:%S)] DEV: $TOOL_NAME\" >> .genius/dev.log 2>/dev/null || true'"
  Stop:
    - type: command
      command: "bash -c 'echo \"DEV COMPLETE: $(date)\" >> .genius/dev.log 2>/dev/null || true'"
      once: true
---

# Genius Dev v22.0 — The Craftsman

**Real artists ship. But they ship when it's insanely great.**
Field shapes, full standards, optional MCP patterns: `references/dev-details.md`.

## Smart Sub-Skill Dispatch

Before implementing anything, analyze the task and route to the specialized sub-skill:

| Task type | Sub-skill to use |
|-----------|-----------------|
| React, Vue, Svelte, CSS, Tailwind, UI, animations, responsive | **genius-dev-frontend** |
| Node.js, Express, Fastify, API routes, auth, REST, GraphQL | **genius-dev-backend** |
| React Native, Expo, iOS, Android, mobile APIs | **genius-dev-mobile** |
| SQL, NoSQL, schema, migrations, Prisma, Drizzle, indexing | **genius-dev-database** |
| Third-party API integration, SDK wrapper, webhook, OpenAPI | **genius-dev-api** |
| Solidity, Vyper, Cairo, Move, ERC-*, Foundry, Hardhat, Anchor, ethers/viem/wagmi | **genius-dev-web3** |
| Full-stack feature, multi-layer, or unclassified | **Handle directly** (see below) |

**Web3 signal cues** (route to `genius-dev-web3` immediately): file ext `.sol`,
`.vy`, `.cairo`, `.move`; configs `foundry.toml`, `hardhat.config.*`, `Anchor.toml`;
keywords "contract", "token", "NFT", "ERC-*", "vault", "staking", "airdrop",
"wallet connect", "onchain", "reentrancy", "gas optimization".

**How to dispatch:** state your routing decision ("This task involves [type].
I'm routing to genius-dev-[type]."). Agent Teams mode → spawn the sub-skill as a
sub-agent. Codex dual mode → thread forking. Standalone → apply the sub-skill's
guidelines from its SKILL.md.

## Workflow Protocol

1. **Understand** — parse requirements, check BRIEFING.md for existing patterns, identify files, plan the approach.
2. **Implement** — create files in dependency order, follow existing codebase patterns, handle errors gracefully.
3. **Verify** — `npm run typecheck || npx tsc --noEmit`, `npm run lint`, `npm run test`.
4. **Document** — update relevant docs plus the runtime state/session log expected by Genius Team v22.

## State & Memory

**DO NOT launch separate HTML files** — update `.genius/outputs/state.json`
(`phases.dev` status/progress/currentTask; on complete: status `complete`,
progress 100, `currentPhase: "qa"`). Read `@.genius/memory/BRIEFING.md` at start
(check previously rejected approaches); append decisions/errors/completions to
`.genius/memory/{decisions,errors,progress}.json`. Exact JSON field shapes:
`references/dev-details.md` § Unified Dashboard Integration and § Memory Integration.

## Quality Bar

TypeScript: no `any`, proper error handling, clear interfaces. React: functional
components, loading/error states, error boundaries. General: no hardcoded values
or secrets, no console.logs, meaningful names, single responsibility. Six Pillars
and the full pre-completion checklist: `references/dev-details.md` § Code Quality
Standards and § Quality Checklist.

## Optional MCP Patterns

MCP Elicitation (structured mid-task input, Claude Code ≥ 2.1.76) and Cloudflare
Code Mode (`GENIUS_MCP_CODE_MODE=true`) — when and how:
`references/dev-details.md` § MCP Elicitation Pattern and § Cloudflare Code Mode MCP.

## Handoffs

- **From genius-orchestrator** (maker in the build-test-fix pair): task via Task()
  with subagent_type, requirements, BRIEFING.md. On re-entry: genius-qa-micro's
  exact gate failures (command + exit + file:line) — fix only those.
- **To genius-qa-micro** (objective gate): implemented files; gate runs the project's real test/lint/typecheck.
- **To genius-debugger** (on error): error message, stack trace, what was attempted.

## Definition of Done

- [ ] Code compiles/builds without errors
- [ ] genius-qa-micro ran and passed
- [ ] Changes committed with descriptive message
- [ ] `.genius/state.json` and/or `.genius/session-log.jsonl` updated with completed task context
- [ ] No console.log or debug code left in production paths
