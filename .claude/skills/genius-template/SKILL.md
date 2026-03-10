---
name: genius-template
description: >-
  Project template bootstrapper. Imports pre-built project templates for common
  app types: SaaS, e-commerce, mobile app, game, web3/DeFi, landing page, API.
  Sets up the project structure, initial files, and configures Genius Team skills
  for the template type. Use when user says "start from a template", "SaaS boilerplate",
  "e-commerce starter", "create from template", "/genius-template",
  "bootstrap a SaaS", "mobile app starter", "landing page template".
  Do NOT use for custom projects — use /genius-start with the interview flow instead.
context: fork
agent: >-
  You are the Project Bootstrapper on the Genius Team. You scaffold production-ready
  project structures from opinionated templates, so teams start with best practices
  already in place rather than accumulating technical debt from day one.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - exec
hooks:
  pre: read .genius/state.json
  post: update .genius/state.json with project.template and project.stack
---

# genius-template — Project Template Bootstrapper

## Available Templates

| Template | Stack | Best For |
|----------|-------|---------|
| `saas` | Next.js + Supabase + Stripe + Resend + shadcn/ui | B2B/B2C SaaS with subscriptions |
| `ecommerce` | Next.js + Medusa.js + Stripe + Cloudinary | Online stores, marketplaces |
| `mobile` | Expo + Supabase + React Navigation + Expo Notifications | iOS/Android apps |
| `landing` | Next.js + Tailwind + Framer Motion + Resend | Product landing pages, waitlists |
| `api` | Node.js + Fastify + Prisma + PostgreSQL + Zod | REST/GraphQL APIs, microservices |
| `web3` | Next.js + wagmi + viem + Dune MCP + genius-crypto | DeFi, NFT, Web3 apps |
| `game` | Phaser.js + Socket.io | Real-time multiplayer browser games |

---

## Template Selection Protocol

### Step 1 — Identify Template

If user ran `/genius-template {name}` → use that template directly.

Otherwise, present options:

```
Available templates:

1. saas       — Next.js + Supabase + Stripe + Resend + shadcn/ui
2. ecommerce  — Next.js + Medusa.js + Stripe + Cloudinary
3. mobile     — Expo + Supabase + React Navigation + Expo Notifications
4. landing    — Next.js + Tailwind + Framer Motion + Resend
5. api        — Node.js + Fastify + Prisma + PostgreSQL + Zod
6. web3       — Next.js + wagmi + viem + Dune MCP + genius-crypto
7. game       — Phaser.js + Socket.io (real-time multiplayer)

Which template? (or describe what you're building)
```

### Step 2 — Confirm Stack

Before generating, confirm:
- Project name
- Primary language (TypeScript preferred)
- Database preferences (if applicable)
- Deployment target (Vercel / Railway / Fly.io / App Store)

### Step 3 — Generate Project Structure

---

## Template Specifications

### `saas` — SaaS Starter

```
my-saas/
├── app/
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   ├── signup/page.tsx
│   │   └── callback/route.ts
│   ├── (dashboard)/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── settings/page.tsx
│   ├── (marketing)/
│   │   ├── page.tsx           ← Landing page
│   │   └── pricing/page.tsx
│   └── api/
│       ├── webhooks/stripe/route.ts
│       └── webhooks/supabase/route.ts
├── components/
│   ├── ui/                    ← shadcn/ui components
│   ├── auth/
│   └── dashboard/
├── lib/
│   ├── supabase/
│   │   ├── client.ts
│   │   ├── server.ts
│   │   └── middleware.ts
│   ├── stripe.ts
│   ├── resend.ts
│   └── utils.ts
├── supabase/
│   └── migrations/
│       └── 0001_initial.sql
├── .env.example
├── package.json
└── README.md
```

```bash
# Setup commands
npx create-next-app@latest my-saas --typescript --tailwind --app --src-dir=no
cd my-saas
npx shadcn@latest init
npm install @supabase/supabase-js @supabase/ssr stripe @stripe/stripe-js resend
npm install -D supabase
```

```sql
-- supabase/migrations/0001_initial.sql
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  email text,
  full_name text,
  avatar_url text,
  plan text default 'free',
  stripe_customer_id text,
  created_at timestamptz default now()
);
alter table public.profiles enable row level security;
create policy "Users can view own profile" on public.profiles
  for select using (auth.uid() = id);
```

**Recommended Genius Team skills:**
- `genius-dev-backend` — API routes, auth logic, Stripe webhooks
- `genius-dev-frontend` — UI components, dashboard
- `genius-analytics` — PostHog setup, funnel tracking
- `genius-performance` — Lighthouse audit before launch

---

### `ecommerce` — E-commerce Starter

```
my-store/
├── storefront/               ← Next.js frontend
│   ├── app/
│   │   ├── (store)/
│   │   │   ├── page.tsx
│   │   │   ├── products/[handle]/page.tsx
│   │   │   └── cart/page.tsx
│   │   └── api/
│   ├── lib/medusa.ts
│   └── package.json
├── backend/                  ← Medusa.js server
│   ├── src/
│   │   ├── api/
│   │   └── modules/
│   ├── medusa-config.ts
│   └── package.json
├── .env.example
└── docker-compose.yml
```

```bash
# Medusa backend
npx create-medusa-app@latest my-store
# Next.js storefront
npx create-next-app@latest storefront --typescript --tailwind --app
npm install @medusajs/medusa-js cloudinary
```

**Recommended skills:**
- `genius-dev-backend` — Custom Medusa modules, payment providers
- `genius-dev-frontend` — Product pages, cart, checkout
- `genius-seo` — Product schema markup, category pages
- `genius-analytics` — E-commerce tracking (add_to_cart, purchase events)

---

### `mobile` — Expo Mobile Starter

