---
description: Performance patterns to prevent N+1, missing indexes, unbounded queries
paths:
  - 'src/**/*'
---

# Performance Rules

These rules apply to all source code to prevent common performance pitfalls.

## N+1 Detection
- When looping over records and making a query per record, refactor to a single batch query
- Use `WHERE id IN (...)` or equivalent batch loading instead of per-item lookups
- If using an ORM: use eager loading (`include`, `populate`, `with`) for related data
- Flag any `await` inside a `for`/`forEach`/`map` that calls the database

## Index Checks
- Every `WHERE` clause column should have an index — verify before shipping
- Composite indexes: put the most selective column first
- Foreign key columns need indexes for JOIN performance
- Check `EXPLAIN` output for sequential scans on large tables

## Unbounded Query Prevention
- NEVER query without a `LIMIT` — always paginate
- Default limit: 100 rows max per request unless explicitly justified
- `SELECT *` is banned in production code — select only needed columns
- Time-range queries must have both a start and end bound

## Async Patterns
- Use `Promise.all()` for independent async operations, not sequential `await`
- Don't `await` inside loops — collect promises and resolve together
- Use streaming for large datasets instead of loading everything into memory
- Set timeouts on external API calls — never wait indefinitely

## Caching Rules
- Cache expensive computations and repeated external API calls
- Set appropriate TTLs — don't cache forever without invalidation
- Use cache keys that include all relevant parameters
- Invalidate cache on writes that affect cached data
