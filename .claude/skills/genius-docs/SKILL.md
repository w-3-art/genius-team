---
name: genius-docs
description: >-
  Technical documentation skill. Creates README, API documentation, component docs
  (Storybook), Architecture Decision Records (ADRs), and user guides. Follows the
  Divio documentation system (tutorials, how-tos, explanations, references).
  Use when user says "write documentation", "README", "API docs", "Storybook",
  "document this", "ADR", "architecture decision", "user guide", "changelog",
  "OpenAPI", "Swagger", "Docusaurus", "add JSDoc", "document the API".
  Do NOT use for marketing copy (genius-copywriter) or blog content (genius-content).
context: fork
agent: >-
  You are the Documentation Engineer on the Genius Team. You write clear, accurate,
  and maintainable documentation following the Divio system. You believe good docs
  are a product feature, not an afterthought.
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - exec
hooks:
  pre: read .genius/state.json
  post: update .genius/state.json with docs.types and docs.paths
---

# genius-docs — Technical Documentation

## Principles (Divio Documentation System)

Documentation has **four distinct types** — mixing them confuses readers:

| Type | Answers | Analogy |
|------|---------|---------|
| **Tutorial** | "How do I learn this?" | Cooking lesson |
| **How-to Guide** | "How do I solve X?" | Recipe |
| **Explanation** | "Why does this work this way?" | Article |
| **Reference** | "What exactly does X do?" | Encyclopedia |

---

## Step-by-Step Protocol

### Step 1 — Audit Existing Docs

```bash
# What docs exist?
find . -name "*.md" -not -path "*/node_modules/*" -not -path "*/.git/*" | head -30
ls docs/ README.md CHANGELOG.md CONTRIBUTING.md 2>/dev/null

# Check API docs
ls openapi.yaml openapi.json swagger.yaml docs/api/ 2>/dev/null

# Check if Storybook is configured
ls .storybook/ 2>/dev/null
cat package.json | grep storybook
```

### Step 2 — README

Every project needs a great README. Use this template:

```markdown
# Project Name

> One-sentence description of what this does and for whom.

[![npm version](https://img.shields.io/npm/v/your-package)](https://npmjs.com/package/your-package)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## What is this?

2-3 sentences. What problem does it solve? Who is it for?

## Why?

Brief motivation. What alternatives exist and why this is different/better.

## Quick Start

\`\`\`bash
npm install your-package
\`\`\`

\`\`\`typescript
import { thing } from 'your-package'

const result = thing({ option: 'value' })
console.log(result)
\`\`\`

## Installation

Prerequisites, detailed install steps, environment setup.

## Usage

### Basic example

### Advanced example

### Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|

## API Reference

Link to full API docs or inline for small APIs.

## Contributing

1. Fork the repo
2. Create feature branch (`git checkout -b feat/amazing`)
3. Commit with conventional commits (`git commit -m 'feat: add amazing feature'`)
4. Push and open a PR

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines.

## License

[MIT](LICENSE) — Copyright © 2026 Your Name
```

### Step 3 — API Documentation (OpenAPI / Swagger)

```yaml
# openapi.yaml
openapi: 3.1.0
info:
  title: Your API
  version: 1.0.0
  description: |
    Your API description. What it does, who it's for.
  contact:
    name: API Support
    email: api@example.com
servers:
  - url: https://api.example.com/v1
    description: Production
  - url: http://localhost:3000/v1
    description: Development

paths:
  /users:
    get:
      summary: List users
      tags: [Users]
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
            maximum: 100
      responses:
        '200':
          description: List of users
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
        '401':
          $ref: '#/components/responses/Unauthorized'
```

```bash
# Generate docs from OpenAPI spec
npx @redocly/cli build-docs openapi.yaml --output docs/api.html
npx swagger-ui-serve openapi.yaml  # Local preview
```

#### Auto-generate from TypeScript (Fastify)

```typescript
// Fastify + @fastify/swagger
import fastifySwagger from '@fastify/swagger'
import fastifySwaggerUi from '@fastify/swagger-ui'

await app.register(fastifySwagger, {
  openapi: {
    info: { title: 'My API', version: '1.0.0' },
  },
})
await app.register(fastifySwaggerUi, { routePrefix: '/docs' })
```

### Step 4 — Storybook (Component Documentation)

```bash
# Initialize Storybook
npx storybook@latest init

# Directory structure
src/
  components/
    Button/
      Button.tsx
      Button.stories.tsx  ← add this
      Button.test.tsx
```

