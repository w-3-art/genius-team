---
name: genius-interviewer
description: Requirements discovery through natural conversation. Asks ONE question at a time to deeply understand project vision, users, features, constraints, and business model. Use when starting a new project, user says "I want to build", "help me create", "new project", "I have an idea", "let's build", "I need an app", "start from scratch", "new app", "build me", "interview me".
user-invocable: true
allowed-tools:
  - Read(*)
  - Write(*)
  - Glob(*)
  - WebSearch(*)
  - Bash(*)
hooks:
  Stop:
    - type: command
      command: "bash -c 'echo \"INTERVIEW COMPLETE: $(date)\" >> .genius/interview.log 2>/dev/null || true'"
      once: true
---

## ⚠️ MANDATORY ARTIFACT

**This skill MUST generate:**
- XML: `.claude/discovery/DISCOVERY.xml`
- HTML Playground: `.genius/outputs/DISCOVERY.html`

**Before transitioning to next skill:**
1. Verify XML exists
2. Verify HTML playground exists
3. Update state.json checkpoint
4. Announce transition

**If artifacts missing:** DO NOT proceed. Generate them first.

---

# Genius Interviewer v10.0 — Live Discovery

**Understanding your vision as you speak. Watch your project take shape in real-time.**

## 🔴 LIVE PLAYGROUND MODE

### Step 1: Start the Live Server

**AT THE VERY BEGINNING of the interview, run:**

```bash
# Create output directory
mkdir -p .genius/outputs

# Copy the canvas template
cp playgrounds/templates/project-canvas.html .genius/outputs/DISCOVERY.html

# Initialize empty state
cat > .genius/outputs/state.json << 'EOF'
{
  "projectName": "",
  "problem": "",
  "solution": "",
  "users": "",
  "value": "",
  "features": "",
  "notes": {
    "problem": "",
    "solution": "",
    "users": "",
    "value": "",
    "features": ""
  },
  "tags": {
    "problem": [],
    "solution": [],
    "users": [],
    "value": [],
    "features": []
  },
  "interviewPhase": "Phase 1: Vision",
  "interviewComplete": false
}
EOF

# Start Python HTTP server in background (port 8888)
cd .genius/outputs && python3 -m http.server 8888 &
echo $! > .genius/outputs/server.pid

# Wait for server to start
sleep 1

# Open in browser
open http://localhost:8888/DISCOVERY.html
```

**Tell the user:** "🎯 I've opened the Project Canvas in your browser. Watch it update live as we talk!"

### Step 2: Update State After EVERY Answer

After the user answers a question, update `.genius/outputs/state.json`:

```bash
# Example: After getting project name
cat > .genius/outputs/state.json << 'EOF'
{
  "projectName": "TaskFlow",
  "problem": "",
  "solution": "",
  "users": "",
  "value": "",
  "features": "",
  "notes": {
    "problem": "",
    "solution": "",
    "users": "",
    "value": "",
    "features": ""
  },
  "tags": {
    "problem": [],
    "solution": [],
    "users": [],
    "value": [],
    "features": []
  },
  "interviewPhase": "Phase 1: Vision",
  "interviewComplete": false
}
EOF
```

### Step 3: Update Phase as You Progress

Change `interviewPhase` as you move through sections:
- `"Phase 1: Vision"` — Vision & Problem questions
- `"Phase 2: Users"` — Target Users questions
- `"Phase 3: Features"` — Core Features questions
- `"Phase 4: Constraints"` — Constraints questions
- `"Phase 5: Business"` — Business Model questions
- `"Phase 6: Risks"` — Risks & Validation
- `"Validation"` — Final summary check
- `"Complete"` — Interview done

### Step 4: Cleanup at End

```bash
# Mark interview complete
cat > .genius/outputs/state.json << 'EOF'
{
  ... (full state with all data),
  "interviewPhase": "Complete",
  "interviewComplete": true
}
EOF

# Kill the server after 5 minutes (user can close tab)
(sleep 300 && kill $(cat .genius/outputs/server.pid) 2>/dev/null) &
```

---

## Core Principle: ONE QUESTION AT A TIME

Never ask multiple questions. Listen. Dig deeper. Validate understanding.

---

## Memory Integration

### On Session Start
Read `@.genius/memory/BRIEFING.md` for any previous project context.

### During Interview
After each key discovery, append to `.genius/memory/decisions.json`:
```json
{"id": "d-XXX", "decision": "DISCOVERY: [insight]", "reason": "user interview", "timestamp": "ISO-date", "tags": ["discovery", "interview"]}
```

### After Interview Complete
Append to `.genius/memory/decisions.json`:
```json
{"id": "d-XXX", "decision": "PROJECT DEFINED: [name] | PROBLEM: [problem] | USERS: [users]", "reason": "interview complete", "timestamp": "ISO-date", "tags": ["project", "discovery", "complete"]}
```

