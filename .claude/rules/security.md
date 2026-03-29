---
description: Security rules for API handlers, auth, services, middleware
paths:
  - 'src/api/**/*'
  - 'src/services/**/*'
  - 'src/middleware/**/*'
  - 'src/auth/**/*'
  - '**/auth*'
  - '**/api*'
---

# Security Rules

These rules apply whenever you touch API handlers, auth, services, or middleware.

## Input Validation
- Validate ALL external input at the boundary (request params, body, query, headers)
- Use schema validation (Zod, Joi, or equivalent) — never trust raw input
- Reject unexpected fields; don't silently ignore them
- Sanitize strings before database insertion or HTML rendering

## Authorization Checks
- Every endpoint must check authorization — no endpoint is "public by default"
- Verify the user has permission for the specific resource, not just "is logged in"
- Check ownership: `resource.userId === currentUser.id` before mutations
- Use middleware for auth checks; don't duplicate auth logic in handlers

## Parameterized Queries
- NEVER concatenate user input into SQL strings
- Use parameterized queries or ORM methods exclusively
- If writing raw SQL, use `$1, $2` placeholders (Postgres) or `?` (MySQL/SQLite)
- Review any string interpolation near database calls as a potential injection vector

## Secrets Handling
- NEVER hardcode secrets, API keys, or tokens in source code
- Use environment variables via `process.env` or a secrets manager
- NEVER log secrets — check log statements don't include auth headers or tokens
- NEVER commit `.env` files — verify `.gitignore` includes them

## Dependency Auditing
- Before adding a new dependency, check its maintenance status and download count
- Prefer well-maintained packages with >1000 weekly downloads
- Run `npm audit` or equivalent after adding dependencies
- Pin major versions to avoid supply-chain attacks via auto-updates
