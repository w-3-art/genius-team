# Telemetry & Privacy Policy — Genius Ecosystem

Canonical, ecosystem-wide policy for **Genius Team**, **Genius Cortex**, and
**Revius**. Every logging, tracing, telemetry, or debug surface across the three
repos MUST follow it. Each repo keeps a copy of this file at
`docs/TELEMETRY-PRIVACY.md` and references it from its `README`.

> Verified 2026-07-05 against the official Claude Code telemetry docs
> (<https://code.claude.com/docs/en/monitoring-usage>). Version/flag claims below
> are checked against that page — do not recopy them from third-party notes.

---

## 1. The invariant

**No secret ever reaches a log.** Concretely, none of the following may appear —
verbatim or truncated — in any log line, trace span, WebSocket frame, error
report, CI output, or persisted event:

- **Secrets / tokens / credentials** — API keys (`sk_live_…`, `sk_test_…`,
  `pk_live_…`), `Bearer` tokens, `api_key=` / `api_secret=` values, passwords,
  and credentials embedded in URLs (`https://user:token@host`).
- **Payloads** — full request/response bodies. Log only the minimal fields
  needed to debug (level, signature, timestamp, route).
- **Prompts / completions** — raw prompt or assistant-response text in any
  shared or team-visible log, dashboard, or crash report.

When a value in one of these classes could reach a log surface, it MUST be
**redacted at the write path** (before persist / transmit / broadcast), never as
a display-only filter applied after storage.

## 2. Redaction is applied before persistence, on every surface

Redaction runs on the write path so nothing unredacted ever reaches disk, a
WebSocket frame, or an exporter. It is applied consistently on **every** surface
that logs external text, not just the one route that happens to redact today.

Reference implementations in this ecosystem:

- **Revius** — `sanitizeSecrets` / `SECRET_PATTERNS` in
  `packages/server/src/console/index.ts` strips Stripe-style keys, `Bearer`
  tokens, `api_key`/`api_secret` values, and passwords from **both** the
  `message` and the client-supplied `signature` before a `ConsoleEvent` is
  stored or broadcast (`readConsoleEventFromBody` → `recordConsoleIssue`).
- **Genius Team** — the guard hook `scripts/genius-guard-boundary.sh` redacts
  every line it appends to `.genius/guard.log` (`redact_secrets` inside
  `log_guard`), so a boundary command carrying an embedded credential is masked
  in the audit trail.
- **Genius Cortex** — the vault never exposes secret values through any tool or
  API surface: only key *names* are listable (`listGlobalKeys`); the value
  getters are never wired into MCP tools or HTTP routes.

Each of these is guarded by a regression test that injects a fake secret through
the **real** log/telemetry path and fails if the secret appears in the output
(see §5).

## 3. Claude Code telemetry: prompts-only by default

Claude Code's OpenTelemetry export is **off by default** and prompt/response
content is **not collected** unless you explicitly opt in — only lengths are
recorded, and data is sent only to the OTel endpoint you configure, never to
Anthropic. When telemetry is enabled in a Genius workflow, keep it **prompts-only**:

| Env var | Ecosystem default | Meaning |
|---|---|---|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | unset (off) | Master switch; telemetry is disabled until set to `1`. |
| `OTEL_LOG_USER_PROMPTS` | unset (off) | Prompt content redacted by default (only length recorded). `1` includes full prompt text. |
| `OTEL_LOG_ASSISTANT_RESPONSES` | **`0`** | Assistant response text (truncated at 60 KB). **Falls back to `OTEL_LOG_USER_PROMPTS` when unset** — so for prompts-only telemetry you MUST set it explicitly to `0`, otherwise turning on prompts also turns on responses. (Requires Claude Code v2.1.193+.) |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | a collector **you own** | Never leave it at an example/default endpoint pointed at a third party. |

Rule of thumb: **`OTEL_LOG_ASSISTANT_RESPONSES=0`** for prompts-only telemetry,
and only raise `OTEL_LOG_USER_PROMPTS` with a documented, consented reason —
never in a shared or multi-tenant environment.

## 4. Security note — tracing active at a client site

If a client enables Claude Code tracing (or any OTel export) while using a Genius
tool:

- Prompts, tool calls, and — if `OTEL_LOG_ASSISTANT_RESPONSES` is not `0` —
  assistant responses will leave the machine to the configured OTLP endpoint.
  Confirm that endpoint is a collector the client owns and has reviewed.
- Treat any credential discovered in a log or trace as **compromised**: rotate
  first, then investigate blast radius.
- Put stored logs/traces behind the same auth as the rest of the API, give them
  a bounded retention window, and keep session data local-first unless the
  operator explicitly opts into remote sync.

## 5. Regression tests (per repo)

Each repo runs a test that exercises the **real** log path with an injected fake
secret and fails if it leaks. These are wired into each repo's CI:

- **Genius Team** — `scripts/test-guard-no-leak.sh`: feeds the guard hook a
  boundary command containing a fake credential, runs it, and asserts the raw
  secret is absent (masked) from `.genius/guard.log`. Wired into
  `.github/workflows/validate.yml`.
- **Revius** — `packages/server/src/console/no-leak.test.ts`: POSTs a console
  event whose `message` and `signature` carry a fake secret through the real
  ingest → store → WebSocket broadcast → list path, and asserts the secret never
  appears in the stored event, the broadcast frame, the list response, or the
  review reference. Run by `pnpm -r run test` in CI.
- **Genius Cortex** — `test/vault-no-leak.test.ts`: locks the contract that the
  vault surface returns only key names, never values. Run by `npm test`.

## 6. Checklist for any new logging surface

Before merging code that logs, traces, or exports anything:

- [ ] Secret/token/credential values redacted **before** write.
- [ ] No full request/response payloads — minimal fields only.
- [ ] No raw prompt/completion text in shared logs or error reports.
- [ ] `OTEL_LOG_ASSISTANT_RESPONSES=0` unless completions are explicitly needed.
- [ ] Redaction covered by a regression test on the real path.
- [ ] Read endpoints for logs/traces are authenticated; retention is bounded.