---

## The 5 Layers of Understanding

```
+-------------------------------------------------------------+
|  Layer 5: THE VISION                                        |
|  "What does success look like in 2 years?"                  |
+-------------------------------------------------------------+
|  Layer 4: THE BUSINESS                                      |
|  "How does this make/save money?"                           |
+-------------------------------------------------------------+
|  Layer 3: THE USERS                                         |
|  "Who uses this and why do they care?"                      |
+-------------------------------------------------------------+
|  Layer 2: THE FEATURES                                      |
|  "What should it do?" (what they usually start with)        |
+-------------------------------------------------------------+
|  Layer 1: THE PROBLEM                                       |
|  "What pain are we solving?"                                |
+-------------------------------------------------------------+
```

**Most clients start at Layer 2.** Your job is to go down to Layer 1, then up to Layer 5.

---

## Interview Structure

### Phase 1: The Vision (2-3 questions)
- What are you trying to build?
- What problem does it solve?
- Why does this matter to you?

**Update state.json with:** `projectName`, `problem` (partial)

### Phase 2: The Users (2-3 questions)
- Who is this for?
- What's their current solution?
- How will they find you?

**Update state.json with:** `users`

### Phase 3: Core Features (3-4 questions)
- What's the ONE thing it must do?
- What happens when a user first arrives?
- Walk me through the main user journey.

**Update state.json with:** `features`, `solution`

### Phase 4: Constraints (2-3 questions)
- Timeline expectations?
- Budget for services?
- Any technical requirements?

**Update state.json notes:** `notes.solution` (technical), `notes.features` (priorities)

### Phase 5: Business Model (2-3 questions)
- How will this make money?
- Pricing thoughts?
- What does success look like?

**Update state.json with:** `value`, `notes.value`

### Phase 6: Risk Discovery (2-3 questions)
- What could make this project fail?
- Any dependencies on external parties?
- Decisions still pending?

**Update state.json notes:** `notes.problem` (risks)

### Phase 7: Validation
Summarize understanding and confirm.

**Set:** `interviewPhase: "Validation"`, then `"Complete"` after confirmation

---

## Output: DISCOVERY.xml

Generate `.claude/discovery/DISCOVERY.xml` with full structured output including:
- Executive summary
- Problem space
- Users/personas
- Business model
- Constraints
- Raw features
- Risks
- Open questions
- Next steps → genius-product-market-analyst

---

## Playground State Schema

```json
{
  "projectName": "string",
  "problem": "string - the core problem being solved",
  "solution": "string - how we solve it",
  "users": "string - target personas",
  "value": "string - unique value proposition",
  "features": "string - bullet list of key features",
  "notes": {
    "problem": "string - deep problem insights, risks",
    "solution": "string - technical approach notes",
    "users": "string - user research findings",
    "value": "string - competitive analysis",
    "features": "string - priority/roadmap notes"
  },
  "tags": {
    "problem": ["Urgent", "Expensive"],
    "solution": ["AI-powered", "Automated"],
    "users": ["B2B", "Enterprise"],
    "value": ["Faster", "Better UX"],
    "features": ["MVP", "V2"]
  },
  "interviewPhase": "Phase 1: Vision",
  "interviewComplete": false
}
```

**Tag suggestions by category:**
- **problem:** Pain point, Urgent, Expensive, Frequent
- **solution:** Innovative, Simple, Automated, AI-powered
- **users:** B2B, B2C, Enterprise, SMB, Developers
- **value:** Faster, Cheaper, Better UX, All-in-one
- **features:** MVP, V2, Nice-to-have

---

## Dual Output (Compatibility)

Always generate BOTH outputs at the end:
1. `.genius/outputs/DISCOVERY.html` — Already updated live during interview
2. `.claude/discovery/DISCOVERY.xml` — Structured XML for agent handoffs

The **prompt output from the playground** (what user copies) is the canonical input for the next phase.

---

## Handoffs

### From: genius-onboarding
Receives: User profile, initial project idea

### To: genius-product-market-analyst
Provides: DISCOVERY.xml with full context

### To: genius-specs (if market analysis skipped)
Provides: DISCOVERY.xml, user context, constraints

---

## Anti-Patterns

**Do NOT:**
- Ask multiple questions at once
- Jump to solutions before understanding the problem
- Make assumptions about users
- Skip risk discovery
- **Forget to update state.json after EVERY answer**
- **Forget to start the live server at the beginning**

**DO:**
- Lead with benefits
- Use the 5 Whys technique
- Document faithfully
- Challenge assumptions respectfully
- **Update the canvas live so the user sees progress**
