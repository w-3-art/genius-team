---
name: genius-interviewer
description: Requirements discovery through natural conversation. Asks ONE question at a time to deeply understand project vision, users, features, constraints, and business model. Use when starting a new project, user says "I want to build", "help me create", "new project", "I have an idea", "let's build", "I need an app", "start from scratch", "new app", "build me", "interview me".
user-invocable: true
allowed-tools:
  - Read(*)
  - Write(*)
  - Glob(*)
  - WebSearch(*)
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

# Genius Interviewer v9.0 — The Discovery Master

**Understanding your vision before we build.**

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

### Phase 2: The Users (2-3 questions)
- Who is this for?
- What's their current solution?
- How will they find you?

### Phase 3: Core Features (3-4 questions)
- What's the ONE thing it must do?
- What happens when a user first arrives?
- Walk me through the main user journey.

### Phase 4: Constraints (2-3 questions)
- Timeline expectations?
- Budget for services?
- Any technical requirements?

### Phase 5: Business Model (2-3 questions)
- How will this make money?
- Pricing thoughts?
- What does success look like?

### Phase 6: Risk Discovery (2-3 questions)
- What could make this project fail?
- Any dependencies on external parties?
- Decisions still pending?

### Phase 7: Validation
Summarize understanding and confirm.

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

## Playground Integration

### State Collection During Interview

While conducting the interview, maintain an internal state object with all discoveries:

```javascript
// Mental model - collect this data throughout the interview
interviewState = {
    projectName: "",      // Layer 2-5 answers
    problem: "",          // Layer 1 - core pain
    solution: "",         // How we solve it
    users: "",            // Target personas
    value: "",            // Unique value proposition
    features: "",         // Key features (bullet list)
    notes: {
        problem: "",      // Deep problem insights
        solution: "",     // Technical approach notes
        users: "",        // User research findings
        value: "",        // Competitive analysis
        features: ""      // Priority/roadmap notes
    },
    tags: {
        problem: [],      // e.g., ["Urgent", "Expensive"]
        solution: [],     // e.g., ["AI-powered", "Automated"]
        users: [],        // e.g., ["B2B", "Enterprise"]
        value: [],        // e.g., ["Faster", "Better UX"]
        features: []      // e.g., ["MVP", "V2"]
    }
}
```

### Generate Interactive Canvas

After the interview is complete, generate the visual playground:

```bash
# 1. Ensure output directory exists
mkdir -p .genius/outputs

# 2. Copy the template
cp playgrounds/templates/project-canvas.html .genius/outputs/DISCOVERY.html

# 3. Inject the interview data into the HTML
# Use sed or inline script to populate the state object
# The template has a `state` object in JavaScript that we populate

# 4. Open the playground for user validation
open .genius/outputs/DISCOVERY.html
```

### Data Injection

Inject collected data by replacing the empty state initialization in the HTML:

```javascript
// Find and replace the state initialization with populated data:
const state = {
    projectName: 'YOUR_PROJECT_NAME',
    problem: 'YOUR_PROBLEM_STATEMENT',
    solution: 'YOUR_SOLUTION',
    users: 'YOUR_TARGET_USERS',
    value: 'YOUR_VALUE_PROP',
    features: 'YOUR_FEATURES_LIST',
    notes: {
        problem: 'DEEP_PROBLEM_NOTES',
        solution: 'TECHNICAL_NOTES',
        users: 'USER_RESEARCH',
        value: 'COMPETITIVE_ANALYSIS',
        features: 'PRIORITY_NOTES'
    },
    tags: {
        problem: ['tag1', 'tag2'],
        solution: ['tag1'],
        users: ['B2B'],
        value: ['Faster'],
        features: ['MVP']
    }
};
```

Also populate the textarea values using JavaScript at the end of init():
```javascript
// Add after state injection - populate form fields
document.getElementById('project-name').value = state.projectName;
document.getElementById('problem').value = state.problem;
document.getElementById('solution').value = state.solution;
document.getElementById('users').value = state.users;
document.getElementById('value').value = state.value;
document.getElementById('features').value = state.features;
document.getElementById('note-problem').value = state.notes.problem;
document.getElementById('note-solution').value = state.notes.solution;
document.getElementById('note-users').value = state.notes.users;
document.getElementById('note-value').value = state.notes.value;
document.getElementById('note-features').value = state.notes.features;
updateAll();
```

### User Validation Flow

1. **Open playground**: User sees the visual mind map with all interview data
2. **Adjust if needed**: User can drag nodes, edit text, toggle tags
3. **Copy Summary**: User clicks "📋 Copy Summary" to get the structured output
4. **Proceed**: The copied prompt output becomes input for `genius-product-market-analyst`

### Dual Output (Compatibility)

Always generate BOTH outputs:
1. `.genius/outputs/DISCOVERY.html` — Interactive playground for visual validation
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

**DO:**
- Lead with benefits
- Use the 5 Whys technique
- Document faithfully
- Challenge assumptions respectfully
