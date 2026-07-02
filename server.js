/**
 * Genius Team ecosystem site server (Railway / any Node host).
 *
 * Serves:
 *   - /                    → docs/ static (4 product pages + mockups + assets)
 *   - /api/chat            → POST proxy to Anthropic Messages API
 *   - /api/health          → GET liveness probe
 *   - /updates/latest.json → Tauri auto-updater manifest (served as JSON)
 *   - /updates/*.dmg, *.tar.gz, *.sig → Tauri artifacts (served as octet-stream + CORS)
 *   - /proposition1..5     → rewrites to propositionN.html (kept for inbound links)
 *
 * Env:
 *   PORT                    Railway-assigned (default 3000)
 *   ANTHROPIC_API_KEY       required for /api/chat
 *   ANTHROPIC_MODEL         default 'claude-haiku-4-5'
 *   ALLOWED_CHAT_ORIGINS    optional comma-separated CORS allowlist for /api/chat
 *                           (default: site's own origin — '*' is fine for public chat)
 *
 * IMPORTANT (production/Railway): ALLOWED_CHAT_ORIGINS MUST be set to the site's
 * real origin(s) (e.g. "https://genius.w3art.io") on Railway. Leaving it unset
 * defaults to '*', which lets any third-party site call /api/chat from a
 * browser using this server's ANTHROPIC_API_KEY-backed proxy quota.
 *
 * /api/chat is also rate-limited per client IP (in-memory sliding window,
 * see CHAT_RATE_LIMIT_* below) to bound abuse/cost. This is a single-instance,
 * in-memory limiter — it resets on redeploy and does not share state across
 * multiple Railway replicas. Fine for the current single-instance deployment;
 * revisit with a shared store (e.g. Redis) if the service is ever scaled out.
 */
import { serve } from '@hono/node-server';
import { serveStatic } from '@hono/node-server/serve-static';
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { secureHeaders } from 'hono/secure-headers';
import { readFile, stat } from 'node:fs/promises';
import { createReadStream } from 'node:fs';
import { dirname, join, resolve, extname, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const DOCS_DIR = resolve(__dirname, 'docs');
const UPDATES_DIR = join(DOCS_DIR, 'updates');

const PORT = Number(process.env.PORT ?? 3000);
const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;
const ANTHROPIC_MODEL = process.env.ANTHROPIC_MODEL || 'claude-haiku-4-5';
const CHAT_ORIGINS = (process.env.ALLOWED_CHAT_ORIGINS || '*')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

const SYSTEM_PROMPT = `You are the Genius Team website assistant on the genius.w3art.io ecosystem site.

## Your role
Help users understand the shared site, the GT/Cortex/Revius split, installation paths, and the intelligence layer accurately.
Be concise, practical, and technically correct.

## Tone
- calm
- precise
- warm
- truthful
- no hype

## Product framing
- Genius Team is the per-repo build framework for vibe coding inside a project.
- Cortex is the transverse control tower for multiple Genius Team repos.
- Revius is the local-first UX review layer that turns feedback into AI-ready tasks.
- The site uses one shared design language across all three product pages.

## Current truth
Genius Team v22.0.0
Cortex v3.2.1 (free beta)
Revius v0.1.0 (free beta)

## Site surfaces
- \`index.html\` — ecosystem landing
- \`genius-team.html\` — Genius Team product page
- \`cortex.html\` — Cortex product page
- \`revius.html\` — Revius product page

## Genius Team install paths
Prerequisite: Claude Code CLI installed and authenticated.

Create a new project:
\`bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/create.sh) MY_PROJECT\`

Add Genius Team to an existing repo:
\`cd MY_PROJECT && bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/add.sh)\`

Upgrade an existing Genius Team repo:
\`cd MY_PROJECT && bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/upgrade.sh)\`

After install:
1. Open Claude Code in the repo
2. Run \`/genius-start\`

## How to answer
- Prefer the ecosystem truth over legacy GT-only framing.
- If the user asks about design, explain that the shared design language is the source of truth.
- If the user asks about Cortex UI, say it is a control tower, not a launcher or a per-repo builder.
- If the user asks about Revius, say it is a review overlay for existing apps, not a builder.
- If you are unsure, say so instead of inventing.
- For advanced details, point users to the GitHub org: https://github.com/w-3-art`;

const app = new Hono();

app.use('*', logger());
app.use(
  '*',
  secureHeaders({
    contentSecurityPolicy: false, // HTML pages have their own needs (inline SVG, etc.)
  })
);

app.get('/api/health', (c) => c.json({ ok: true, service: 'genius-team-site', version: '22.0.0' }));

// ---------------------------------------------------------------------------
// Chat proxy — per-IP rate limiting (in-memory sliding window)
// ---------------------------------------------------------------------------
const CHAT_RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000; // 10 minutes
const CHAT_RATE_LIMIT_MAX_REQUESTS = 20; // per IP per window

/** ip -> array of request timestamps (ms) within the current window */
const chatRateLimitBuckets = new Map();

function getClientIp(c) {
  const forwardedFor = c.req.header('x-forwarded-for');
  if (forwardedFor) {
    const first = forwardedFor.split(',')[0].trim();
    if (first) return first;
  }
  return c.env?.incoming?.socket?.remoteAddress || 'unknown';
}

/** Returns true and records the hit if the request is allowed; false if the IP is over the limit. */
function allowChatRequest(ip) {
  const now = Date.now();
  const windowStart = now - CHAT_RATE_LIMIT_WINDOW_MS;

  let timestamps = chatRateLimitBuckets.get(ip);
  if (!timestamps) {
    timestamps = [];
    chatRateLimitBuckets.set(ip, timestamps);
  }

  // Drop timestamps that have slid out of the window.
  while (timestamps.length > 0 && timestamps[0] <= windowStart) {
    timestamps.shift();
  }

  if (timestamps.length >= CHAT_RATE_LIMIT_MAX_REQUESTS) {
    return false;
  }

  timestamps.push(now);
  return true;
}

// Periodic sweep so buckets for IPs that stop sending requests don't accumulate forever.
setInterval(
  () => {
    const cutoff = Date.now() - CHAT_RATE_LIMIT_WINDOW_MS;
    for (const [ip, timestamps] of chatRateLimitBuckets) {
      while (timestamps.length > 0 && timestamps[0] <= cutoff) {
        timestamps.shift();
      }
      if (timestamps.length === 0) chatRateLimitBuckets.delete(ip);
    }
  },
  CHAT_RATE_LIMIT_WINDOW_MS
).unref();

app.use(
  '/api/chat',
  cors({
    origin: CHAT_ORIGINS.length === 1 && CHAT_ORIGINS[0] === '*' ? '*' : CHAT_ORIGINS,
    allowMethods: ['POST', 'OPTIONS'],
    allowHeaders: ['Content-Type'],
    maxAge: 600,
  })
);

app.post('/api/chat', async (c) => {
  const clientIp = getClientIp(c);
  if (!allowChatRequest(clientIp)) {
    return c.json(
      { error: 'rate limit exceeded, try again later' },
      429,
      { 'Retry-After': String(Math.ceil(CHAT_RATE_LIMIT_WINDOW_MS / 1000)) }
    );
  }

  if (!ANTHROPIC_API_KEY) {
    return c.json({ error: 'chat unavailable: ANTHROPIC_API_KEY not configured' }, 503);
  }

  let body;
  try {
    body = await c.req.json();
  } catch {
    return c.json({ error: 'invalid JSON body' }, 400);
  }

  const { message, history } = body ?? {};
  if (typeof message !== 'string' || message.length === 0) {
    return c.json({ error: 'message required (non-empty string)' }, 400);
  }
  if (message.length > 4000) {
    return c.json({ error: 'message too long (max 4000 chars)' }, 400);
  }

  // History is an array of {role: 'user'|'assistant', content: string}
  const safeHistory = Array.isArray(history)
    ? history
        .filter(
          (m) =>
            m &&
            (m.role === 'user' || m.role === 'assistant') &&
            typeof m.content === 'string' &&
            m.content.length > 0 &&
            m.content.length <= 4000
        )
        .slice(-10)
    : [];

  const messages = [...safeHistory, { role: 'user', content: message }];

  try {
    const upstream = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: ANTHROPIC_MODEL,
        max_tokens: 1024,
        system: SYSTEM_PROMPT,
        messages,
      }),
    });

    if (!upstream.ok) {
      const text = await upstream.text();
      console.error('anthropic api error', upstream.status, text.slice(0, 500));
      return c.json({ error: 'upstream error' }, 502);
    }

    const data = await upstream.json();
    const assistantMessage = data?.content?.[0]?.text ?? '';
    return c.json({ message: assistantMessage, model: ANTHROPIC_MODEL });
  } catch (err) {
    console.error('chat handler error', err);
    return c.json({ error: 'internal error' }, 500);
  }
});

