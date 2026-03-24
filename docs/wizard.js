// ═══════════════════════════════════════════════════════════
// Genius Team — Getting Started Wizard (shared component)
// Include this script + call GeniusWizard.init() after DOM ready
// ═══════════════════════════════════════════════════════════

const GeniusWizard = {
  state: { step: 0, project: 'my-app', env: 'cli', engine: 'claude', type: 'new' },

  init() {
    // Inject modal HTML
    const modal = document.createElement('div');
    modal.id = 'gw-overlay';
    modal.className = 'gw-overlay';
    modal.innerHTML = `
      <div class="gw-card">
        <button class="gw-close" onclick="GeniusWizard.close()">&times;</button>
        <div class="gw-progress" id="gwProgress">
          <div class="gw-dot active" data-step="0"></div>
          <div class="gw-line"><div class="gw-line-fill" id="gwLineFill1"></div></div>
          <div class="gw-dot" data-step="1"></div>
          <div class="gw-line"><div class="gw-line-fill" id="gwLineFill2"></div></div>
          <div class="gw-dot" data-step="2"></div>
          <div class="gw-line"><div class="gw-line-fill" id="gwLineFill3"></div></div>
          <div class="gw-dot" data-step="3"></div>
        </div>

        <!-- Step 0: Project name -->
        <div class="gw-step active" id="gwStep0">
          <div class="gw-icon">🚀</div>
          <h3>What's your project called?</h3>
          <p>Pick a name — you can always change it later.</p>
          <input type="text" class="gw-input" id="gwName" value="my-app" placeholder="my-app"
                 oninput="GeniusWizard.state.project=this.value.replace(/[^a-z0-9-]/g,'')">
          <div class="gw-nav"><div></div><button class="gw-btn primary" onclick="GeniusWizard.next()">Next →</button></div>
        </div>

        <!-- Step 1: Environment -->
        <div class="gw-step" id="gwStep1">
          <div class="gw-icon">💻</div>
          <h3>How do you prefer to work?</h3>
          <p>Both work great — pick what feels right.</p>
          <div class="gw-options">
            <button class="gw-opt selected" onclick="GeniusWizard.select(this,'env','cli')">
              <span class="gw-opt-icon">⌨️</span>
              <span class="gw-opt-title">Terminal</span>
              <span class="gw-opt-desc">Type commands</span>
            </button>
            <button class="gw-opt" onclick="GeniusWizard.select(this,'env','ide')">
              <span class="gw-opt-icon">🖥️</span>
              <span class="gw-opt-title">VS Code</span>
              <span class="gw-opt-desc">Visual editor</span>
            </button>
          </div>
          <div class="gw-nav">
            <button class="gw-btn ghost" onclick="GeniusWizard.prev()">← Back</button>
            <button class="gw-btn primary" onclick="GeniusWizard.next()">Next →</button>
          </div>
        </div>

        <!-- Step 2: Engine -->
        <div class="gw-step" id="gwStep2">
          <div class="gw-icon">🤖</div>
          <h3>Which AI engine?</h3>
          <p>Claude is recommended for beginners.</p>
          <div class="gw-options three">
            <button class="gw-opt selected" onclick="GeniusWizard.select(this,'engine','claude')">
              <span class="gw-opt-icon">🟣</span>
              <span class="gw-opt-title">Claude</span>
              <span class="gw-opt-desc">Recommended</span>
            </button>
            <button class="gw-opt" onclick="GeniusWizard.select(this,'engine','codex')">
              <span class="gw-opt-icon">🟢</span>
              <span class="gw-opt-title">Codex</span>
              <span class="gw-opt-desc">OpenAI</span>
            </button>
            <button class="gw-opt" onclick="GeniusWizard.select(this,'engine','dual')">
              <span class="gw-opt-icon">🔀</span>
              <span class="gw-opt-title">Both</span>
              <span class="gw-opt-desc">Dual mode</span>
            </button>
          </div>
          <div class="gw-nav">
            <button class="gw-btn ghost" onclick="GeniusWizard.prev()">← Back</button>
            <button class="gw-btn primary" onclick="GeniusWizard.next()">Next →</button>
          </div>
        </div>

        <!-- Step 3: Result -->
        <div class="gw-step" id="gwStep3">
          <div class="gw-icon">✅</div>
          <h3>You're all set!</h3>
          <p>Copy this command and paste it in your terminal:</p>
          <div class="gw-result" id="gwResult">
            <code id="gwCmd"></code>
            <button class="gw-copy" onclick="GeniusWizard.copy()">📋 Copy</button>
          </div>
          <div class="gw-then">
            <strong>Then run:</strong>
            <code>cd <span id="gwCdName"></span> && claude</code>
            <div class="gw-then-sub">Type <code>/genius-start</code> to begin building!</div>
          </div>
          <div class="gw-nav">
            <button class="gw-btn ghost" onclick="GeniusWizard.prev()">← Back</button>
            <a href="https://github.com/w-3-art/genius-team" target="_blank" class="gw-btn primary">⭐ Star on GitHub</a>
          </div>
        </div>
      </div>
    `;
    document.body.appendChild(modal);

    // Inject styles
    const style = document.createElement('style');
    style.textContent = `
      .gw-overlay { position:fixed; inset:0; background:rgba(0,0,0,.8); backdrop-filter:blur(12px); z-index:9999; display:flex; align-items:center; justify-content:center; padding:1.5rem; opacity:0; pointer-events:none; transition:opacity .3s; }
      .gw-overlay.open { opacity:1; pointer-events:all; }
      .gw-card { background:#161616; border:1px solid rgba(212,165,116,.12); border-radius:24px; padding:2.5rem; max-width:520px; width:100%; position:relative; transform:translateY(20px) scale(.97); transition:transform .3s; font-family:'DM Sans','Inter',system-ui,sans-serif; }
      .gw-overlay.open .gw-card { transform:none; }
      .gw-close { position:absolute; top:1rem; right:1rem; background:rgba(255,255,255,.06); border:none; color:rgba(255,255,255,.5); font-size:1.4rem; width:36px; height:36px; border-radius:50%; cursor:pointer; display:flex; align-items:center; justify-content:center; transition:all .2s; }
      .gw-close:hover { background:rgba(255,255,255,.12); color:#fff; }
      .gw-progress { display:flex; align-items:center; justify-content:center; gap:0; margin-bottom:2rem; }
      .gw-dot { width:10px; height:10px; border-radius:50%; background:rgba(255,255,255,.15); transition:all .3s; }
      .gw-dot.active { background:#D4A574; box-shadow:0 0 10px rgba(212,165,116,.4); }
      .gw-dot.done { background:#22c55e; }
      .gw-line { width:40px; height:2px; background:rgba(255,255,255,.08); margin:0 4px; overflow:hidden; border-radius:1px; }
      .gw-line-fill { height:100%; width:0; background:linear-gradient(90deg,#D4A574,#F5F0EB); transition:width .4s; border-radius:1px; }
      .gw-step { display:none; flex-direction:column; align-items:center; text-align:center; min-height:280px; animation:gwFadeIn .3s ease; }
      .gw-step.active { display:flex; }
      @keyframes gwFadeIn { from { opacity:0; transform:translateX(20px); } to { opacity:1; transform:none; } }
      .gw-icon { font-size:2.5rem; margin-bottom:.75rem; }
      .gw-step h3 { font-size:1.4rem; font-weight:700; margin-bottom:.4rem; color:#fff; }
      .gw-step p { color:rgba(255,255,255,.45); font-size:.9rem; margin-bottom:1.5rem; }
      .gw-input { width:100%; max-width:280px; padding:.9rem 1.2rem; border-radius:12px; border:2px solid rgba(255,255,255,.12); background:rgba(255,255,255,.03); color:#fff; font-family:monospace; font-size:1.1rem; text-align:center; transition:border-color .2s; margin-bottom:1.5rem; }
      .gw-input:focus { outline:none; border-color:#D4A574; }
      .gw-options { display:flex; gap:.75rem; margin-bottom:1.5rem; flex-wrap:wrap; justify-content:center; }
      .gw-options.three { gap:.6rem; }
      .gw-opt { display:flex; flex-direction:column; align-items:center; gap:.3rem; padding:1.1rem 1.4rem; min-width:120px; border-radius:16px; background:rgba(255,255,255,.03); border:2px solid rgba(255,255,255,.08); cursor:pointer; transition:all .25s; color:#fff; }
      .gw-opt:hover { background:rgba(255,255,255,.06); border-color:rgba(255,255,255,.15); transform:translateY(-2px); }
      .gw-opt.selected { background:rgba(212,165,116,.12); border-color:#D4A574; }
      .gw-opt-icon { font-size:1.5rem; }
      .gw-opt-title { font-weight:600; font-size:.9rem; }
      .gw-opt-desc { font-size:.72rem; color:rgba(255,255,255,.4); }
      .gw-nav { display:flex; justify-content:space-between; width:100%; margin-top:auto; padding-top:1rem; }
      .gw-btn { padding:.7rem 1.6rem; border-radius:12px; font-weight:600; font-size:.9rem; cursor:pointer; border:none; transition:all .25s; text-decoration:none; display:inline-block; }
      .gw-btn.primary { background:linear-gradient(135deg,#D4A574,#C4956A); color:#fff; box-shadow:0 4px 15px rgba(212,165,116,.3); }
      .gw-btn.primary:hover { transform:translateY(-2px); box-shadow:0 6px 20px rgba(212,165,116,.4); }
      .gw-btn.ghost { background:rgba(255,255,255,.05); color:rgba(255,255,255,.6); border:1px solid rgba(255,255,255,.1); }
      .gw-btn.ghost:hover { background:rgba(255,255,255,.08); color:#fff; }
      .gw-result { background:rgba(0,0,0,.4); border:1px solid rgba(212,165,116,.2); border-radius:12px; padding:1rem 1.2rem; width:100%; margin-bottom:1rem; display:flex; align-items:center; justify-content:space-between; gap:.75rem; }
      .gw-result code { font-size:.82rem; color:#F5F0EB; word-break:break-all; text-align:left; flex:1; }
      .gw-copy { padding:.4rem .8rem; border-radius:8px; background:rgba(212,165,116,.15); border:1px solid rgba(212,165,116,.2); color:#D4A574; font-size:.78rem; font-weight:600; cursor:pointer; transition:all .2s; white-space:nowrap; }
      .gw-copy:hover { background:rgba(212,165,116,.25); }
      .gw-then { background:rgba(34,197,94,.06); border:1px solid rgba(34,197,94,.15); border-radius:12px; padding:1rem; width:100%; text-align:left; margin-bottom:1rem; }
      .gw-then strong { color:#22c55e; font-size:.85rem; }
      .gw-then code { background:rgba(0,0,0,.3); padding:.15rem .4rem; border-radius:4px; font-size:.82rem; color:rgba(255,255,255,.7); }
      .gw-then-sub { margin-top:.5rem; font-size:.78rem; color:rgba(255,255,255,.4); }
      @media(max-width:640px) { .gw-card { padding:1.5rem; } .gw-opt { min-width:100px; padding:.9rem 1rem; } .gw-result code { font-size:.72rem; } }
    `;
    document.head.appendChild(style);
  },

  open() {
    document.getElementById('gw-overlay').classList.add('open');
    document.body.style.overflow = 'hidden';
  },

  close() {
    document.getElementById('gw-overlay').classList.remove('open');
    document.body.style.overflow = '';
  },

  select(btn, key, value) {
    this.state[key] = value;
    btn.parentElement.querySelectorAll('.gw-opt').forEach(b => b.classList.remove('selected'));
    btn.classList.add('selected');
  },

  next() {
    const curr = document.getElementById(`gwStep${this.state.step}`);
    curr.classList.remove('active');
    this.state.step++;
    if (this.state.step === 3) this.generateResult();
    const next = document.getElementById(`gwStep${this.state.step}`);
    next.classList.add('active');
    this.updateProgress();
  },

  prev() {
    const curr = document.getElementById(`gwStep${this.state.step}`);
    curr.classList.remove('active');
    this.state.step--;
    document.getElementById(`gwStep${this.state.step}`).classList.add('active');
    this.updateProgress();
  },

  updateProgress() {
    const dots = document.querySelectorAll('.gw-dot');
    const fills = [document.getElementById('gwLineFill1'), document.getElementById('gwLineFill2'), document.getElementById('gwLineFill3')];
    dots.forEach((d, i) => {
      d.classList.remove('active', 'done');
      if (i < this.state.step) d.classList.add('done');
      if (i === this.state.step) d.classList.add('active');
    });
    fills.forEach((f, i) => { f.style.width = i < this.state.step ? '100%' : '0'; });
  },

  generateResult() {
    const s = this.state;
    const name = s.project || 'my-app';
    const mode = s.env === 'ide' ? ' --mode ide' : '';
    const engine = s.engine !== 'claude' ? ` --engine ${s.engine}` : '';
    const cmd = `bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/create.sh) ${name}${mode}${engine}`;
    document.getElementById('gwCmd').textContent = cmd;
    document.getElementById('gwCdName').textContent = name;
  },

  copy() {
    const cmd = document.getElementById('gwCmd').textContent;
    navigator.clipboard.writeText(cmd);
    const btn = document.querySelector('.gw-copy');
    btn.textContent = '✓ Copied!';
    btn.style.background = 'rgba(34,197,94,.2)';
    btn.style.borderColor = 'rgba(34,197,94,.3)';
    btn.style.color = '#22c55e';
    setTimeout(() => { btn.textContent = '📋 Copy'; btn.style.cssText = ''; }, 2000);
  }
};
