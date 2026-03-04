# Changelog

## [15.0.0] - 2026-03-04

### Added
- 🔗 **HTTP Hooks support** — `GENIUS_WEBHOOK_URL` env var enables POST JSON notifications on skill completion and session stop (PostToolUse + Stop events in all 4 mode configs)
- 🔀 **Codex thread forking in genius-orchestrator** — v2.1 orchestrator documents native Codex 0.107.0 thread forking pattern for parallel agent execution (dual engine mode)
- 📄 **PDF specs support in genius-qa** — genius-qa accepts PDF specification documents as input (OpenClaw native + text extraction fallback)
- 🌐 **Git worktrees + shared configs** — dual engine mode now documents config sharing between Claude Code and Codex worktrees
- 📊 **Codex 0.107.0 stable** — updated tooling references; thread forking, realtime voice, custom multimodal tools

### Changed  
- `genius-orchestrator.yaml` — v2.1: added `thread_forking` section documenting Codex native sub-agent pattern
- `genius-qa.yaml` — added PDF input as optional source alongside specs.md
- All 4 mode `settings.json` — added optional `http` hook type for webhook notifications

---

## [14.0.0] - 2026-02-27

### Added
- 📊 **Proactive Dashboard UX** — Dashboard link shown after every skill, in `/genius-start`, `/status`, and at every checkpoint
- 🧠 **Native Auto Memory integration** — `@.genius/memory/BRIEFING.md` import in CLAUDE.md auto-loads project context without SessionStart hook
- 📁 **`.claude/rules/genius-memory.md`** — New modular rule file explaining the full memory hierarchy (Auto Memory vs `.genius/memory/`)
- 📝 **`CLAUDE.local.md` template** — Personal project preferences, auto-gitignored (sandbox URLs, local ports, personal API keys)
- 🌀 **Genius-Claw — Auto Memory aware** — §4 resume checks Auto Memory; §5 post-session always announces dashboard update; §5b full native memory table
- 🔧 **`/genius-start` Step 4b** — Bootstraps Claude Code Auto Memory with project facts on first run
- 🗂️ **`.claude/rules/` support** — Foundation for path-scoped modular rules (topic-specific, path-aware via YAML frontmatter)

### Changed
- All CLAUDE.md files (root + 4 modes): added `🧠 Memory` section with @import and Auto Memory guidance
- `genius-team` SKILL.md: PROACTIVE RULE — always mention Dashboard after skill completion
- `genius-orchestrator` SKILL.md: Dashboard link in Completion Protocol
- `/genius-dashboard` command: PROACTIVE RULE header (auto-suggest after every skill)

---

## [13.0.0] - 2026-02-26

### Added
- 🗂️ **Master Playground Dashboard** — `/genius-dashboard` command, `.genius/DASHBOARD.html` hub aggregating all playgrounds
- 📱 **Mobile-responsive playgrounds** — All 12 playgrounds work on phone and tablet
- 🌀 **Genius-Claw plugin** — OpenClaw native install: `openclaw plugins install https://genius.w3art.io/genius-claw.zip`
  - Cross-project memory (`memory/genius-claw.md`)
  - Project registry (`memory/genius-claw-projects.json`)
  - Global dashboard with Canvas presentation
  - Daily brief + stale alert + auto-update crons
- 🧙 **OpenClaw-first wizard** on genius.w3art.io
- 🔁 **Post-output dashboard hooks** — HTML-generating skills auto-open dashboard

### Changed
- CLAUDE.md wizard refactored to OpenClaw-first flow
- Banner and hero text updated to v13

---

## [12.0.0] - 2026-02-20

### Added
- 🤖 **8 full agent specifications** with YAML manifests
  - `genius-interviewer`, `genius-specs`, `genius-architect`, `genius-qa`
  - `genius-deploy`, `genius-dev`, `genius-security` + full orchestration registry
- 🎤 **Interview-First Flow** — Every project starts with `genius-interviewer` before any work begins
- ⛔ **Phase Checkpoints** — Human approval gates between major phase transitions
- 🔁 **Retrospective Engine** — Phase retrospectives feed learnings back into memory
- 🧠 **Cross-Project Memory** — Decisions and lessons persist across projects, not just sessions
- 🤝 **Agent coordination protocol** — shared artifacts, git worktree isolation, handoff contracts

---

## [11.0.0] - 2026-02-17

### Added
- 🔀 **Multi-engine support** via `--engine` flag
  - `--engine=claude` — Claude Code only (default, existing behavior)
  - `--engine=codex` — Codex CLI only (creates `.agents/` folder, uses `AGENTS.md`)
  - `--engine=dual` — Both engines (shared skills, both instruction files)
- 📁 `.agents/` directory structure for Codex CLI
  - Symlinks to `.claude/skills/` in dual mode for shared skills
- 📄 `AGENTS.md` auto-generated for Codex compatibility
  - Adapted from `CLAUDE.md` with path/tool substitutions
- 🔄 Dual engine coordination
  - `.genius/dual-engine-state.json` for tracking engine usage
  - Shared artifacts between Claude and Codex sessions
- 📜 Updated `create.sh` one-liner to accept `--engine` flag:
  ```bash
  bash <(curl -fsSL .../create.sh) my-project --engine=dual
  ```

### Changed
- `setup.sh` now validates engine parameter (claude|codex|dual)
- Prerequisite checks are engine-aware (only checks relevant CLIs)
- JSON validation skips engine-specific files appropriately
- Summary and next-steps guidance customized per engine

### Note
- `--mode=dual` (Builder+Challenger workflow) and `--engine=dual` (Claude+Codex) are independent
- You can combine them: `--mode=dual --engine=dual` for maximum flexibility

## [10.0.0] - 2026-02-16

### Added
- 🎮 12 interactive HTML playgrounds (one per skill)
  - Project Canvas, Market Simulator, User Journey Builder, Design System Builder
  - GTM Simulator, Copy A/B Tester, Stack Configurator, Architecture Explorer
  - Progress Dashboard, Test Coverage Map, Risk Matrix, Deploy Checklist
- 🛡️ Anti-drift guard system
  - GENIUS_GUARD.md with absolute rules
  - /guard-check and /guard-recover commands
  - Blocking handoffs if artifacts missing
  - PreToolUse hook detects code written outside genius-dev
- 🧠 Persistent memory system
  - memory-capture.sh for structured event capture
  - memory-rollup.sh for daily summaries
  - memory-recover.sh for reconstruction
  - /memory-status, /memory-add, /memory-search, /memory-recover, /memory-forget commands
- 🔄 Self-update system
  - /genius-upgrade command
  - scripts/upgrade.sh for v9→v10 migration
  - VERSION file for version detection
  - genius-updater now checks Genius Team version (not just Claude Code)

### Changed
- All 12 skills now have MANDATORY ARTIFACT sections
- settings.json hooks enriched for memory capture
- BRIEFING.md now includes Recent Events, Key Decisions, Milestones
- Router (genius-team skill) now has blocking handoffs

## [9.0.0] - 2026-02-08
- Initial open source release
- Agent Teams support
- File-based memory system
- 4 operating modes (CLI, IDE, Omni, Dual)
