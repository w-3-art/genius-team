# Production Deployment Checklist (Genius Team v23.0)

**Strict rule:** Do not deploy or consider production-ready until this checklist is 100% complete with zero errors.

## Plugin Foundation (Phase 1)
- [x] 20+ skills created and verified
- [x] Bootstrap with production safeguards
- [x] Bug fix (docs/HTML leakage) implemented and tested
- [x] Verification script passes

## Main Repo Integration (Phase 2)
- [x] README, AGENTS.md, CLAUDE.md updated for v23.0
- [x] .gitignore updated with site exclusion
- [x] plugin-mode.json template created
- [x] Migration script created
- [x] Main verify.sh updated with plugin check

## Testing (Phase 3)
- [x] Clean install test: 0 leakage
- [x] Verify.sh passes in test project
- [x] Bootstrap production safeguards verified (never fail silently, session logging, plugin-mode.json)
- [ ] Real Claude Code session testing (P0-P3 flow, auto-trigger, guard, dual-mode)
- [ ] Zero errors in real session

## Production Readiness (Phase 4)
- [ ] All real-world tests pass with 100% confidence
- [ ] No errors in Claude Code session
- [ ] Migration tested on existing project
- [ ] Dual-mode handoff verified end-to-end
- [ ] Guard enforcement blocks violations
- [ ] Auto-trigger works without manual invocation

**Final sign-off required:** User must confirm real Claude Code session testing completed with zero errors before any production use.

**Do not stop until this is 100% green.**