// Vercel Edge Function for Genius Team Chat
//
// This is a duplicate deployment target of the same /api/chat proxy served by
// server.js on Railway. Mitigations below are kept aligned with server.js:
//   - identical input limits (message <=4000 chars, history <=10 entries of
//     <=4000 chars each, max_tokens 1024)
//   - CORS restricted via ALLOWED_CHAT_ORIGINS (same env var, same default)
//   - per-IP rate limiting
//
// IMPORTANT (Edge runtime caveat): unlike server.js's single Node process on
// Railway, a Vercel Edge Function can run across many isolated instances/
// regions, each with its own module-scope memory. The in-memory rate limiter
// below is therefore BEST-EFFORT ONLY — it throttles abuse from a single
// edge instance but a distributed attacker can bypass it by fanning out
// across regions. The hard input limits (message/history/max_tokens) are the
// real backstop: they cap the cost of any individual request regardless of
// whether the rate limit was bypassed. Revisit with a shared store (e.g.
// Vercel KV / Upstash Redis) if this endpoint is ever targeted seriously.
export const config = {
  runtime: 'edge',
};

// Env:
//   ANTHROPIC_API_KEY       required
//   ANTHROPIC_MODEL         default 'claude-haiku-4-5'
//   ALLOWED_CHAT_ORIGINS    optional comma-separated CORS allowlist
//                           (default: '*' — matches server.js's default;
//                           set this in Vercel project env for production)
const ALLOWED_ORIGINS = (process.env.ALLOWED_CHAT_ORIGINS || '*')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

function corsHeaders(reqOrigin) {
  const headers = {
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '600',
    Vary: 'Origin',
  };
  if (ALLOWED_ORIGINS.length === 1 && ALLOWED_ORIGINS[0] === '*') {
    headers['Access-Control-Allow-Origin'] = '*';
  } else if (reqOrigin && ALLOWED_ORIGINS.includes(reqOrigin)) {
    headers['Access-Control-Allow-Origin'] = reqOrigin;
  }
  return headers;
}

function jsonResponse(body, status, reqOrigin) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders(reqOrigin),
    },
  });
}

// ---------------------------------------------------------------------------
// Best-effort per-instance rate limiting (see module comment above).
// ---------------------------------------------------------------------------
const CHAT_RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000; // 10 minutes
const CHAT_RATE_LIMIT_MAX_REQUESTS = 20; // per IP per window, per instance

/** ip -> array of request timestamps (ms) within the current window */
const chatRateLimitBuckets = new Map();

function getClientIp(req) {
  const forwardedFor = req.headers.get('x-forwarded-for');
  if (forwardedFor) {
    const first = forwardedFor.split(',')[0].trim();
    if (first) return first;
  }
  return req.headers.get('x-real-ip') || 'unknown';
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

const SYSTEM_PROMPT = `You are the Genius Team website assistant on the genius.w3art.io ecosystem site.

## Your role
Help users understand the shared site, the GT/Cortex split, installation paths, and the intelligence layer accurately.
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
- The site uses one shared design language across the GT pages and the Cortex pages.
- The intelligence layer is separate from project artifacts.

## Current truth
Genius Team v22.0.0

## Site surfaces
- \`index.html\` — ecosystem landing
- \`genius-team.html\` — Genius Team product page
- \`cortex.html\` — Cortex product page

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

## GT v22 contract facts
- Runtime state is centered on \`.genius/state.json\`
- Workflow registry lives in \`.genius/workflows.json\`
- Unified output state lives in \`.genius/outputs/state.json\`
- Session history lives in \`.genius/session-log.jsonl\`
- HTML outputs live in \`.genius/outputs/\`
- Project dashboard hub lives in \`.genius/DASHBOARD.html\`

## Cortex facts
- Cortex is not the per-repo execution framework.
- Cortex works across repos.
- Cortex can scan projects, show status, align repos, and manage portfolio-level behaviors.
- Cortex intelligence concepts are:
  - Behaviors
  - Rules
  - Memory Bits
  - Personas
  - Code Bits
  - Glossary

## Important Cortex commands
- \`cortex init\` — bootstrap the Cortex workspace
- \`cortex scan\` — discover GT repos
- \`cortex status\` — inspect portfolio readiness
- \`cortex upgrade --all\` — align repos to the current GT contract
- \`cortex behaviors\` — manage behaviors
- \`cortex memory\` — cross-project knowledge

## How to answer
- Prefer the ecosystem truth over legacy GT-only framing.
- If the user asks about design, explain that the shared design language is the source of truth.
- If the user asks about Cortex UI, say it is a control tower, not a launcher or a per-repo builder.
- If you are unsure, say so instead of inventing.
- For advanced details, point users to the GitHub repo: https://github.com/w-3-art/genius-team`;


export default async function handler(req) {
  const reqOrigin = req.headers.get('origin');

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders(reqOrigin) });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, reqOrigin);
  }

  const clientIp = getClientIp(req);
  if (!allowChatRequest(clientIp)) {
    return jsonResponse(
      { error: 'rate limit exceeded, try again later' },
      429,
      reqOrigin
    );
  }

  try {
    const { message, history } = await req.json();

    if (typeof message !== 'string' || message.length === 0) {
      return jsonResponse({ error: 'message required (non-empty string)' }, 400, reqOrigin);
    }
    if (message.length > 4000) {
      return jsonResponse({ error: 'message too long (max 4000 chars)' }, 400, reqOrigin);
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

    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': process.env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: process.env.ANTHROPIC_MODEL || 'claude-haiku-4-5',
        max_tokens: 1024,
        system: SYSTEM_PROMPT,
        messages: messages,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('Anthropic API error:', error);
      return jsonResponse({ error: 'Failed to get response' }, 500, reqOrigin);
    }

    const data = await response.json();
    const assistantMessage = data.content[0].text;

    return jsonResponse(
      {
        message: assistantMessage,
        model: process.env.ANTHROPIC_MODEL || 'claude-haiku-4-5',
      },
      200,
      reqOrigin
    );

  } catch (error) {
    console.error('Chat error:', error);
    return jsonResponse({ error: 'Internal server error' }, 500, reqOrigin);
  }
}
