---
description: Testing standards for test files
paths:
  - '**/*.test.*'
  - '**/*.spec.*'
  - '**/tests/**'
  - '**/__tests__/**'
---

# Testing Rules

## Test Naming as Specs
- Test names should read as specifications: `it("returns 401 when token is expired")`
- Use `describe` blocks to group related behavior
- A failing test name should tell you exactly what broke without reading the code

## Arrange-Act-Assert
- Structure every test as: setup (arrange), execute (act), verify (assert)
- One logical assertion per test
- Assert on behavior/output, not internal state

## Edge Cases
- Test the happy path AND at least one error/edge case per function
- Always test: empty input, null/undefined, boundary values, error responses

## Mock at Boundary Only
- Mock external services (APIs, databases, file system) — never mock internal functions
- Verify mock call counts and arguments
