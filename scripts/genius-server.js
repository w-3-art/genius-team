#!/usr/bin/env node
/**
 * Genius Team Playground Server
 * Serves .genius/playgrounds/ locally and optionally via tunnel
 * Usage: node genius-server.js [--port 3333] [--dir .genius/playgrounds] [--tunnel]
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { execSync, spawn } = require('child_process');
const os = require('os');

// ─── CLI ARGS ────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
let port = 3333;
let serveDir = null;
let enableTunnel = false;

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--port' && args[i + 1]) port = parseInt(args[++i]);
  if (args[i] === '--dir' && args[i + 1]) serveDir = args[++i];
  if (args[i] === '--tunnel') enableTunnel = true;
  if (args[i] === '--help') {
    console.log(`
Genius Team Playground Server

Usage:
  node genius-server.js [options]

Options:
  --port <n>     Port to listen on (default: 3333)
  --dir <path>   Directory to serve (default: .genius/playgrounds)
  --tunnel       Auto-start a local tunnel for remote access
  --help         Show this help

Remote access (auto-detected in order):
  1. localtunnel (lt)   — npx localtunnel --port PORT
  2. cloudflared        — cloudflared tunnel --url http://localhost:PORT
  3. ngrok              — ngrok http PORT
    `);
    process.exit(0);
  }
}

// ─── PATHS ───────────────────────────────────────────────────────────────────
const cwd = process.cwd();
if (!serveDir) {
  serveDir = path.join(cwd, '.genius', 'playgrounds');
}
serveDir = path.resolve(serveDir);

const memoryDir = path.join(cwd, '.genius', 'memory');
const stateFile = path.join(memoryDir, 'server.json');

// ─── MIME TYPES ──────────────────────────────────────────────────────────────
const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

// ─── STATE ────────────────────────────────────────────────────────────────────
function writeState(remoteUrl) {
  try {
    if (!fs.existsSync(memoryDir)) fs.mkdirSync(memoryDir, { recursive: true });
    fs.writeFileSync(stateFile, JSON.stringify({
      status: 'running',
      localUrl: `http://localhost:${port}`,
      remoteUrl: remoteUrl || null,
      startedAt: new Date().toISOString(),
      playgroundsDir: serveDir,
    }, null, 2));
  } catch (_) {}
}

function clearState() {
  try {
    fs.writeFileSync(stateFile, JSON.stringify({ status: 'stopped', stoppedAt: new Date().toISOString() }, null, 2));
  } catch (_) {}
}

// ─── TUNNEL DETECTION ────────────────────────────────────────────────────────
function detectTunnel() {
  const tools = [
    { name: 'lt', check: 'which lt', start: (p) => ['npx', ['localtunnel', '--port', String(p)]] },
    { name: 'cloudflared', check: 'which cloudflared', start: (p) => ['cloudflared', ['tunnel', '--url', `http://localhost:${p}`]] },
    { name: 'ngrok', check: 'which ngrok', start: (p) => ['ngrok', ['http', String(p)]] },
  ];
  for (const t of tools) {
    try { execSync(t.check, { stdio: 'ignore' }); return t; } catch (_) {}
  }
  return null;
}

// ─── HTTP SERVER ─────────────────────────────────────────────────────────────
const server = http.createServer((req, res) => {
  // Strip query string
  let urlPath = req.url.split('?')[0];

  // Sanitize path traversal
  const safePath = path.normalize(urlPath).replace(/^(\.\.[/\\])+/, '');
  let filePath = path.join(serveDir, safePath);

  // Directory → try index.html or list
  if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
    const indexFile = path.join(filePath, 'index.html');
    if (fs.existsSync(indexFile)) {
      filePath = indexFile;
    } else {
      // List directory
      try {
        const files = fs.readdirSync(filePath);
        const items = files.map(f => {
          const isDir = fs.statSync(path.join(filePath, f)).isDirectory();
          return `<li><a href="${path.join(urlPath, f)}">${f}${isDir ? '/' : ''}</a></li>`;
        }).join('\n');
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(`<!DOCTYPE html><html><body><h2>${urlPath}</h2><ul>${items}</ul></body></html>`);
        return;
      } catch (e) {
        res.writeHead(500); res.end('Server error'); return;
      }
    }
  }

  if (!fs.existsSync(filePath)) {
    res.writeHead(404, { 'Content-Type': 'text/html' });
    res.end(`<html><body><h2>404 — Not found</h2><p>${urlPath}</p><p><a href="/">← Back to dashboard</a></p></body></html>`);
    return;
  }

  const ext = path.extname(filePath).toLowerCase();
  const mime = MIME[ext] || 'application/octet-stream';

  try {
    const content = fs.readFileSync(filePath);
    res.writeHead(200, { 'Content-Type': mime });
    res.end(content);
  } catch (e) {
    res.writeHead(500); res.end('Server error');
  }
});

// ─── STARTUP ─────────────────────────────────────────────────────────────────
server.listen(port, () => {
  const line = '─'.repeat(40);
  console.log(`\n🧠 Genius Team Playground Server`);
  console.log(line);

  // Check if serve dir exists
  if (!fs.existsSync(serveDir)) {
    console.log(`\n⚠️  Playgrounds directory not found: ${serveDir}`);
    console.log(`   Run genius-team setup first, then re-launch this server.`);
    console.log(`   (Default path: .genius/playgrounds in your project root)\n`);
  }

  // Check if dashboard exists
  const dashFile = path.join(serveDir, 'genius-dashboard.html');
  if (fs.existsSync(serveDir) && !fs.existsSync(dashFile)) {
    console.log(`⚠️  genius-dashboard.html not found — run genius-team to generate it.\n`);
  }

  console.log(`\n🌐 Local:   http://localhost:${port}`);
  console.log(`📁 Serving: ${serveDir}`);

  writeState(null);

  if (enableTunnel) {
    const tool = detectTunnel();
    if (tool) {
      console.log(`\n🔗 Starting tunnel via ${tool.name}...`);
      const [cmd, cmdArgs] = tool.start(port);
      const proc = spawn(cmd, cmdArgs, { stdio: ['ignore', 'pipe', 'pipe'] });
      proc.stdout.on('data', (d) => {
        const text = d.toString();
        const urlMatch = text.match(/https?:\/\/[^\s]+/);
        if (urlMatch) {
          const remoteUrl = urlMatch[0].trim();
          writeState(remoteUrl);
          console.log(`🌍 Remote:  ${remoteUrl}`);
        }
      });
      proc.stderr.on('data', (d) => {
        const text = d.toString();
        const urlMatch = text.match(/https?:\/\/[^\s]+/);
        if (urlMatch) {
          const remoteUrl = urlMatch[0].trim();
          writeState(remoteUrl);
          console.log(`🌍 Remote:  ${remoteUrl}`);
        }
      });
      proc.on('exit', () => console.log('\n⚠️  Tunnel process exited.'));
    } else {
      console.log(`\n⚠️  No tunnel tool found. Install localtunnel: npm i -g localtunnel`);
      console.log(`   Then re-run with: node genius-server.js --tunnel`);
    }
  } else {
    console.log(`\n💡 Remote access: run with --tunnel flag`);
    console.log(`   (requires: localtunnel, cloudflared, or ngrok)`);
  }

  console.log(`\nPress Ctrl+C to stop\n`);
});

server.on('error', (e) => {
  if (e.code === 'EADDRINUSE') {
    console.error(`\n❌ Port ${port} is already in use.`);
    console.error(`   Try: node genius-server.js --port ${port + 1}\n`);
  } else {
    console.error(`\n❌ Server error: ${e.message}\n`);
  }
  process.exit(1);
});

// ─── GRACEFUL SHUTDOWN ───────────────────────────────────────────────────────
['SIGINT', 'SIGTERM'].forEach(sig => {
  process.on(sig, () => {
    console.log('\n\n🛑 Stopping server...');
    clearState();
    server.close(() => {
      console.log('✅ Server stopped.\n');
      process.exit(0);
    });
  });
});
