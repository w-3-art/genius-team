---
name: genius-dev-api
description: >-
  Third-party API integration skill. Wraps external APIs (Stripe, Supabase, Resend,
  Twilio, OpenAI, etc.) into clean SDK wrappers, generates OpenAPI clients, handles
  webhooks and rate limiting. Use when task involves "integrate [service]",
  "Stripe integration", "OpenAI API", "webhook handler", "API client", "SDK wrapper".
  Do NOT use for building your own API (genius-dev-backend) or UI (genius-dev-frontend).
context: fork
agent: genius-dev-api
user-invocable: false
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Glob(*)
  - Grep(*)
  - Bash(npm *)
  - Bash(npx *)
  - Bash(node *)
  - Bash(git diff*)
  - Bash(git status*)
hooks:
  PostToolUse:
    - type: command
      command: "bash -c 'echo \"[$(date +%H:%M:%S)] API-INTEGRATION: $TOOL_NAME\" >> .genius/dev.log 2>/dev/null || true'"
  Stop:
    - type: command
      command: "bash -c 'echo \"API-INTEGRATION COMPLETE: $(date)\" >> .genius/dev.log 2>/dev/null || true'"
      once: true
---

# Genius Dev API v17 — Integration Specialist

**Third-party APIs are dependencies. Wrap them. Test them. Isolate them.**

---

## Mode Compatibility

| Mode | Behavior |
|------|----------|
| **CLI** | Full SDK installation, env var setup, curl testing |
| **IDE** (VS Code/Cursor) | Use `.env.local` for secrets; REST Client for endpoint testing |
| **Omni** | Claude handles wrapper architecture; route to best model for SDK-specific code |
| **Dual** | Claude designs wrapper interfaces; Codex implements provider-specific implementations |

---

## Core Principles

1. **Wrap, don't sprinkle**: Never call third-party SDKs directly in business logic — create a wrapper
2. **Fail gracefully**: Network errors, rate limits, API outages should not crash your app
3. **Retry with backoff**: Transient failures are normal — implement exponential backoff
4. **Idempotent webhooks**: Webhook handlers must be safe to receive multiple times
5. **Secrets in environment**: Never hardcode API keys — always use `process.env`

---

## API Wrapper Pattern

### The standard wrapper structure

```typescript
// lib/integrations/stripe.ts

import Stripe from 'stripe';

// Single instance (singleton)
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2024-06-20',
});

export class StripeService {
  // Wrap each operation — never expose raw Stripe client
  
  async createCustomer(email: string, name: string): Promise<string> {
    try {
      const customer = await stripe.customers.create({ email, name });
      return customer.id;
    } catch (error) {
      if (error instanceof Stripe.errors.StripeError) {
        throw new IntegrationError('stripe', error.code ?? 'unknown', error.message);
      }
      throw error;
    }
  }

  async createCheckoutSession(params: {
    customerId: string;
    priceId: string;
    successUrl: string;
    cancelUrl: string;
  }): Promise<string> {
    const session = await stripe.checkout.sessions.create({
      customer: params.customerId,
      payment_method_types: ['card'],
      line_items: [{ price: params.priceId, quantity: 1 }],
      mode: 'subscription',
      success_url: params.successUrl,
      cancel_url: params.cancelUrl,
    });
    return session.url!;
  }
}

export const stripeService = new StripeService();
```

### Custom error class
```typescript
// lib/errors.ts
export class IntegrationError extends Error {
  constructor(
    public provider: string,
    public code: string,
    message: string,
  ) {
    super(`[${provider}] ${code}: ${message}`);
    this.name = 'IntegrationError';
  }
}
```

---

## Retry Logic with Exponential Backoff

```typescript
// lib/utils/retry.ts
export async function withRetry<T>(
  fn: () => Promise<T>,
  options: {
    maxAttempts?: number;
    initialDelayMs?: number;
    maxDelayMs?: number;
    retryOn?: (error: unknown) => boolean;
  } = {}
): Promise<T> {
  const {
    maxAttempts = 3,
    initialDelayMs = 500,
    maxDelayMs = 10000,
    retryOn = (e) => e instanceof Error && ['ECONNRESET', 'ETIMEDOUT', 'ENOTFOUND'].includes((e as any).code),
  } = options;

  let lastError: unknown;
  
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      
      if (attempt === maxAttempts || !retryOn(error)) throw error;
      
      const delay = Math.min(initialDelayMs * 2 ** (attempt - 1), maxDelayMs);
      const jitter = delay * 0.1 * Math.random();
      await new Promise(resolve => setTimeout(resolve, delay + jitter));
    }
  }
  
  throw lastError;
}

// Usage
const result = await withRetry(() => openai.chat.completions.create(...), {
  maxAttempts: 3,
  retryOn: (e) => e instanceof OpenAI.APIError && e.status === 429,
});
```

