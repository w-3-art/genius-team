---
name: genius-deployer
description: Deployment and operations skill that handles staging and production deployments, monitors systems, reads logs, diagnoses issues, and manages rollbacks. Works with Vercel, Railway, and other platforms. Use for "deploy", "go live", "push to production", "ship it".
---

## ⚠️ MANDATORY ARTIFACT

**This skill MUST generate:**
- Log: `DEPLOY-LOG.md`
- HTML Playground: `.genius/outputs/DEPLOY-CHECKLIST.html`

**Before transitioning to next skill:**
1. Verify DEPLOY-LOG.md exists
2. Verify HTML playground exists
3. Update state.json checkpoint
4. Announce transition

**If artifacts missing:** DO NOT proceed. Generate them first.

---

# Genius Deployer v9.0 — Ship It Safely

**Ships code to production with zero downtime. Never deploy on Friday at 5pm.**

## Memory Integration

### On Deploy Start
Read `@.genius/memory/BRIEFING.md` for deployment history and env config.

### On Deploy Success
Append to `.genius/memory/decisions.json`:
```json
{"id": "d-XXX", "decision": "DEPLOYED: [version] to [env]", "reason": "all checks passed", "timestamp": "ISO-date", "tags": ["deployment", "success"]}
```

### On Deploy Failure
Append to `.genius/memory/errors.json`:
```json
{"id": "e-XXX", "error": "DEPLOY FAILED: [version] to [env] — [error]", "solution": "[rollback or fix]", "timestamp": "ISO-date", "tags": ["deployment", "failed"]}
```

---

## Deployment Protocol

### 1. Pre-Deploy Checklist
- [ ] All tests pass
- [ ] TypeScript compiles
- [ ] Lint clean
- [ ] Build succeeds
- [ ] Environment variables set
- [ ] Database migrations ready
- [ ] NOT Friday after 3pm

### 2. Staged Deployment
Build → Deploy to Staging → Smoke Test → Deploy to Production → Monitor (15 min)

### 3. Rollback Procedure
When: Error rate > 5%, critical flow broken, security vulnerability

```bash
# Vercel
vercel rollback
# Railway
railway rollback
```

---

## Platform Commands

### Vercel
`vercel`, `vercel --prod`, `vercel logs`, `vercel rollback`

### Railway
`railway up`, `railway logs`, `railway rollback`

---

## Handoffs

### From genius-qa + genius-security
Receives: QA approval, security clearance

### To genius-debugger (on issue)
Provides: Deployment logs, error messages, environment context

---

## Playground Integration

### Deploy Checklist Playground
Before any deployment, generate an interactive checklist for human validation.

**Template:** `playgrounds/templates/deploy-checklist.html`
**Output:** `.genius/outputs/DEPLOY-CHECKLIST.html`

### Deployment Flow with Checklist

```
1. GENERATE → Create project-specific checklist
2. PRESENT  → Open checklist in Canvas for user
3. VALIDATE → User checks items interactively
4. CONFIRM  → Wait for GO status
5. DEPLOY   → Execute deployment
6. UPDATE   → Record status in memory
```

### Generating the Checklist

Copy the template and customize:
```bash
cp playgrounds/templates/deploy-checklist.html .genius/outputs/DEPLOY-CHECKLIST.html
```

Pre-fill project info in the HTML:
- `projectName`: Project being deployed
- `versionTag`: Version/commit/tag being deployed
- `targetEnv`: Target environment (staging/production)
- `deployDate`: Scheduled deployment time

### Presets

Select the appropriate deployment type:

| Preset | Use Case | Key Items |
|--------|----------|-----------|
| 🆕 **First Deploy** | New project going live | SSL, DNS, basic smoke tests |
| 🔥 **Hotfix** | Emergency fix | Minimal checks, fast rollback |
| 📦 **Major Release** | Version bump, new features | Full test suite, migrations, monitoring |
| 🗃️ **Database Migration** | Schema changes | Backup, rollback scripts, maintenance mode |

### Interactive Validation

The user validates each item through three states:
- **✗ Not Done** (red) → Item not started
- **⏳ In Progress** (orange, animated) → Currently being done
- **✓ Done** (green) → Item completed

**Features:**
- ⏱️ **Timer per item** — Tracks time spent in "In Progress"
- 🚨 **Blocker detection** — Critical items block deployment
- 📊 **Progress bar** — Visual completion percentage
- 🔙 **Rollback plan** — Document rollback strategy inline

### Go/No-Go Indicator

| Status | Meaning |
|--------|---------|
| ✅ **GO** | All critical items done, ready to deploy |
| ⏳ **WAIT** | No blockers but items in progress |
| 🚫 **NO-GO** | Critical blockers remain |

**Rule:** NEVER deploy with NO-GO status.

### Deployment Phases

#### Phase 1: Pre-Deploy 📋
Environment, database, code, and test verification.
- Environment variables configured ⚠️ CRITICAL
- Database backup completed ⚠️ CRITICAL
- Code review approved ⚠️ CRITICAL
- All test suites passing ⚠️ CRITICAL

#### Phase 2: Deploy 🚀
Actual deployment execution.
- Team notified
- Maintenance mode (if needed)
- Deployment executed ⚠️ CRITICAL
- Deployment verified

#### Phase 3: Post-Deploy ✅
Verification and monitoring.
- Error rates checked ⚠️ CRITICAL
- Performance baseline established
- Smoke tests passed ⚠️ CRITICAL
- DNS/CDN/SSL verified

#### Phase 4: Rollback Plan 🔙
Preparation for potential rollback.
- Previous version tagged
- DB rollback script tested
- On-call team identified
- Rollback timeline defined

### Prompt Output Format

When user clicks "Copy", the checklist generates a status report:

```
# DEPLOYMENT CHECKLIST STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 📊 STATUS: ✅ GO - Ready to Deploy!

## 📋 Project Info
- Project: my-awesome-app
- Version: v2.1.0
- Environment: production

## 📈 Progress: 95%
- ✓ Done: 28
- ⏳ In Progress: 1
- ✗ Not Done: 1

## 🚨 BLOCKERS (0)
None

## 📊 Phase Summary
📋 Pre-Deploy: [██████████] 100%
🚀 Deploy: [████████░░] 80%
✅ Post-Deploy: [██████████] 100%
🔙 Rollback Plan: [██████████] 100%

## 🔙 Rollback Plan
1. Revert to v2.0.9: docker pull myapp:v2.0.9
2. Restore DB: pg_restore backup_20240115.sql
...
```

### Integration with Memory

**On checklist completion (GO):**
```json
{"id": "d-XXX", "decision": "DEPLOY APPROVED: [version] to [env]", "reason": "checklist passed", "timestamp": "ISO", "tags": ["deployment", "checklist", "approved"]}
```

**On deployment blocked (NO-GO):**
```json
{"id": "d-XXX", "decision": "DEPLOY BLOCKED: [version] to [env]", "reason": "[blocker list]", "timestamp": "ISO", "tags": ["deployment", "checklist", "blocked"]}
```

### Usage Example

```
User: Deploy to production

Agent:
1. Reads BRIEFING.md for deployment context
2. Copies deploy-checklist.html to .genius/outputs/
3. Pre-fills project info
4. Presents checklist via Canvas
5. Waits for GO status
6. Executes deployment protocol
7. Records decision in memory
```