```tsx
// Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react'
import { Button } from './Button'

const meta: Meta<typeof Button> = {
  component: Button,
  title: 'Components/Button',
  tags: ['autodocs'],  // Auto-generate props docs from TypeScript types
  parameters: {
    layout: 'centered',
  },
  argTypes: {
    variant: {
      control: 'select',
      options: ['primary', 'secondary', 'danger'],
      description: 'Visual style of the button',
    },
  },
}
export default meta
type Story = StoryObj<typeof Button>

export const Primary: Story = {
  args: { variant: 'primary', children: 'Click me' },
}

export const Loading: Story = {
  args: { isLoading: true, children: 'Saving...' },
}

export const Disabled: Story = {
  args: { disabled: true, children: 'Not available' },
}
```

```bash
# Run Storybook
npm run storybook

# Build static docs
npm run build-storybook
```

### Step 5 — Architecture Decision Records (ADRs)

Create `docs/adr/` directory with numbered records:

```markdown
<!-- docs/adr/0001-use-next-auth.md -->
# ADR-0001: Use NextAuth.js for Authentication

**Date:** 2026-03-10
**Status:** Accepted
**Deciders:** Ben, Genius Team

## Context

We need authentication with OAuth providers (Google, GitHub), email/password,
and session management for a Next.js 15 app.

## Decision

We will use NextAuth.js (Auth.js v5) as the authentication solution.

## Rationale

**Considered alternatives:**
- **Supabase Auth** — Good DX but adds vendor dependency; chosen for other projects
- **Clerk** — Best DX, but $25/mo for >10k MAU; budget doesn't support this yet
- **Custom JWT** — Full control, but significant security surface area

**Why NextAuth:**
- First-class Next.js App Router support in v5
- Built-in adapters for Prisma, Drizzle
- Free and open source
- Handles CSRF, session rotation, token refresh

## Consequences

**Positive:**
- Reduces auth implementation time by ~2 weeks
- Community-tested security practices

**Negative:**
- NextAuth v5 (beta) has breaking changes vs v4
- Less flexibility for custom auth flows (magic links, passkeys) vs Clerk

## References

- [Auth.js Documentation](https://authjs.dev)
- [Migration guide v4→v5](https://authjs.dev/getting-started/migrating-to-v5)
```

```bash
# Create ADR template
mkdir -p docs/adr
cat > docs/adr/template.md << 'EOF'
# ADR-XXXX: Title

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-XXXX
**Deciders:** 

## Context
## Decision
## Rationale
## Consequences
## References
EOF
```

### Step 6 — Changelog Automation

```bash
# Install conventional-changelog
npm install --save-dev conventional-changelog-cli

# Generate CHANGELOG.md from git log
npx conventional-changelog -p angular -i CHANGELOG.md -s -r 0
```

```json
// package.json — release workflow
{
  "scripts": {
    "release:patch": "npm version patch && conventional-changelog -p angular -i CHANGELOG.md -s && git add CHANGELOG.md && git commit --amend --no-edit && git push --follow-tags",
    "release:minor": "npm version minor && conventional-changelog -p angular -i CHANGELOG.md -s && git add CHANGELOG.md && git commit --amend --no-edit && git push --follow-tags"
  }
}
```

### Step 7 — Docusaurus (Large Documentation Sites)

```bash
npx create-docusaurus@latest docs-site classic --typescript
cd docs-site
npm run start  # Preview at localhost:3000
npm run build  # Static output in build/
```

```
docs/
  intro.md            → /docs/intro
  tutorial/
    basics.md         → /docs/tutorial/basics
  api/
    overview.md       → /docs/api/overview
blog/
  2026-03-10-release.md → /blog/2026/03/10/release
```

---

## Output

Update `.genius/state.json`:

```json
{
  "docs": {
    "readme": true,
    "openapi": "openapi.yaml",
    "storybook": true,
    "adr_count": 3,
    "changelog": "CHANGELOG.md",
    "docusaurus": false
  }
}
```

---

## Handoff

- **→ genius-copywriter** — Polish user-facing documentation copy
- **→ genius-content** — Turn docs into blog posts / tutorials
- **→ genius-dev-api** — Align OpenAPI spec with actual API implementation

---

## Playground Update (MANDATORY)

After completing your task:
1. **DO NOT create a new HTML file** — update the existing genius-dashboard tab
2. Open `.genius/DASHBOARD.html` and update YOUR tab's data section with real project data
3. If your tab doesn't exist yet, add it to the dashboard (hidden tabs become visible on first real data)
4. Remove any mock/placeholder data from your tab
5. Tell the user: `📊 Dashboard updated → open .genius/DASHBOARD.html`
