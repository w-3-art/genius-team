---
name: genius-specs
description: Transforms discovery findings into formal specifications with user stories, use cases, business rules, and acceptance criteria. REQUIRES USER APPROVAL before continuing to design phase. Use for "specs", "specifications", "requirements", "user stories", "acceptance criteria", "write specs".
---

## ⚠️ MANDATORY ARTIFACT

**This skill MUST generate:**
- XML: `.claude/discovery/SPECIFICATIONS.xml`
- HTML Playground: `.genius/outputs/SPECIFICATIONS.html`

**Before transitioning to next skill:**
1. Verify XML exists
2. Verify HTML playground exists
3. Update state.json checkpoint
4. Announce transition

**If artifacts missing:** DO NOT proceed. Generate them first.

---

# Genius Specs v9.0 — Requirements Architect

**Transforming discoveries into crystal-clear specifications.**

## Memory Integration

### On Session Start
Read `@.genius/memory/BRIEFING.md` for project context and past decisions.

### During Specification
Append to `.genius/memory/decisions.json`:
```json
{"id": "d-XXX", "decision": "SPEC: [story_id] [title] Priority: [priority]", "reason": "derived from discovery", "timestamp": "ISO-date", "tags": ["specification", "user-story"]}
```

### On Complete
Append to `.genius/memory/decisions.json`:
```json
{"id": "d-XXX", "decision": "SPECIFICATIONS COMPLETE: [count] stories, [use_cases] use cases", "reason": "awaiting user approval", "timestamp": "ISO-date", "tags": ["specification", "checkpoint"]}
```

---

## Prerequisites

**REQUIRED before starting:**
- `DISCOVERY.xml` from genius-interviewer
- `MARKET-ANALYSIS.xml` from genius-product-market-analyst (optional)

---

## Specification Process

1. Load Discovery
2. Extract User Stories (As a... I want... So that...)
3. Elaborate Use Cases (preconditions, flows, postconditions)
4. Document Business Rules
5. Define NFRs (performance, security, accessibility)

---

## Output: SPECIFICATIONS.xml

Structured XML with:
- User stories with acceptance criteria (Given/When/Then)
- Use cases with main and alternative flows
- Business rules
- Non-functional requirements
- Data model
- API endpoints
- Screen definitions
- Glossary

---

## Quality Checklist

- [ ] Every story has at least 2 acceptance criteria
- [ ] All criteria are testable (Given/When/Then)
- [ ] Business rules are explicit and unambiguous
- [ ] No implementation details in specs (WHAT, not HOW)
- [ ] NFRs have measurable targets
- [ ] Data model covers all entities
- [ ] API endpoints defined for all actions

---

## CHECKPOINT: User Approval Required

**MANDATORY. Do NOT continue automatically.**

After generating SPECIFICATIONS.xml:
```
SPECIFICATIONS COMPLETE

Summary: [X] stories, [Y] use cases, [Z] business rules

Ready to move to the design phase?
--> "yes" or "approved" to proceed
--> "change [aspect]" to revise
```

---

## Playground Integration

### Overview
The User Journey Builder playground provides an interactive way for users to:
- **Reorder priorities** via drag & drop
- **Adjust scope** (MVP / V1 / Full)
- **Configure sprint capacity** and duration
- **Validate the prioritized backlog** before proceeding

### Updated Flow

1. **Generate user stories** from the discovery phase
2. **Create `.genius/outputs/SPECIFICATIONS.html`** with stories pre-injected
3. **Open the playground** (via canvas) for user interaction
4. **User validates** the final backlog → output prompt becomes the approved spec

### Story Format for Injection

When injecting stories into the playground, use this JavaScript structure:

```javascript
{
  id: number,           // Unique identifier (timestamp or sequential)
  title: string,        // User story title (e.g., "User can sign up with email")
  priority: "must" | "should" | "could" | "wont",  // MoSCoW priority
  estimation: "S" | "M" | "L" | "XL",              // T-shirt sizing
  phase: "MVP" | "V1" | "Full"                     // Delivery phase
}
```

**Estimation Points:**
- `S` = 1 point
- `M` = 3 points
- `L` = 5 points
- `XL` = 8 points

**Priority Mapping:**
- `must` → MVP (core features, must ship)
- `should` → V1 (important but not blocking)
- `could` → Full (nice to have)
- `wont` → Full (parking lot / future)

### Creating SPECIFICATIONS.html

1. Copy template from `playgrounds/templates/user-journey-builder.html`
2. Inject stories into the `state.stories` array in the `<script>` section
3. Save to `.genius/outputs/SPECIFICATIONS.html`

**Example injection:**
```javascript
// Replace the loadFromLocalStorage() call with pre-populated data
document.addEventListener('DOMContentLoaded', () => {
    state.stories = [
        { id: 1, title: "User can register with email", priority: "must", estimate: "M", scope: "mvp" },
        { id: 2, title: "User can login/logout", priority: "must", estimate: "S", scope: "mvp" },
        { id: 3, title: "User can reset password", priority: "should", estimate: "M", scope: "v1" },
        // ... more stories from discovery
    ];
    state.projectName = "Project Name from Discovery";
    updateAll();
});
```

### Opening the Playground

Use canvas to present the generated HTML:
```
canvas:present .genius/outputs/SPECIFICATIONS.html
```

### Output: Validated Backlog

The user copies the **Generated Prompt** from the playground, which contains:
- Sprint planning configuration
- Prioritized backlog by MoSCoW categories
- Implementation order (user-defined via drag & drop)
- Estimated sprints and timeline

This validated output becomes the authoritative specification for the design and architecture phases.

---

## Handoffs

### From: genius-interviewer / genius-product-market-analyst
Receives: DISCOVERY.xml, MARKET-ANALYSIS.xml

### To: genius-designer (after approval)
Provides: SPECIFICATIONS.xml, screen definitions, component list

### To: genius-architect
Provides: SPECIFICATIONS.xml, data model, API endpoints, NFRs
