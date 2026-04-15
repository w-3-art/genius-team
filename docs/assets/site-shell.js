(function () {
  function qs(selector, root = document) {
    return root.querySelector(selector);
  }

  function qsa(selector, root = document) {
    return Array.from(root.querySelectorAll(selector));
  }

  function copyText(value, button) {
    if (!value) return;
    navigator.clipboard?.writeText(value).then(() => {
      if (!button) return;
      const previous = button.textContent;
      button.textContent = 'Copied';
      button.disabled = true;
      window.setTimeout(() => {
        button.textContent = previous;
        button.disabled = false;
      }, 1300);
    });
  }

  function initNav() {
    const nav = qs('[data-site-nav]');
    const panel = qs('[data-mobile-nav]');
    const toggle = qs('[data-nav-toggle]');
    if (!toggle || !panel) return;

    const closePanel = () => {
      panel.dataset.open = 'false';
      toggle.setAttribute('aria-expanded', 'false');
    };

    toggle.addEventListener('click', () => {
      const open = panel.dataset.open === 'true';
      panel.dataset.open = open ? 'false' : 'true';
      toggle.setAttribute('aria-expanded', String(!open));
    });

    qsa('a', panel).forEach(link => {
      link.addEventListener('click', closePanel);
    });

    if (nav) {
      const onScroll = () => {
        nav.dataset.scrolled = window.scrollY > 12 ? 'true' : 'false';
      };
      onScroll();
      window.addEventListener('scroll', onScroll, { passive: true });
    }
  }

  function initReveal() {
    const nodes = qsa('[data-reveal]');
    if (!nodes.length) return;
    if (!('IntersectionObserver' in window)) {
      nodes.forEach(node => node.classList.add('is-visible'));
      return;
    }
    const observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.16 });
    nodes.forEach(node => observer.observe(node));
  }

  function initCopyButtons() {
    document.addEventListener('click', event => {
      const button = event.target.closest('[data-copy-command]');
      if (!button) return;
      copyText(button.getAttribute('data-copy-command'), button);
    });
  }

  function initChat() {
    const widget = qs('[data-chat-widget]');
    if (!widget) return;

    const panel = qs('[data-chat-panel]', widget);
    const toggle = qs('[data-chat-toggle]', widget);
    const close = qs('[data-chat-close]', widget);
    const form = qs('[data-chat-form]', widget);
    const input = qs('[data-chat-input]', widget);
    const messages = qs('[data-chat-messages]', widget);
    const prompts = qsa('[data-chat-prompt]', widget);

    if (!panel || !toggle || !close || !form || !input || !messages) return;

    const addMessage = (role, text) => {
      const bubble = document.createElement('div');
      bubble.className = 'site-chat__bubble';
      bubble.dataset.role = role;
      bubble.textContent = text;
      messages.appendChild(bubble);
      messages.scrollTop = messages.scrollHeight;
    };

    const openPanel = () => {
      panel.dataset.open = 'true';
      toggle.setAttribute('aria-expanded', 'true');
      input.focus();
    };

    const closePanel = () => {
      panel.dataset.open = 'false';
      toggle.setAttribute('aria-expanded', 'false');
    };

    toggle.addEventListener('click', () => {
      const open = panel.dataset.open === 'true';
      if (open) closePanel();
      else openPanel();
    });

    close.addEventListener('click', closePanel);

    prompts.forEach(button => {
      button.addEventListener('click', () => {
        input.value = button.getAttribute('data-chat-prompt') || '';
        openPanel();
      });
    });

    form.addEventListener('submit', async event => {
      event.preventDefault();
      const text = input.value.trim();
      if (!text) return;
      input.value = '';
      addMessage('user', text);
      const typing = document.createElement('div');
      typing.className = 'site-chat__bubble';
      typing.dataset.role = 'assistant';
      typing.textContent = 'Thinking...';
      messages.appendChild(typing);
      messages.scrollTop = messages.scrollHeight;

      try {
        const response = await fetch('/api/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            message: text,
            history: qsa('.site-chat__bubble', messages)
              .slice(-10)
              .filter(node => node !== typing)
              .map(node => ({
                role: node.dataset.role,
                content: node.textContent || '',
              })),
          }),
        });

        typing.remove();

        if (!response.ok) {
          addMessage('assistant', 'I could not reach the assistant endpoint.');
          return;
        }

        const data = await response.json();
        addMessage('assistant', data.message || 'No answer returned.');
      } catch (error) {
        typing.remove();
        addMessage('assistant', 'Network error while contacting the assistant.');
      }
    });

    if (!messages.children.length) {
      addMessage('assistant', 'Ask about Genius Team, Cortex, the shared design language, or the difference between project artifacts and intelligence objects.');
    }
  }

  function initActiveLinks() {
    const path = window.location.pathname.split('/').pop() || 'index.html';
    qsa('[data-nav-link]').forEach(link => {
      const href = link.getAttribute('href') || '';
      const match = href.endsWith(path) || (path === '' && href.endsWith('index.html'));
      if (match) link.classList.add('active');
    });
  }

  function initWizardTriggers() {
    const openers = qsa('[data-open-wizard]');
    if (!openers.length) return;

    const openWizard = () => {
      window.GeniusWizard?.open?.();
    };

    openers.forEach(button => {
      button.addEventListener('click', openWizard);
    });
  }

  function initScrollProgress() {
    const bar = qs('[data-scroll-progress]');
    if (!bar) return;

    const sync = () => {
      const scrollable = document.documentElement.scrollHeight - window.innerHeight;
      const progress = scrollable > 0 ? window.scrollY / scrollable : 0;
      bar.style.transform = `scaleX(${Math.min(Math.max(progress, 0), 1)})`;
    };

    sync();
    window.addEventListener('scroll', sync, { passive: true });
    window.addEventListener('resize', sync);
  }

  function initChapterLinks() {
    const links = qsa('[data-chapter-link]');
    if (!links.length) return;

    const targets = Array.from(
      new Map(
        links
          .map(link => link.getAttribute('href') || '')
          .filter(href => href.startsWith('#'))
          .map(href => [href, qs(href)])
          .filter(([, node]) => Boolean(node))
      ).entries()
    );

    if (!targets.length) return;

    const sync = () => {
      const scrollTop = window.scrollY + 160;
      let activeHref = targets[0][0];

      targets.forEach(([href, node]) => {
        if (node.offsetTop <= scrollTop) activeHref = href;
      });

      if (window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 8) {
        activeHref = targets[targets.length - 1][0];
      }

      links.forEach(link => {
        const isActive = link.getAttribute('href') === activeHref;
        link.classList.toggle('is-active', isActive);
        if (isActive) link.setAttribute('aria-current', 'true');
        else link.removeAttribute('aria-current');
      });
    };

    sync();
    window.addEventListener('scroll', sync, { passive: true });
    window.addEventListener('resize', sync);
  }

  document.addEventListener('DOMContentLoaded', () => {
    initNav();
    initReveal();
    initCopyButtons();
    initWizardTriggers();
    initScrollProgress();
    initChapterLinks();
    initChat();
    initActiveLinks();
  });

  window.SiteShell = {
    copy: copyText,
  };
})();
