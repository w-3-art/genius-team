---
description: Check Omni Mode provider availability without reverting to legacy versioning or API-key framing
---

# /omni-status

Check which Omni Mode provider CLIs are actually available on this machine.

## Execution

Run this bash block:

```bash
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🌐 Genius Team v22.0 — Omni Mode Provider Status         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "── Claude Code (Lead Orchestrator) ──"
if command -v claude &>/dev/null; then
  echo "  ✅ Installed: $(claude --version 2>/dev/null | head -1)"
else
  echo "  ❌ Not found (critical for Claude-based flows)"
fi
echo ""

echo "── Codex CLI ──"
if command -v codex &>/dev/null; then
  echo "  ✅ Installed: $(codex --version 2>/dev/null | head -1)"
else
  echo "  ❌ Not installed → fallback to Claude Code"
fi
echo ""

echo "── Kimi CLI ──"
if command -v kimi &>/dev/null; then
  echo "  ✅ Installed: $(kimi --version 2>/dev/null | head -1)"
else
  echo "  ❌ Not installed → fallback to Claude Code"
fi
echo ""

echo "── Gemini CLI ──"
if command -v gemini &>/dev/null; then
  echo "  ✅ Installed: $(gemini --version 2>/dev/null | head -1)"
else
  echo "  ❌ Not installed → fallback to Claude Code"
fi
echo ""

echo "── Summary ──"
AVAILABLE=0
for cmd in claude codex kimi gemini; do
  command -v "$cmd" &>/dev/null && AVAILABLE=$((AVAILABLE + 1))
done
echo "  Providers available: $AVAILABLE/4"
if [ $AVAILABLE -eq 4 ]; then
  echo "  Mode: 🟢 Full Omni"
elif [ $AVAILABLE -gt 1 ]; then
  echo "  Mode: 🟡 Partial Omni"
else
  echo "  Mode: 🔵 Solo"
fi

if [ -f .genius/omni-router.log ]; then
  echo "  Last routing: $(tail -1 .genius/omni-router.log 2>/dev/null)"
fi
```

## Reporting rule

Report only what is actually present on the machine.

Do not infer auth status.
Do not switch back to API-key framing in the command output.