// ---------------------------------------------------------------------------
// Tauri updater endpoint
// /updates/latest.json MUST be served as application/json so Tauri parses it.
// Everything else in /updates/ is binary (DMG, tar.gz, signatures).
// ---------------------------------------------------------------------------
const ALLOWED_UPDATE_EXT = new Set(['.json', '.dmg', '.tar', '.gz', '.sig', '.msi', '.exe', '.AppImage']);

app.get('/updates/*', async (c) => {
  const urlPath = c.req.path; // e.g. /updates/latest.json
  const rel = urlPath.replace(/^\/updates\//, '');

  // Normalize and confine to updates/ directory — block path traversal
  const target = normalize(join(UPDATES_DIR, rel));
  if (!target.startsWith(UPDATES_DIR + '/') && target !== UPDATES_DIR) {
    return c.text('forbidden', 403);
  }

  const ext = extname(target).toLowerCase();
  // ".tar.gz" composite extension → extname gives ".gz"
  const isJson = ext === '.json';
  if (!ALLOWED_UPDATE_EXT.has(ext)) {
    return c.text('not found', 404);
  }

  try {
    const s = await stat(target);
    if (!s.isFile()) return c.text('not found', 404);

    if (isJson) {
      const buf = await readFile(target);
      return new Response(buf, {
        status: 200,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Cache-Control': 'public, max-age=60',
          'Access-Control-Allow-Origin': '*',
        },
      });
    }

    return new Response(createReadStream(target), {
      status: 200,
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Length': String(s.size),
        'Cache-Control': 'public, max-age=3600',
        'Access-Control-Allow-Origin': '*',
      },
    });
  } catch {
    return c.text('not found', 404);
  }
});

// ---------------------------------------------------------------------------
// Static site (docs/)
// ---------------------------------------------------------------------------
app.use(
  '/*',
  serveStatic({
    root: './docs',
  })
);

// Root → docs/index.html explicitly (serveStatic handles it but leave fallback)
app.get('/', serveStatic({ path: './docs/index.html' }));

serve({ fetch: app.fetch, port: PORT }, (info) => {
  console.log(`genius-team-site listening on 0.0.0.0:${info.port}`);
  console.log(`  docs dir: ${DOCS_DIR}`);
  console.log(`  updates : ${UPDATES_DIR}`);
  console.log(`  chat    : ${ANTHROPIC_API_KEY ? 'enabled' : 'DISABLED (no ANTHROPIC_API_KEY)'}`);
});
