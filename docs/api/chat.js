// Vercel Serverless Function for Genius Team Chat
export const config = {
  runtime: 'edge',
};

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
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const { message, history = [] } = await req.json();

    if (!message) {
      return new Response(JSON.stringify({ error: 'Message required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Build messages array
    const messages = [
      ...history.slice(-10), // Keep last 10 messages for context
      { role: 'user', content: message }
    ];

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
      return new Response(JSON.stringify({ error: 'Failed to get response' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const data = await response.json();
    const assistantMessage = data.content[0].text;

    return new Response(JSON.stringify({ 
      message: assistantMessage,
      model: process.env.ANTHROPIC_MODEL || 'claude-haiku-4-5'
    }), {
      status: 200,
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });

  } catch (error) {
    console.error('Chat error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