```
my-app/
├── app/
│   ├── (tabs)/
│   │   ├── index.tsx
│   │   └── profile.tsx
│   ├── (auth)/
│   │   ├── login.tsx
│   │   └── signup.tsx
│   └── _layout.tsx
├── components/
│   ├── ui/
│   └── screens/
├── lib/
│   ├── supabase.ts
│   └── notifications.ts
├── assets/
├── app.json
└── package.json
```

```bash
npx create-expo-app@latest my-app --template
cd my-app
npx expo install @supabase/supabase-js @react-native-async-storage/async-storage
npx expo install expo-notifications expo-device expo-constants
npm install @react-navigation/native @react-navigation/bottom-tabs
```

**Recommended skills:**
- `genius-dev-mobile` — Native features, push notifications, app store
- `genius-analytics` — PostHog mobile SDK
- `genius-performance` — Bundle size, startup time

---

### `landing` — Landing Page Starter

```
my-landing/
├── app/
│   ├── page.tsx              ← Main landing page
│   ├── thank-you/page.tsx    ← Post-signup
│   └── api/
│       └── waitlist/route.ts
├── components/
│   ├── sections/
│   │   ├── Hero.tsx
│   │   ├── Features.tsx
│   │   ├── Testimonials.tsx
│   │   ├── Pricing.tsx
│   │   └── CTA.tsx
│   └── ui/
├── lib/resend.ts
└── package.json
```

```bash
npx create-next-app@latest my-landing --typescript --tailwind --app
npm install framer-motion resend
npx shadcn@latest init
```

**Recommended skills:**
- `genius-copywriter` — Hero copy, value propositions, CTAs
- `genius-seo` — Meta tags, structured data, Open Graph
- `genius-analytics` — Conversion tracking, heatmaps

---

### `api` — Node.js API Starter

```
my-api/
├── src/
│   ├── routes/
│   │   ├── users.ts
│   │   └── health.ts
│   ├── plugins/
│   │   ├── auth.ts
│   │   └── prisma.ts
│   ├── schemas/
│   │   └── user.ts           ← Zod schemas
│   └── server.ts
├── prisma/
│   └── schema.prisma
├── .env.example
├── Dockerfile
└── package.json
```

```bash
npm init -y
npm install fastify @fastify/jwt @fastify/cors @prisma/client zod
npm install -D typescript @types/node prisma tsx
npx prisma init
```

**Recommended skills:**
- `genius-dev-api` — Route handlers, middleware, auth
- `genius-dev-backend` — Business logic, database design
- `genius-docs` — OpenAPI/Swagger docs

---

### `web3` — Web3 / DeFi Starter

```
my-dapp/
├── app/
│   ├── page.tsx
│   └── api/
│       └── dune/route.ts     ← Dune MCP proxy
├── components/
│   ├── ConnectWallet.tsx
│   ├── ContractRead.tsx
│   └── TransactionStatus.tsx
├── lib/
│   ├── wagmi.ts
│   └── contracts/
│       └── MyContract.ts
├── contracts/                ← Solidity (optional)
│   └── MyContract.sol
└── package.json
```

```bash
npx create-next-app@latest my-dapp --typescript --tailwind --app
npm install wagmi viem @tanstack/react-query
npm install @rainbow-me/rainbowkit
```

**Recommended skills:**
- `genius-crypto` — Smart contract interaction, DeFi integrations
- `genius-dev-frontend` — dApp UI, wallet connection UX
- `genius-security` — Smart contract audit checklist

---

### `game` — Phaser.js Game Starter

```
my-game/
├── src/
│   ├── scenes/
│   │   ├── MainMenu.ts
│   │   ├── Game.ts
│   │   └── GameOver.ts
│   ├── objects/
│   ├── config/
│   │   └── game.config.ts
│   └── main.ts
├── server/                   ← Socket.io multiplayer server
│   └── index.ts
├── public/
│   └── assets/
├── package.json
└── vite.config.ts
```

```bash
npm create vite@latest my-game -- --template vanilla-ts
npm install phaser socket.io-client
npm install -D @types/node vite-plugin-static-copy
# Server
npm install socket.io express
```

**Recommended skills:**
- `genius-dev-frontend` — Game UI, menus, HUD
- `genius-performance` — Asset optimization, loading screens

---

## Step 4 — Generate Initial Files

After template selection, generate:

1. **`README.md`** — Project-specific with setup instructions
2. **`.env.example`** — All required environment variables documented
3. **`package.json`** — Correct scripts (dev, build, start, test)
4. **`src/`** — Minimal working scaffold (not empty files)
5. **`.genius/state.json`** — Template context

---

## Step 5 — Initialize State

```json
// .genius/state.json
{
  "project": {
    "name": "{project-name}",
    "template": "saas",
    "stack": ["nextjs", "supabase", "stripe", "resend", "shadcn"],
    "deployment": "vercel",
    "created_at": "2026-03-10"
  },
  "recommended_skills": [
    "genius-dev-backend",
    "genius-dev-frontend",
    "genius-analytics"
  ],
  "phase": "setup"
}
```

---

## Handoff (by template type)

- **SaaS** → `genius-dev-backend` (auth + billing) → `genius-dev-frontend` (dashboard) → `genius-analytics`
- **E-commerce** → `genius-dev-backend` (catalog + orders) → `genius-seo` (product schema)
- **Mobile** → `genius-dev-mobile` → `genius-analytics`
- **Landing** → `genius-copywriter` (copy) → `genius-seo` (meta) → `genius-analytics` (conversion)
- **API** → `genius-dev-api` → `genius-docs` (OpenAPI)
- **Web3** → `genius-crypto` → `genius-dev-frontend`
- **Game** → `genius-dev-frontend` → `genius-performance`
