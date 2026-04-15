// Genius Team / Cortex onboarding wizard
// Uses the shared design language classes from docs/design-language/**.

const GeniusWizard = (() => {
  const state = {
    open: false,
    step: 0,
    product: 'gt',
    projectType: 'new',
    project: 'my-project',
    mode: 'cli',
    engine: 'claude',
    cortexAction: 'init',
    reposDir: '~/Projects',
  };

  let root = null;
  let escapeHandler = null;

  function el(selector) {
    return root?.querySelector(selector) || document.querySelector(selector);
  }

  function inject() {
    if (root) return;

    root = document.createElement('div');
    root.id = 'geniusWizard';
    root.className = 'wizard-overlay';
    root.dataset.open = 'false';
    root.setAttribute('role', 'dialog');
    root.setAttribute('aria-modal', 'true');
    root.setAttribute('aria-hidden', 'true');
    root.innerHTML = `
      <div class="wizard-card dl-surface dl-surface--strong">
        <div class="wizard-card__head">
          <div>
            <div class="dl-chip dl-chip--gold">Quick start</div>
            <h2 class="wizard-card__title">Choose your path</h2>
            <p class="wizard-card__desc">Genius Team builds inside a repo. Cortex coordinates a portfolio of GT repos. The wizard keeps both paths truthful.</p>
          </div>
          <button class="wizard-card__close" type="button" aria-label="Close" data-wizard-close>×</button>
        </div>

        <div class="wizard-progress" aria-hidden="true">
          <div class="wizard-progress__dot" data-progress-dot="0"></div>
          <div class="wizard-progress__line"></div>
          <div class="wizard-progress__dot" data-progress-dot="1"></div>
          <div class="wizard-progress__line"></div>
          <div class="wizard-progress__dot" data-progress-dot="2"></div>
          <div class="wizard-progress__line"></div>
          <div class="wizard-progress__dot" data-progress-dot="3"></div>
        </div>

        <div class="wizard-step is-active" data-step="0">
          <h3 class="wizard-step__title">What are you setting up?</h3>
          <p class="wizard-step__desc">Pick the surface that matches your next move.</p>
          <div class="wizard-options wizard-options--2">
            <button class="wizard-option is-active" type="button" data-choice="product" data-value="gt">
              <span class="dl-chip dl-chip--gold">Genius Team</span>
              <span class="wizard-option__title">Per-repo build framework</span>
              <span class="wizard-option__desc">Install or add GT to a codebase, then run the repository flow.</span>
            </button>
            <button class="wizard-option" type="button" data-choice="product" data-value="cortex">
              <span class="dl-chip">Cortex</span>
              <span class="wizard-option__title">Portfolio control tower</span>
              <span class="wizard-option__desc">Bootstrap the multi-repo workspace, scan repos, and align the portfolio.</span>
            </button>
          </div>
          <div class="wizard-actions">
            <span class="dl-provenance">The wizard only suggests commands that exist in the current toolchain.</span>
            <button class="dl-button dl-button--primary" type="button" data-wizard-next>Next</button>
          </div>
        </div>

        <div class="wizard-step" data-step="1"></div>
        <div class="wizard-step" data-step="2"></div>
        <div class="wizard-step" data-step="3"></div>
      </div>
    `;

    document.body.appendChild(root);
    root.addEventListener('click', handleClick);
    root.addEventListener('click', event => {
      if (event.target === root) close();
    });
    render();
  }

  function handleClick(event) {
    const closeBtn = event.target.closest('[data-wizard-close]');
    if (closeBtn) {
      close();
      return;
    }

    const choice = event.target.closest('[data-choice]');
    if (choice) {
      const key = choice.getAttribute('data-choice');
      const value = choice.getAttribute('data-value') || '';
      state[key] = value;
      render();
      return;
    }

    if (event.target.closest('[data-wizard-next]')) {
      advance();
      return;
    }

    if (event.target.closest('[data-wizard-back]')) {
      back();
      return;
    }

    if (event.target.closest('[data-wizard-copy]')) {
      const code = el('[data-wizard-result-code]')?.textContent || '';
      navigator.clipboard?.writeText(code);
      const btn = event.target.closest('[data-wizard-copy]');
      if (btn) {
        const previous = btn.textContent;
        btn.textContent = 'Copied';
        setTimeout(() => {
          btn.textContent = previous || 'Copy';
        }, 1200);
      }
    }
  }

  function open() {
    inject();
    root.dataset.open = 'true';
    state.open = true;
    render();
    const current = el('[data-step="0"].is-active [data-choice]');
    current?.focus();
  }

  function close() {
    if (!root) return;
    root.dataset.open = 'false';
    state.open = false;
  }

  function advance() {
    if (state.step < 3) state.step += 1;
    if (state.step === 3) generate();
    render();
  }

  function back() {
    if (state.step > 0) state.step -= 1;
    render();
  }

  function setStepContent(stepIndex, html) {
    const step = el(`[data-step="${stepIndex}"]`);
    if (step) step.innerHTML = html;
  }

  function render() {
    if (!root) return;

    qsa('[data-choice]').forEach(button => {
      const key = button.getAttribute('data-choice');
      const value = button.getAttribute('data-value');
      button.classList.toggle('is-active', state[key] === value);
    });

    qsa('[data-step]').forEach(step => {
      const index = Number(step.getAttribute('data-step') || '0');
      step.classList.toggle('is-active', index === state.step);
    });

    qsa('[data-progress-dot]').forEach(dot => {
      const index = Number(dot.getAttribute('data-progress-dot') || '0');
      dot.classList.toggle('is-active', index <= state.step);
    });

    if (state.step === 1) {
      if (state.product === 'gt') {
        setStepContent(1, `
          <h3 class="wizard-step__title">How are you starting with Genius Team?</h3>
          <p class="wizard-step__desc">Choose whether you are creating a new repo or adopting an existing one.</p>
          <div class="wizard-options wizard-options--2">
            <button class="wizard-option ${state.projectType === 'new' ? 'is-active' : ''}" type="button" data-choice="projectType" data-value="new">
              <span class="dl-chip dl-chip--gold">New repo</span>
              <span class="wizard-option__title">Create a project</span>
              <span class="wizard-option__desc">Clone Genius Team into a fresh repo and initialize the runtime.</span>
            </button>
            <button class="wizard-option ${state.projectType === 'existing' ? 'is-active' : ''}" type="button" data-choice="projectType" data-value="existing">
              <span class="dl-chip">Existing repo</span>
              <span class="wizard-option__title">Add GT to a codebase</span>
              <span class="wizard-option__desc">Keep the repo, add GT files, and align it to the v22 contract.</span>
            </button>
          </div>
          <div class="wizard-field">
            <label for="wizardProject">Project name</label>
            <input id="wizardProject" type="text" value="${escapeHtml(state.project)}" placeholder="my-project" data-wizard-project>
          </div>
          <div class="wizard-actions">
            <button class="dl-button dl-button--ghost" type="button" data-wizard-back>Back</button>
            <button class="dl-button dl-button--primary" type="button" data-wizard-next>Next</button>
          </div>
        `);
      } else {
        setStepContent(1, `
          <h3 class="wizard-step__title">What do you want Cortex to do?</h3>
          <p class="wizard-step__desc">Cortex is the transverse control tower. Start with the action that matches your portfolio.</p>
          <div class="wizard-options wizard-options--3">
            <button class="wizard-option ${state.cortexAction === 'init' ? 'is-active' : ''}" type="button" data-choice="cortexAction" data-value="init">
              <span class="dl-chip dl-chip--gold">Bootstrap</span>
              <span class="wizard-option__title">Initialize workspace</span>
              <span class="wizard-option__desc">Create the Cortex home directories and starter state.</span>
            </button>
            <button class="wizard-option ${state.cortexAction === 'scan' ? 'is-active' : ''}" type="button" data-choice="cortexAction" data-value="scan">
              <span class="dl-chip">Scan</span>
              <span class="wizard-option__title">Discover repos</span>
              <span class="wizard-option__desc">Find Genius Team projects in your workspace and classify them.</span>
            </button>
            <button class="wizard-option ${state.cortexAction === 'upgrade' ? 'is-active' : ''}" type="button" data-choice="cortexAction" data-value="upgrade">
              <span class="dl-chip">Align</span>
              <span class="wizard-option__title">Upgrade portfolio</span>
              <span class="wizard-option__desc">Bring repos toward the current GT contract and Cortex-ready state.</span>
            </button>
          </div>
          <div class="wizard-actions">
            <button class="dl-button dl-button--ghost" type="button" data-wizard-back>Back</button>
            <button class="dl-button dl-button--primary" type="button" data-wizard-next>Next</button>
          </div>
        `);
      }
    }

    if (state.step === 2) {
      if (state.product === 'gt') {
        setStepContent(2, `
          <h3 class="wizard-step__title">Which mode and engine do you want?</h3>
          <p class="wizard-step__desc">Pick the execution mode and engine for the install command.</p>
          <div class="wizard-options wizard-options--2" style="margin-bottom:0.75rem">
            <button class="wizard-option ${state.mode === 'cli' ? 'is-active' : ''}" type="button" data-choice="mode" data-value="cli">
              <span class="dl-chip dl-chip--gold">CLI</span>
              <span class="wizard-option__title">Terminal first</span>
              <span class="wizard-option__desc">Claude Code in the terminal.</span>
            </button>
            <button class="wizard-option ${state.mode === 'ide' ? 'is-active' : ''}" type="button" data-choice="mode" data-value="ide">
              <span class="dl-chip">IDE</span>
              <span class="wizard-option__title">Editor first</span>
              <span class="wizard-option__desc">VS Code or Cursor with the same GT contract.</span>
            </button>
          </div>
          <div class="wizard-options wizard-options--3">
            <button class="wizard-option ${state.engine === 'claude' ? 'is-active' : ''}" type="button" data-choice="engine" data-value="claude">
              <span class="dl-chip dl-chip--gold">Claude</span>
              <span class="wizard-option__title">Default engine</span>
              <span class="wizard-option__desc">Best fit for the current GT site and repo flow.</span>
            </button>
            <button class="wizard-option ${state.engine === 'codex' ? 'is-active' : ''}" type="button" data-choice="engine" data-value="codex">
              <span class="dl-chip">Codex</span>
              <span class="wizard-option__title">Codex CLI</span>
              <span class="wizard-option__desc">Use the same repo contract from the OpenAI engine.</span>
            </button>
            <button class="wizard-option ${state.engine === 'dual' ? 'is-active' : ''}" type="button" data-choice="engine" data-value="dual">
              <span class="dl-chip">Dual</span>
              <span class="wizard-option__title">Builder + challenger</span>
              <span class="wizard-option__desc">Two-engine mode for paired checks.</span>
            </button>
          </div>
          <div class="wizard-actions">
            <button class="dl-button dl-button--ghost" type="button" data-wizard-back>Back</button>
            <button class="dl-button dl-button--primary" type="button" data-wizard-next>Generate command</button>
          </div>
        `);
      } else {
        setStepContent(2, `
          <h3 class="wizard-step__title">Where are the repositories?</h3>
          <p class="wizard-step__desc">Cortex can bootstrap the workspace, scan repos, or align the portfolio from a directory.</p>
          <div class="wizard-field">
            <label for="wizardReposDir">Projects directory</label>
            <input id="wizardReposDir" type="text" value="${escapeHtml(state.reposDir)}" placeholder="~/Projects" data-wizard-reposdir>
          </div>
          <div class="wizard-actions">
            <button class="dl-button dl-button--ghost" type="button" data-wizard-back>Back</button>
            <button class="dl-button dl-button--primary" type="button" data-wizard-next>Generate command</button>
          </div>
        `);
      }
    }

    if (state.step === 3) {
      generate();
      setStepContent(3, `
        <h3 class="wizard-step__title">Your command is ready</h3>
        <p class="wizard-step__desc">Copy the command, run it in your terminal, then follow the next step shown below.</p>
        <div class="wizard-result">
          <div class="wizard-result__code" data-wizard-result-code></div>
          <div class="wizard-result__meta">
            <button class="dl-button dl-button--secondary" type="button" data-wizard-copy>Copy command</button>
            <button class="dl-button dl-button--ghost" type="button" data-wizard-back>Back</button>
          </div>
          <div class="wizard-result__note" data-wizard-next-step></div>
        </div>
      `);
    }
  }

  function qsa(selector, rootNode = document) {
    return Array.from(rootNode.querySelectorAll(selector));
  }

  function escapeHtml(value) {
    return String(value)
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
  }

  function readInputs() {
    const projectInput = el('[data-wizard-project]');
    if (projectInput) state.project = projectInput.value.trim() || 'my-project';

    const reposInput = el('[data-wizard-reposdir]');
    if (reposInput) state.reposDir = reposInput.value.trim() || '~/Projects';
  }

  function generate() {
    readInputs();

    let command = '';
    let note = '';

    if (state.product === 'gt') {
      const flags = [];
      if (state.mode && state.mode !== 'cli') flags.push(`--mode ${state.mode}`);
      if (state.engine && state.engine !== 'claude') flags.push(`--engine ${state.engine}`);
      const suffix = flags.length ? ` ${flags.join(' ')}` : '';

      if (state.projectType === 'existing') {
        command = `cd ${state.project} && bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/add.sh)${suffix}`;
      } else {
        command = `bash <(curl -fsSL https://raw.githubusercontent.com/w-3-art/genius-team/main/scripts/create.sh) ${state.project}${suffix}`;
      }

      note = state.engine === 'codex'
        ? `Then open the repo with <code>codex</code> and run <code>/genius-start</code>.`
        : `Then open the repo with <code>claude</code> and run <code>/genius-start</code>.`;
    } else {
      const dir = state.reposDir || '~/Projects';
      if (state.cortexAction === 'upgrade') {
        command = `cortex upgrade --all`;
        note = `Use <code>cortex status</code> afterwards to confirm the portfolio is aligned.`;
      } else if (state.cortexAction === 'scan') {
        command = `cortex scan ${dir}`;
        note = `Then run <code>cortex status</code> to review compatibility and readiness.`;
      } else {
        command = `npm install -g genius-cortex && cortex init`;
        note = `After init, run <code>cortex scan ${dir}</code> to discover your repos.`;
      }
    }

    const result = el('[data-wizard-result-code]');
    const noteEl = el('[data-wizard-next-step]');
    if (result) result.textContent = command;
    if (noteEl) noteEl.innerHTML = note;
  }

  function open() {
    inject();
    state.step = 0;
    state.product = 'gt';
    state.projectType = 'new';
    state.project = 'my-project';
    state.mode = 'cli';
    state.engine = 'claude';
    state.cortexAction = 'init';
    state.reposDir = '~/Projects';
    root.dataset.open = 'true';
    root.setAttribute('aria-hidden', 'false');
    state.open = true;
    document.documentElement.style.overflow = 'hidden';
    if (!escapeHandler) {
      escapeHandler = event => {
        if (event.key === 'Escape') close();
      };
    }
    document.addEventListener('keydown', escapeHandler);
    render();
  }

  function close() {
    if (!root) return;
    root.dataset.open = 'false';
    root.setAttribute('aria-hidden', 'true');
    state.open = false;
    document.documentElement.style.overflow = '';
    if (escapeHandler) {
      document.removeEventListener('keydown', escapeHandler);
    }
  }

  return {
    state,
    init: inject,
    open,
    close,
  };
})();

window.GeniusWizard = GeniusWizard;