---

## Webhook Handling

### Signature verification (critical security step)

```typescript
// routes/webhooks/stripe.ts
import express from 'express';
import Stripe from 'stripe';

const router = express.Router();
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

// ⚠️ Must use raw body for signature verification
router.post('/stripe', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature']!;
  
  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET!);
  } catch (err) {
    console.error('Webhook signature verification failed:', err);
    return res.status(400).send('Webhook Error');
  }

  // Idempotency: check if we've already processed this event
  const existing = await db.webhookEvents.findUnique({ where: { eventId: event.id } });
  if (existing) return res.json({ received: true, duplicate: true });

  // Process event
  await db.webhookEvents.create({ data: { eventId: event.id, type: event.type } });

  switch (event.type) {
    case 'checkout.session.completed':
      await handleCheckoutComplete(event.data.object as Stripe.Checkout.Session);
      break;
    case 'customer.subscription.deleted':
      await handleSubscriptionCancelled(event.data.object as Stripe.Subscription);
      break;
    default:
      console.log(`Unhandled event type: ${event.type}`);
  }

  res.json({ received: true });
});
```

---

## Environment Variables

### Template for `.env.example` (always commit this, never `.env`)

```bash
# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# OpenAI
OPENAI_API_KEY=sk-...
OPENAI_ORG_ID=org-...

# Resend (email)
RESEND_API_KEY=re_...
RESEND_FROM_EMAIL=noreply@yourdomain.com

# Supabase
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...  # ⚠️ Never expose to client

# Twilio (SMS)
TWILIO_ACCOUNT_SID=AC...
TWILIO_AUTH_TOKEN=...
TWILIO_PHONE_NUMBER=+1...
```

### Validate at startup
```typescript
// lib/env.ts
import { z } from 'zod';

const envSchema = z.object({
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  STRIPE_WEBHOOK_SECRET: z.string().startsWith('whsec_'),
  OPENAI_API_KEY: z.string().startsWith('sk-'),
  // ... all required vars
});

export const env = envSchema.parse(process.env);
// Will throw at startup if any required env var is missing/invalid
```

---

## Rate Limiting Patterns

### Client-side rate limit respect
```typescript
class RateLimitedClient {
  private queue: Array<() => Promise<unknown>> = [];
  private processing = false;
  private requestsPerSecond: number;

  constructor(requestsPerSecond = 10) {
    this.requestsPerSecond = requestsPerSecond;
  }

  async enqueue<T>(fn: () => Promise<T>): Promise<T> {
    return new Promise((resolve, reject) => {
      this.queue.push(() => fn().then(resolve, reject));
      if (!this.processing) this.processQueue();
    });
  }

  private async processQueue() {
    this.processing = true;
    while (this.queue.length > 0) {
      const fn = this.queue.shift()!;
      await fn();
      await new Promise(r => setTimeout(r, 1000 / this.requestsPerSecond));
    }
    this.processing = false;
  }
}
```

---

## Common Integrations Quick Reference

| Service | Package | Key Docs |
|---------|---------|----------|
| Stripe | `stripe` | stripe.com/docs/api |
| OpenAI | `openai` | platform.openai.com/docs |
| Resend | `resend` | resend.com/docs |
| Supabase | `@supabase/supabase-js` | supabase.com/docs |
| Twilio | `twilio` | twilio.com/docs |
| Cloudinary | `cloudinary` | cloudinary.com/documentation |
| SendGrid | `@sendgrid/mail` | docs.sendgrid.com |
| Pusher | `pusher` | pusher.com/docs |

For detailed setup guides per service → **genius-integration-guide** skill.

---

## Output

Update `.genius/outputs/state.json` on completion:

```bash
jq --arg ts "$(date -Iseconds)" '.skill = "genius-dev-api" | .status = "complete" | .updatedAt = $ts' .genius/outputs/state.json > .genius/outputs/state.json.tmp && mv .genius/outputs/state.json.tmp .genius/outputs/state.json 2>/dev/null || true
```

---

## Handoff

- → **genius-dev-backend**: Route handlers that use the wrappers
- → **genius-integration-guide**: Full step-by-step setup docs for the service
- → **genius-security**: Review secrets handling and webhook auth
- → **genius-qa-micro**: Mock-based integration tests

---

## Playground Update (MANDATORY)

After completing your task:
1. **DO NOT create a new HTML file** — update the existing genius-dashboard tab
2. Open `.genius/DASHBOARD.html` and update YOUR tab's data section with real project data
3. If your tab doesn't exist yet, add it to the dashboard (hidden tabs become visible on first real data)
4. Remove any mock/placeholder data from your tab
5. Tell the user: `📊 Dashboard updated → open .genius/DASHBOARD.html`
