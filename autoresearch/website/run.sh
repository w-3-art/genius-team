#!/bin/bash
# Autoresearch loop — website overnight
# Runs N iterations of: build → score → improve → commit → repeat

set -e
REPO="/Users/benbot/genius-team"
LOG="$REPO/autoresearch/website/log.md"
PROGRAM="$REPO/autoresearch/website/program.md"
MAX_ITERATIONS=25
ITERATION=0

mkdir -p "$REPO/autoresearch/website"
echo "# Autoresearch Website Log — $(date)" > "$LOG"
echo "" >> "$LOG"

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
  ITERATION=$((ITERATION + 1))
  echo "=== Iteration $ITERATION / $MAX_ITERATIONS — $(date) ===" | tee -a "$LOG"
  
  # Build or improve pages
  PROMPT=""
  if [ $ITERATION -eq 1 ]; then
    PROMPT="ITERATION 1 — BUILD FROM SCRATCH.
    
Read $PROGRAM for full spec.

Build 3 complete HTML pages from scratch:
- $REPO/docs/proposition1.html (Cinematic Amber: Sora, #F59E0B/#F97316, iris clip-path, parallax, cursor glow, 450+ lines)
- $REPO/docs/proposition2.html (Neon Violet: Plus Jakarta Sans, #EC4899/#8B5CF6, floating orbs, card stack, neon glow, 450+ lines)
- $REPO/docs/proposition3.html (Premium Gold: DM Sans, #D4A574/#F5F0EB, timeline vertical with animated line, progress bars, 450+ lines)

ALL pages must:
- Have GSAP + Lenis scroll
- Have wizard.js integrated (GeniusWizard.init() + GeniusWizard.open() on all CTAs)
- Have heading 'Anyone can build' 
- Messaging: vibe coding tool (agents HELP, not DO everything)
- Dense premium content (no empty space)
- 6 skill categories (Ideation 5, Build 7, Quality 5, Growth 5, Ops 4, AI Engine 5)
- Prop-nav at bottom: /proposition1, /proposition2, /proposition3

After writing all 3, write a score for each (1-10) on these criteria to $LOG:
1. Visual impact
2. Clarity (non-tech person understands in 3s)
3. Density (no empty space)
4. Uniqueness vs other pages
5. Messaging (vibe coding, not magic)
6. Interactions (scroll effects, hover, cursor)
7. Responsive
8. Technical quality

Then commit: cd $REPO && git add docs/proposition1.html docs/proposition2.html docs/proposition3.html autoresearch/ && git commit -m 'autoresearch: iteration 1 — build from scratch' && git push origin main"
  else
    PREV_SCORES=$(tail -50 "$LOG" 2>/dev/null || echo "no previous scores")
    PROMPT="ITERATION $ITERATION — IMPROVE WEAKEST AREAS.

Read previous scores from $LOG.
Read $PROGRAM for the full spec and constraints.

Previous iteration results (last 50 lines of log):
$PREV_SCORES

YOUR TASK:
1. Look at the lowest-scoring criterion across all 3 pages
2. Make ONE targeted improvement to fix it
3. Re-read the improved page and re-score it
4. Write new scores to $LOG
5. Commit: cd $REPO && git add -A && git commit -m 'autoresearch: iteration $ITERATION — [what you fixed]' && git push origin main

Focus on: visual richness, dense content, unique interactions per page, messaging accuracy.
Do NOT homogenize the pages — keep their distinct identities.
If a page has empty sections, fill them with real content.
If animations are weak, strengthen them.
If messaging says 'agents do everything', fix to 'agents guide you'."
  fi
  
  echo "Running claude for iteration $ITERATION..." | tee -a "$LOG"
  cd "$REPO" && claude --permission-mode bypassPermissions --print "$PROMPT" 2>&1 | tee -a "$LOG"
  
  echo "" >> "$LOG"
  echo "--- End iteration $ITERATION ---" >> "$LOG"
  echo "" >> "$LOG"
  
  # Brief pause between iterations
  sleep 5
done

echo "Autoresearch complete after $MAX_ITERATIONS iterations" | tee -a "$LOG"
echo "Notifying..."
cd "$REPO" && git add -A && git commit -m "autoresearch: final log after $MAX_ITERATIONS iterations" && git push origin main || true
