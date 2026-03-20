#!/bin/bash
# Autoresearch loop — Genius Team v19 + Website
# 25h budget, iterative improvement

set -e
REPO="/Users/benbot/genius-team"
LOG="$REPO/autoresearch/v19/log.md"
PROGRAM="$REPO/autoresearch/v19/program.md"
MAX_ITERATIONS=20
ITERATION=0

mkdir -p "$REPO/autoresearch/v19"
echo "# Autoresearch v19 Log — $(date)" > "$LOG"
echo "" >> "$LOG"

###############################
# PHASE 1: SITE — Complete P3
###############################
ITERATION=$((ITERATION + 1))
echo "=== PHASE 1: Complete P3 website (iteration $ITERATION) — $(date) ===" | tee -a "$LOG"

cd "$REPO" && claude --permission-mode bypassPermissions --print "
READ THESE FILES FIRST:
1. $PROGRAM (the full plan)
2. $REPO/docs/proposition3.html (the current P3 — our best base)
3. $REPO/docs/index.html (the current production site — has sections P3 is missing)

YOUR TASK — Complete P3 to be a FULL production-ready site:

SECTIONS IN index.html THAT P3 IS MISSING:
- Operating Modes (CLI/IDE/Omni/Dual) — key differentiator
- Interactive Playgrounds section
- Quick Start (wizard/install) — currently only a basic CTA
- Upgrade section (for existing users)
- FAQ section
- What's New in v18 section
- The full 42 skills list (P3 only has 6 categories, needs the detail too)

WHAT TO KEEP FROM P3:
- The premium gold visual identity (DM Sans, gold #D4A574, dark bg #0F0F0F)
- The editorial feel with generous spacing
- The timeline workflow section
- The philosophy section
- The testimonials
- GSAP + Lenis scroll animations
- The existing quality level

WHAT TO ADD (from index.html adapted to P3's style):
1. An Operating Modes section — show the 4 modes with brief descriptions
2. A Quick Start section with the wizard OR a simple install command block
3. A FAQ section (accordion style matching P3's editorial tone)
4. Skills detail — expandable from the 6 categories to see individual skills
5. What's New badge/section mentioning v18 highlights briefly

IMPORTANT:
- Keep it aéré and simple — don't cram everything into a wall
- Consider adding separate pages if it makes more sense (e.g., /docs, /getting-started)
- Messaging: vibe coding toolkit, agents GUIDE you, not magic
- wizard.js must stay integrated
- Update prop-nav if adding pages
- The page should feel COMPLETE — not a demo or draft

After completing:
1. Write the updated file
2. Score it on: completeness vs index.html, visual quality, clarity, density
3. Write scores to $LOG
4. Commit: cd $REPO && git add -A && git commit -m 'autoresearch v19: iteration $ITERATION — complete P3 site' && git push origin main
" 2>&1 | tee -a "$LOG"

echo "--- End Phase 1 iteration ---" >> "$LOG"
sleep 5

###############################
# PHASE 2: v19 Code Changes
###############################
ITERATION=$((ITERATION + 1))
echo "=== PHASE 2: v19 code changes (iteration $ITERATION) — $(date) ===" | tee -a "$LOG"

cd "$REPO" && claude --permission-mode bypassPermissions --print "
READ $PROGRAM for context.

YOUR TASK — Prepare Genius Team v19.0.0:

KEY NEW FEATURES FOR v19 (based on March 2026 developments):

1. CLAUDE CODE CHANNELS SUPPORT
   - Create or update a skill to document how to use Genius Team via Telegram/Discord
   - This is NOT a custom implementation — it's documenting how to use CC's built-in Channels feature WITH Genius Team
   - Add to TOOLS.md as a new capability

2. VOICE MODE GUIDE
   - Document /voice command usage within Genius Team workflows
   - Which skills benefit most from voice? (brainstorming with genius-pm, quick commands)

3. 1M CONTEXT OPTIMIZATION  
   - Update compaction strategy references for Opus 4.6's 1M window
   - Less aggressive compaction = better session continuity

4. /LOOP INTEGRATION
   - Document /loop for genius-experiments autoresearch loops
   - Simplifies the bash-loop approach we currently use

5. EFFORT LEVELS
   - Document /effort command in TOOLS.md
   - Suggest effort levels per skill type

FILE CHANGES NEEDED:
- VERSION: 18.0.0 → 19.0.0
- CHANGELOG.md: new entry at top
- TOOLS.md: updated tool versions (CC v2.1.76)
- README.md: version references
- scripts/upgrade.sh: new upgrade function
- .claude/commands/genius-upgrade.md: updated
- Any new/updated SKILL.md files as needed

RELEASE CHECKLIST from MEMORY.md must be followed.

After completing:
1. Make all changes
2. Log what was done to $LOG
3. Commit: cd $REPO && git add -A && git commit -m 'feat: v19.0.0 — Claude Channels, Voice, 1M context, /loop, /effort' && git push origin main
" 2>&1 | tee -a "$LOG"

echo "--- End Phase 2 ---" >> "$LOG"
sleep 5

###############################
# PHASE 3: Autoresearch Iterations
###############################
while [ $ITERATION -lt $MAX_ITERATIONS ]; do
  ITERATION=$((ITERATION + 1))
  echo "=== PHASE 3: Improvement iteration $ITERATION — $(date) ===" | tee -a "$LOG"
  
  PREV_SCORES=$(tail -60 "$LOG" 2>/dev/null || echo "no previous scores")
  
  cd "$REPO" && claude --permission-mode bypassPermissions --print "
AUTORESEARCH ITERATION $ITERATION

Read the previous iteration results:
$PREV_SCORES

Read the program: $PROGRAM

YOUR TASK: Look at what still needs improvement and make ONE targeted fix.

AREAS TO CHECK (pick the weakest):
1. Website P3 — visual quality, completeness, interactions, responsive
2. Website P3 — messaging accuracy (vibe coding, not magic)
3. v19 release — anything missing from the release checklist
4. v19 skills — are they complete and useful?
5. Site deploy — verify with curl -sI https://genius.w3art.io/proposition3 | head -1
6. Cross-check: does the site mention v19 features? Does v19 mention the site?

Make ONE improvement, log it, commit it.
cd $REPO && git add -A && git commit -m 'autoresearch v19: iteration $ITERATION — [brief description]' && git push origin main

Write new scores/assessment to stdout.
" 2>&1 | tee -a "$LOG"
  
  echo "--- End iteration $ITERATION ---" >> "$LOG"
  sleep 5
done

echo "" >> "$LOG"
echo "# AUTORESEARCH COMPLETE — $(date)" >> "$LOG"
echo "Total iterations: $ITERATION" >> "$LOG"

cd "$REPO" && git add -A && git commit -m "autoresearch v19: final log after $ITERATION iterations" && git push origin main || true

echo "Done! Check the log at $LOG"
