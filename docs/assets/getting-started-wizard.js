/**
 * Genius Team — Getting Started Wizard (v22+)
 *
 * 4 steps max: Intent → (Name) → Engine → Result.
 * Output: the exact one-liner for the user's case.
 *   - New project     → bash <(curl …/scripts/create.sh) NAME [flags]
 *   - Existing repo   → cd repo && bash <(curl …/scripts/add.sh) [flags]
 *   - Upgrade         → cd repo && bash <(curl …/scripts/upgrade.sh) [--force]
 *
 * Reads language from localStorage['genius-lang'] (same as the rest of the site).
 * Self-contained: no dependency on ecosystem.js. Drop-in script + `GTWizard.open()`.
 */
(() => {
  const REPO_RAW = 'https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts';

  const I18N = {
    en: {
      // progress
      badge: 'Getting started',
      // step 1
      s1_title: 'What do you want to do?',
      s1_desc: 'Pick the closest match — you can change later.',
      s1_new_title: 'Start a new project',
      s1_new_desc: 'Empty directory. GT bootstraps everything.',
      s1_add_title: 'Add GT to an existing project',
      s1_add_desc: 'You already have code. GT layers on top.',
      s1_up_title: 'Update an existing GT install',
      s1_up_desc: 'Pull the latest framework into a GT repo.',
      // step 2 (name)
      s2_title: 'Name your project',
      s2_desc: 'Directory name — letters, numbers, dashes.',
      s2_placeholder: 'my-app',
      // step 3 (engine)
      s3_title: 'Which AI engine?',
      s3_desc: 'You can always switch later.',
      s3_claude_title: 'Claude',
      s3_claude_desc: 'Recommended',
      s3_codex_title: 'Codex',
      s3_codex_desc: 'OpenAI',
      s3_dual_title: 'Both',
      s3_dual_desc: 'Dual engine',
      // step 4 (result)
      s4_title_new: "You're all set!",
      s4_title_add: 'Run this inside your project',
      s4_title_up: 'Run this inside your GT project',
      s4_desc: 'Copy the command and paste it in your terminal.',
      s4_then: 'Then:',
      s4_then_new: 'cd {name} && claude',
      s4_then_add: 'claude',
      s4_then_up: 'Restart Claude Code, then run /genius-start',
      s4_then_sub_new: 'Type /genius-start to begin building.',
      s4_then_sub_add: 'Type /genius-start — GT picks up your existing code.',
      s4_then_sub_up: 'Hooks and skills reload; your CLAUDE.md is never touched.',
      // buttons
      next: 'Next →',
      back: '← Back',
      copy: 'Copy',
      copied: '✓ Copied',
      close: 'Close',
      github: '⭐ Star on GitHub',
      open_button: 'Get started in 3 steps',
      // advanced
      adv_toggle: 'Advanced',
      adv_branch_label: 'Branch (optional)',
      adv_branch_help: 'Install from a feature branch (e.g. for beta testing).',
      adv_force_label: 'Force full re-sync (use only if upgrade from same version)',
    },
    fr: {
      badge: 'Démarrer',
      s1_title: 'Que veux-tu faire ?',
      s1_desc: 'Choisis le cas le plus proche — tu pourras changer plus tard.',
      s1_new_title: 'Démarrer un nouveau projet',
      s1_new_desc: 'Dossier vide. GT bootstrap tout.',
      s1_add_title: 'Ajouter GT à un projet existant',
      s1_add_desc: 'Tu as déjà du code. GT se superpose.',
      s1_up_title: 'Mettre à jour une install GT',
      s1_up_desc: 'Récupère la dernière version du framework.',
      s2_title: 'Nom du projet',
      s2_desc: 'Nom du dossier — lettres, chiffres, tirets.',
      s2_placeholder: 'mon-app',
      s3_title: 'Quel moteur IA ?',
      s3_desc: 'Tu peux changer à tout moment.',
      s3_claude_title: 'Claude',
      s3_claude_desc: 'Recommandé',
      s3_codex_title: 'Codex',
      s3_codex_desc: 'OpenAI',
      s3_dual_title: 'Les deux',
      s3_dual_desc: 'Dual engine',
      s4_title_new: 'Tout est prêt !',
      s4_title_add: 'Lance ceci dans ton projet',
      s4_title_up: 'Lance ceci dans ton projet GT',
      s4_desc: 'Copie la commande et colle-la dans ton terminal.',
      s4_then: 'Ensuite :',
      s4_then_new: 'cd {name} && claude',
      s4_then_add: 'claude',
      s4_then_up: 'Redémarre Claude Code, puis /genius-start',
      s4_then_sub_new: 'Tape /genius-start pour commencer à construire.',
      s4_then_sub_add: 'Tape /genius-start — GT reconnaît ton code existant.',
      s4_then_sub_up: 'Hooks et skills rechargés ; ton CLAUDE.md n\u2019est jamais touché.',
      next: 'Suivant →',
      back: '← Retour',
      copy: 'Copier',
      copied: '✓ Copié',
      close: 'Fermer',
      github: '⭐ Star sur GitHub',
      open_button: 'Démarrer en 3 étapes',
      adv_toggle: 'Avancé',
      adv_branch_label: 'Branche (optionnel)',
      adv_branch_help: 'Installer depuis une branche (ex: beta test).',
      adv_force_label: 'Re-sync complet (upgrade depuis la même version)',
    },
  };

  function currentLang() {
    try {
      return localStorage.getItem('genius-lang') === 'fr' ? 'fr' : 'en';
    } catch {
      return 'en';
    }
  }
  function t(key) {
    const dict = I18N[currentLang()] || I18N.en;
    return dict[key] ?? I18N.en[key] ?? key;
  }

  const state = {
    step: 1,
    intent: null, // 'new' | 'add' | 'upgrade'
    name: 'my-app',
    engine: 'claude',
    branch: '',
    force: false,
  };

  let rootEl = null;

  function html() {
    return `
      <div class="gtw-card" role="dialog" aria-modal="true" aria-labelledby="gtwTitle">
        <button class="gtw-close" type="button" aria-label="${t('close')}" data-gtw-close>×</button>
        <div class="gtw-badge">${t('badge')}</div>
        <div class="gtw-progress" aria-hidden="true">
          <span class="gtw-dot" data-step="1"></span>
          <span class="gtw-line"><span class="gtw-line-fill" data-fill="1"></span></span>
          <span class="gtw-dot" data-step="2"></span>
          <span class="gtw-line"><span class="gtw-line-fill" data-fill="2"></span></span>
          <span class="gtw-dot" data-step="3"></span>
          <span class="gtw-line"><span class="gtw-line-fill" data-fill="3"></span></span>
          <span class="gtw-dot" data-step="4"></span>
        </div>

        <!-- Step 1 — Intent -->
        <section class="gtw-step" data-step="1">
          <h3 id="gtwTitle" class="gtw-h">${t('s1_title')}</h3>
          <p class="gtw-sub">${t('s1_desc')}</p>
          <div class="gtw-cards">
            <button type="button" class="gtw-opt" data-intent="new">
              <span class="gtw-opt-icon" aria-hidden="true">🚀</span>
              <span class="gtw-opt-title">${t('s1_new_title')}</span>
              <span class="gtw-opt-desc">${t('s1_new_desc')}</span>
            </button>
            <button type="button" class="gtw-opt" data-intent="add">
              <span class="gtw-opt-icon" aria-hidden="true">➕</span>
              <span class="gtw-opt-title">${t('s1_add_title')}</span>
              <span class="gtw-opt-desc">${t('s1_add_desc')}</span>
            </button>
            <button type="button" class="gtw-opt" data-intent="upgrade">
              <span class="gtw-opt-icon" aria-hidden="true">⬆️</span>
              <span class="gtw-opt-title">${t('s1_up_title')}</span>
              <span class="gtw-opt-desc">${t('s1_up_desc')}</span>
            </button>
          </div>
        </section>

        <!-- Step 2 — Name (only for intent=new) -->
        <section class="gtw-step" data-step="2">
          <h3 class="gtw-h">${t('s2_title')}</h3>
          <p class="gtw-sub">${t('s2_desc')}</p>
          <input class="gtw-input" type="text" value="${state.name}" placeholder="${t('s2_placeholder')}"
                 inputmode="text" autocomplete="off" spellcheck="false"
                 data-gtw-name aria-label="${t('s2_title')}">
          <div class="gtw-nav">
            <button class="gtw-btn gtw-ghost" type="button" data-gtw-prev>${t('back')}</button>
            <button class="gtw-btn gtw-primary" type="button" data-gtw-next>${t('next')}</button>
          </div>
        </section>

        <!-- Step 3 — Engine -->
        <section class="gtw-step" data-step="3">
          <h3 class="gtw-h">${t('s3_title')}</h3>
          <p class="gtw-sub">${t('s3_desc')}</p>
          <div class="gtw-cards gtw-cards--row">
            <button type="button" class="gtw-opt" data-engine="claude" aria-pressed="true">
              <span class="gtw-opt-icon" aria-hidden="true">🟣</span>
              <span class="gtw-opt-title">${t('s3_claude_title')}</span>
              <span class="gtw-opt-desc">${t('s3_claude_desc')}</span>
            </button>
            <button type="button" class="gtw-opt" data-engine="codex" aria-pressed="false">
              <span class="gtw-opt-icon" aria-hidden="true">🟢</span>
              <span class="gtw-opt-title">${t('s3_codex_title')}</span>
              <span class="gtw-opt-desc">${t('s3_codex_desc')}</span>
            </button>
            <button type="button" class="gtw-opt" data-engine="dual" aria-pressed="false">
              <span class="gtw-opt-icon" aria-hidden="true">🔀</span>
              <span class="gtw-opt-title">${t('s3_dual_title')}</span>
              <span class="gtw-opt-desc">${t('s3_dual_desc')}</span>
            </button>
          </div>
          <details class="gtw-adv">
            <summary>${t('adv_toggle')}</summary>
            <label class="gtw-label">
              <span>${t('adv_branch_label')}</span>
              <input class="gtw-input gtw-input--sm" type="text" placeholder="main"
                     data-gtw-branch value="${state.branch}">
            </label>
            <small class="gtw-help">${t('adv_branch_help')}</small>
            <label class="gtw-label gtw-label--inline" data-gtw-force-wrap hidden>
              <input type="checkbox" data-gtw-force>
              <span>${t('adv_force_label')}</span>
            </label>
          </details>
          <div class="gtw-nav">
            <button class="gtw-btn gtw-ghost" type="button" data-gtw-prev>${t('back')}</button>
            <button class="gtw-btn gtw-primary" type="button" data-gtw-next>${t('next')}</button>
          </div>
        </section>

        <!-- Step 4 — Result -->
        <section class="gtw-step" data-step="4">
          <h3 class="gtw-h" data-gtw-result-title></h3>
          <p class="gtw-sub">${t('s4_desc')}</p>
          <div class="gtw-code">
            <code data-gtw-cmd></code>
            <button class="gtw-copy" type="button" data-gtw-copy>${t('copy')}</button>
          </div>
          <div class="gtw-then">
            <strong>${t('s4_then')}</strong>
            <code data-gtw-then></code>
            <div class="gtw-then-sub" data-gtw-then-sub></div>
          </div>
          <div class="gtw-nav">
            <button class="gtw-btn gtw-ghost" type="button" data-gtw-prev>${t('back')}</button>
            <a class="gtw-btn gtw-primary" href="https://github.com/w-3-art/genius-team" target="_blank" rel="noreferrer">${t('github')}</a>
          </div>
        </section>
      </div>
    `;
  }

  function styles() {
    return `
      .gtw-overlay { position:fixed; inset:0; background:rgba(0,0,0,.78); backdrop-filter:blur(14px); -webkit-backdrop-filter:blur(14px); z-index:10050; display:none; align-items:center; justify-content:center; padding:1.5rem; opacity:0; transition:opacity .25s; }
      .gtw-overlay.is-open { display:flex; opacity:1; }
      .gtw-card { background:#161616; border:1px solid rgba(212,165,116,.14); border-radius:24px; padding:2.2rem 2rem 1.8rem; max-width:560px; width:100%; position:relative; transform:translateY(14px) scale(.98); transition:transform .25s var(--ease-out, cubic-bezier(.22,1,.36,1)); font-family:'DM Sans','Inter',system-ui,sans-serif; color:#E8E4DF; box-shadow:0 30px 80px rgba(0,0,0,.6); max-height:90vh; overflow-y:auto; }
      .gtw-overlay.is-open .gtw-card { transform:none; }
      .gtw-close { position:absolute; top:1rem; right:1rem; width:34px; height:34px; border-radius:50%; border:none; background:rgba(255,255,255,.06); color:rgba(255,255,255,.6); font-size:1.3rem; line-height:1; cursor:pointer; transition:background .2s,color .2s; }
      .gtw-close:hover { background:rgba(255,255,255,.12); color:#fff; }
      .gtw-badge { display:inline-block; font-size:.6rem; letter-spacing:.14em; text-transform:uppercase; font-weight:700; color:#D4A574; padding:.3rem .7rem; border:1px solid rgba(212,165,116,.25); border-radius:999px; margin-bottom:1rem; }
      .gtw-progress { display:flex; align-items:center; justify-content:center; gap:0; margin-bottom:1.6rem; }
      .gtw-dot { width:9px; height:9px; border-radius:50%; background:rgba(255,255,255,.15); transition:background .3s, box-shadow .3s; }
      .gtw-dot.is-active { background:#D4A574; box-shadow:0 0 10px rgba(212,165,116,.4); }
      .gtw-dot.is-done { background:#22c55e; }
      .gtw-line { width:38px; height:2px; background:rgba(255,255,255,.1); margin:0 4px; border-radius:1px; overflow:hidden; }
      .gtw-line-fill { display:block; height:100%; width:0; background:linear-gradient(90deg,#D4A574,#F5F0EB); transition:width .35s; }
      .gtw-step { display:none; flex-direction:column; animation:gtwFade .25s ease; }
      .gtw-step.is-active { display:flex; }
      @keyframes gtwFade { from { opacity:0; transform:translateX(14px); } to { opacity:1; transform:none; } }
      .gtw-h { font-size:1.35rem; font-weight:700; margin:0 0 .35rem; color:#fff; }
      .gtw-sub { color:rgba(255,255,255,.5); font-size:.9rem; margin:0 0 1.4rem; }
      .gtw-cards { display:grid; grid-template-columns:1fr; gap:.6rem; margin-bottom:1rem; }
      .gtw-cards--row { grid-template-columns:repeat(3,1fr); gap:.5rem; }
      .gtw-opt { display:flex; flex-direction:column; align-items:flex-start; gap:.25rem; padding:1rem 1.1rem; border-radius:14px; background:rgba(255,255,255,.03); border:2px solid rgba(255,255,255,.08); cursor:pointer; transition:all .2s; color:#fff; text-align:left; font-family:inherit; }
      .gtw-cards--row .gtw-opt { align-items:center; text-align:center; padding:.9rem .7rem; }
      .gtw-opt:hover { background:rgba(255,255,255,.06); border-color:rgba(212,165,116,.25); transform:translateY(-1px); }
      .gtw-opt.is-selected { background:rgba(212,165,116,.12); border-color:#D4A574; }
      .gtw-opt-icon { font-size:1.35rem; }
      .gtw-opt-title { font-weight:700; font-size:.92rem; }
      .gtw-opt-desc { font-size:.74rem; color:rgba(255,255,255,.45); }
      .gtw-input { width:100%; padding:.85rem 1.1rem; border-radius:12px; border:2px solid rgba(255,255,255,.12); background:rgba(255,255,255,.03); color:#fff; font-family:'DM Mono','Fira Code',monospace; font-size:1rem; transition:border-color .2s; margin-bottom:1rem; }
      .gtw-input:focus { outline:none; border-color:#D4A574; }
      .gtw-input--sm { font-size:.88rem; padding:.6rem .8rem; margin:0; }
      .gtw-adv { margin:.6rem 0 1rem; border-top:1px dashed rgba(255,255,255,.08); padding-top:.8rem; }
      .gtw-adv > summary { cursor:pointer; font-size:.78rem; color:rgba(255,255,255,.55); letter-spacing:.08em; text-transform:uppercase; list-style:none; }
      .gtw-adv > summary::-webkit-details-marker { display:none; }
      .gtw-adv[open] > summary { color:#D4A574; }
      .gtw-label { display:flex; flex-direction:column; gap:.35rem; margin-top:.7rem; font-size:.78rem; color:rgba(255,255,255,.6); }
      .gtw-label--inline { flex-direction:row; align-items:center; gap:.55rem; }
      .gtw-label--inline input { accent-color:#D4A574; }
      .gtw-help { display:block; color:rgba(255,255,255,.38); font-size:.72rem; margin-top:.3rem; }
      .gtw-nav { display:flex; justify-content:space-between; gap:.6rem; margin-top:auto; padding-top:1rem; }
      .gtw-btn { padding:.7rem 1.4rem; border-radius:12px; font-weight:700; font-size:.88rem; cursor:pointer; border:none; transition:transform .2s, box-shadow .2s, background .2s, color .2s; text-decoration:none; display:inline-flex; align-items:center; justify-content:center; font-family:inherit; }
      .gtw-primary { background:linear-gradient(135deg,#D4A574,#C4956A); color:#111; box-shadow:0 4px 14px rgba(212,165,116,.28); }
      .gtw-primary:hover { transform:translateY(-1px); box-shadow:0 6px 18px rgba(212,165,116,.4); }
      .gtw-ghost { background:rgba(255,255,255,.05); color:rgba(255,255,255,.62); border:1px solid rgba(255,255,255,.1); }
      .gtw-ghost:hover { background:rgba(255,255,255,.09); color:#fff; }
      .gtw-code { background:rgba(0,0,0,.45); border:1px solid rgba(212,165,116,.2); border-radius:12px; padding:.9rem 1rem; width:100%; margin-bottom:1rem; display:flex; align-items:center; gap:.75rem; overflow:hidden; }
      .gtw-code code { flex:1; min-width:0; font-family:'DM Mono','Fira Code',monospace; font-size:.82rem; color:#F5F0EB; white-space:nowrap; overflow-x:auto; overflow-y:hidden; padding-bottom:2px; -ms-overflow-style:none; scrollbar-width:thin; scrollbar-color:rgba(212,165,116,.4) transparent; }
      .gtw-code code::-webkit-scrollbar { height:4px; }
      .gtw-code code::-webkit-scrollbar-thumb { background:rgba(212,165,116,.4); border-radius:2px; }
      .gtw-copy { flex-shrink:0; padding:.45rem .9rem; border-radius:8px; background:rgba(212,165,116,.15); border:1px solid rgba(212,165,116,.3); color:#D4A574; font-size:.76rem; font-weight:700; cursor:pointer; transition:background .2s,color .2s; font-family:inherit; }
      .gtw-copy:hover { background:rgba(212,165,116,.25); }
      .gtw-copy.is-copied { background:rgba(34,197,94,.18); border-color:rgba(34,197,94,.35); color:#22c55e; }
      .gtw-then { background:rgba(34,197,94,.06); border:1px solid rgba(34,197,94,.15); border-radius:12px; padding:.9rem 1rem; margin-bottom:1rem; }
      .gtw-then strong { display:block; color:#22c55e; font-size:.78rem; letter-spacing:.08em; text-transform:uppercase; margin-bottom:.4rem; }
      .gtw-then code { background:rgba(0,0,0,.35); padding:.2rem .5rem; border-radius:6px; font-size:.82rem; color:rgba(255,255,255,.8); font-family:'DM Mono','Fira Code',monospace; }
      .gtw-then-sub { margin-top:.5rem; font-size:.76rem; color:rgba(255,255,255,.45); }
      @media(max-width:620px) {
        .gtw-card { padding:1.6rem 1.2rem 1.4rem; max-height:94vh; }
        .gtw-cards--row { grid-template-columns:1fr; }
        .gtw-opt-title { font-size:.86rem; }
      }
    `;
  }

  function render() {
    if (rootEl) return;
    const overlay = document.createElement('div');
    overlay.className = 'gtw-overlay';
    overlay.setAttribute('aria-hidden', 'true');
    overlay.innerHTML = html();
    document.body.appendChild(overlay);
    rootEl = overlay;

    if (!document.getElementById('gtw-styles')) {
      const style = document.createElement('style');
      style.id = 'gtw-styles';
      style.textContent = styles();
      document.head.appendChild(style);
    }

    // Click outside to close
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) close();
    });

    // Events
    overlay.addEventListener('click', (e) => {
      const t = e.target.closest('[data-gtw-close]');
      if (t) close();
    });

    // Step 1 — intent
    overlay.querySelectorAll('[data-intent]').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.intent = btn.dataset.intent;
        // upgrade and add have no name step; jump over step 2
        goTo(state.intent === 'new' ? 2 : 3);
      });
    });

    // Step 2 — name
    const nameInput = overlay.querySelector('[data-gtw-name]');
    nameInput.addEventListener('input', () => {
      state.name = nameInput.value.replace(/[^a-zA-Z0-9._-]/g, '').slice(0, 60) || 'my-app';
      nameInput.value = state.name;
    });

    // Step 3 — engine
    overlay.querySelectorAll('[data-engine]').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.engine = btn.dataset.engine;
        overlay.querySelectorAll('[data-engine]').forEach((b) => {
          b.classList.toggle('is-selected', b === btn);
          b.setAttribute('aria-pressed', b === btn ? 'true' : 'false');
        });
      });
    });
    overlay.querySelector('[data-engine="claude"]').classList.add('is-selected');

    // Advanced
    const branchInput = overlay.querySelector('[data-gtw-branch]');
    branchInput.addEventListener('input', () => { state.branch = branchInput.value.trim(); });
    const forceCb = overlay.querySelector('[data-gtw-force]');
    forceCb.addEventListener('change', () => { state.force = forceCb.checked; });

    // Nav
    overlay.querySelectorAll('[data-gtw-next]').forEach((btn) => btn.addEventListener('click', () => {
      if (state.step === 2) goTo(3);
      else if (state.step === 3) goTo(4);
    }));
    overlay.querySelectorAll('[data-gtw-prev]').forEach((btn) => btn.addEventListener('click', () => {
      if (state.step === 4) goTo(3);
      else if (state.step === 3) goTo(state.intent === 'new' ? 2 : 1);
      else if (state.step === 2) goTo(1);
    }));

    // Copy
    overlay.querySelector('[data-gtw-copy]').addEventListener('click', () => {
      const cmd = overlay.querySelector('[data-gtw-cmd]').textContent;
      navigator.clipboard.writeText(cmd).then(() => {
        const btn = overlay.querySelector('[data-gtw-copy]');
        btn.textContent = t('copied');
        btn.classList.add('is-copied');
        setTimeout(() => {
          btn.textContent = t('copy');
          btn.classList.remove('is-copied');
        }, 1800);
      });
    });

    // ESC closes
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && rootEl?.classList.contains('is-open')) close();
    });
  }

  function goTo(step) {
    state.step = step;
    // Show force checkbox only for upgrade
    const forceWrap = rootEl.querySelector('[data-gtw-force-wrap]');
    if (forceWrap) forceWrap.hidden = state.intent !== 'upgrade';

    // Switch active section
    rootEl.querySelectorAll('.gtw-step').forEach((s) => {
      s.classList.toggle('is-active', Number(s.dataset.step) === step);
    });

    // Update progress
    rootEl.querySelectorAll('.gtw-dot').forEach((d) => {
      const n = Number(d.dataset.step);
      d.classList.toggle('is-active', n === step);
      d.classList.toggle('is-done', n < step);
    });
    rootEl.querySelectorAll('.gtw-line-fill').forEach((f) => {
      const n = Number(f.dataset.fill);
      f.style.width = n < step ? '100%' : '0';
    });

    if (step === 4) renderResult();
  }

  function renderResult() {
    const branchFlag = state.branch ? ` --branch=${shellEscape(state.branch)}` : '';
    const branchPath = state.branch || 'main';
    const engineFlag = state.engine !== 'claude' ? ` --engine=${state.engine}` : '';

    let cmd = '';
    let then = '';
    let thenSub = '';
    let title = '';

    if (state.intent === 'new') {
      const name = state.name || 'my-app';
      cmd = `bash <(curl -fsSL ${REPO_RAW.replace('/main/', `/${branchPath}/`)}/create.sh) ${name}${engineFlag}${branchFlag}`;
      then = t('s4_then_new').replace('{name}', name);
      thenSub = t('s4_then_sub_new');
      title = t('s4_title_new');
    } else if (state.intent === 'add') {
      cmd = `bash <(curl -fsSL ${REPO_RAW.replace('/main/', `/${branchPath}/`)}/add.sh)${engineFlag}${branchFlag}`;
      then = t('s4_then_add');
      thenSub = t('s4_then_sub_add');
      title = t('s4_title_add');
    } else {
      // upgrade
      const forceFlag = state.force ? ' --force' : '';
      cmd = `bash <(curl -fsSL ${REPO_RAW.replace('/main/', `/${branchPath}/`)}/upgrade.sh)${branchFlag}${forceFlag}`;
      then = t('s4_then_up');
      thenSub = t('s4_then_sub_up');
      title = t('s4_title_up');
    }

    rootEl.querySelector('[data-gtw-result-title]').textContent = title;
    rootEl.querySelector('[data-gtw-cmd]').textContent = cmd;
    rootEl.querySelector('[data-gtw-then]').textContent = then;
    rootEl.querySelector('[data-gtw-then-sub]').textContent = thenSub;
  }

  function shellEscape(s) {
    // Very conservative: only allow safe chars for branch names.
    return String(s).replace(/[^a-zA-Z0-9._/-]/g, '');
  }

  function open() {
    // Reset
    state.step = 1;
    state.intent = null;
    state.engine = 'claude';
    state.force = false;
    render();
    rootEl.classList.add('is-open');
    rootEl.setAttribute('aria-hidden', 'false');
    document.body.style.overflow = 'hidden';
    // Refresh copy for selected language in case user toggled after first open
    rootEl.querySelector('[data-gtw-copy]').textContent = t('copy');
  }

  function close() {
    if (!rootEl) return;
    rootEl.classList.remove('is-open');
    rootEl.setAttribute('aria-hidden', 'true');
    document.body.style.overflow = '';
  }

  // Expose
  window.GTWizard = { open, close };

  // Wire up any [data-gtw-open] button on the page
  document.addEventListener('click', (e) => {
    const trigger = e.target.closest('[data-gtw-open]');
    if (trigger) {
      e.preventDefault();
      open();
    }
  });
})();
