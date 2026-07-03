---
name: genius-dev-backend
description: >-
  Specialized backend implementation skill. Builds APIs, auth systems, middleware,
  and server-side logic. Handles REST, GraphQL, Node.js, Express, Fastify, Hono.
  Use when task involves "API endpoint", "server", "authentication", "middleware",
  "REST API", "GraphQL", "Node.js", "backend", "server-side",
  "subscription billing", "Stripe subscription", "payment backend", "billing system".
  Do NOT use for UI components (genius-dev-frontend), database schema (genius-dev-database),
  or basic third-party API wrapping (genius-dev-api).
context: fork
agent: genius-dev-backend
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
  - Bash(git diff*)
  - Bash(git status*)
hooks:
  PostToolUse:
    - type: command
      command: "bash -c 'echo \"[$(date +%H:%M:%S)] BACKEND: $TOOL_NAME\" >> .genius/dev.log 2>/dev/null || true'"
  Stop:
    - type: command
      command: "bash -c 'echo \"BACKEND COMPLETE: $(date)\" >> .genius/dev.log 2>/dev/null || true'"
      once: true
---

# Genius Dev Backend v22 — API Architect

**Reliable, secure, fast APIs. Build the server layer the frontend deserves.**
Full code patterns (validation, auth, middleware, errors, retries):
`references/backend-patterns.md`.

## Core Principles

1. **Contract-first**: Define request/response types before writing handlers
2. **Fail fast, fail clear**: Validate input early, return descriptive errors
3. **Stateless by default**: Servers should be horizontally scalable
4. **Security at every layer**: Auth, rate limiting, input sanitization, CORS
5. **Observability**: Every route logs at minimum: method, path, status, duration

## Workflow

1. **Detect the stack** — grep `package.json` for express/fastify/hono/koa/nestjs/trpc,
   check `tsconfig.json`. Framework-specific conventions:
   `references/backend-patterns.md` § Stack Detection.
2. **Design the API contract** — RESTful resource naming (`GET/POST /api/users`,
   `PATCH /api/users/:id`), correct status codes (400 validation, 401 unauthenticated,
   403 unauthorized, 409 conflict, 429 rate-limited), consistent envelope:
   `{ "error": { code, message, field, statusCode } }` on failure,
   `{ "data": ..., "meta": ... }` on success. Full tables: § API Design.
3. **Validate every input** — Zod (preferred) `safeParse` at the handler edge,
   typed result. Pattern: § Input Validation.
4. **Auth** — JWT (stateless) or session (httpOnly, secure in prod) or OAuth
   (store provider ID + email only, never plaintext tokens). Patterns: § Authentication Patterns.
5. **Middleware order** — helmet → cors → body parser → rate limiter (stricter on
   `/api/auth`) → logger → routes → global error handler last. AppError +
   asyncHandler pattern, retry-transient-only rule (never retry validation/auth/
   duplicate writes without idempotency): § Middleware Stack.
6. **Smoke-test with curl** — exercise list, create, update, delete flows with
   authenticated requests against the changed endpoints.

## Output

Mark `.genius/outputs/state.json` complete for `genius-dev-backend` with a fresh timestamp.

## Handoff

- → **genius-dev-database**: schema design, migrations, query optimization
- → **genius-dev-api**: third-party integrations (Stripe, SendGrid, etc.)
- → **genius-qa-micro**: API endpoint tests
- → **genius-security**: security audit on auth/payments routes

## Playground Update

Refresh the existing dashboard tab with real backend progress data and point the user to `.genius/DASHBOARD.html`.

## Definition of Done

- [ ] App starts cleanly after the change
- [ ] New endpoints are exercised
- [ ] Error paths are covered
- [ ] Secrets are not hardcoded
- [ ] Inputs are validated before use
