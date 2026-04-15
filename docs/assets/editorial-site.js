(function () {
  function qs(selector, root) {
    return (root || document).querySelector(selector);
  }

  function qsa(selector, root) {
    return Array.from((root || document).querySelectorAll(selector));
  }

  function clamp(value, min, max) {
    return Math.min(Math.max(value, min), max);
  }

  function initCursorSystem() {
    const ring = qs("[data-cursor-ring]");
    const dot = qs("[data-cursor-dot]");
    const glow = qs("[data-cursor-glow]");

    if (!ring || !dot || window.matchMedia("(pointer: coarse)").matches) return;

    let active = false;
    let pressed = false;

    const syncState = () => {
      ring.classList.toggle("is-active", active);
      dot.classList.toggle("is-active", active);
      ring.classList.toggle("is-pressed", pressed);
    };

    const move = event => {
      const x = event.clientX + "px";
      const y = event.clientY + "px";
      ring.style.left = x;
      ring.style.top = y;
      dot.style.left = x;
      dot.style.top = y;
      if (glow) {
        glow.style.left = x;
        glow.style.top = y;
      }
    };

    const interactive = "a, button, [data-copy-command]";

    qsa(interactive).forEach(node => {
      node.addEventListener("pointerenter", () => {
        active = true;
        syncState();
      });
      node.addEventListener("pointerleave", () => {
        active = false;
        syncState();
      });
    });

    document.addEventListener("pointermove", move, { passive: true });
    document.addEventListener("pointerdown", () => {
      pressed = true;
      syncState();
    });
    document.addEventListener("pointerup", () => {
      pressed = false;
      syncState();
    });
  }

  function initNav() {
    const nav = qs("[data-site-nav]");
    if (!nav) return;

    const sync = () => {
      nav.dataset.scrolled = window.scrollY > 32 ? "true" : "false";
    };

    sync();
    window.addEventListener("scroll", sync, { passive: true });
  }

  function initScrollProgress() {
    const fill = qs("[data-scroll-fill]");
    if (!fill) return;

    const sync = () => {
      const scrollable = document.documentElement.scrollHeight - window.innerHeight;
      const progress = scrollable > 0 ? Math.min(window.scrollY / scrollable, 1) : 0;
      fill.style.transform = "scaleX(" + progress + ")";
    };

    sync();
    window.addEventListener("scroll", sync, { passive: true });
    window.addEventListener("resize", sync);
  }

  function initPageLinks() {
    const path = window.location.pathname.split("/").pop() || "index.html";
    qsa("[data-page-link]").forEach(link => {
      const href = link.getAttribute("href") || "";
      if (href.endsWith(path)) link.classList.add("is-active");
    });
  }

  function initChapterNav() {
    const links = qsa("[data-chapter-link]");
    if (!links.length) return;

    const targets = links
      .map(link => {
        const href = link.getAttribute("href") || "";
        if (!href.startsWith("#")) return null;
        const node = qs(href);
        if (!node) return null;
        return { href: href, node: node };
      })
      .filter(Boolean);

    if (!targets.length) return;

    const sync = () => {
      const marker = window.scrollY + 180;
      let active = targets[0].href;

      targets.forEach(target => {
        if (target.node.offsetTop <= marker) active = target.href;
      });

      if (window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 8) {
        active = targets[targets.length - 1].href;
      }

      links.forEach(link => {
        const isActive = link.getAttribute("href") === active;
        link.classList.toggle("is-active", isActive);
        if (isActive) link.setAttribute("aria-current", "true");
        else link.removeAttribute("aria-current");
      });
    };

    sync();
    window.addEventListener("scroll", sync, { passive: true });
    window.addEventListener("resize", sync);
  }

  function initFloatingPageNav() {
    const pageNav = qs(".page-nav");
    if (!pageNav) return;

    const sync = () => {
      pageNav.classList.toggle("is-visible", window.scrollY > 360);
    };

    sync();
    window.addEventListener("scroll", sync, { passive: true });
    window.addEventListener("resize", sync);
  }

  function initReveal() {
    const nodes = qsa(".reveal");
    if (!nodes.length) return;

    if (!("IntersectionObserver" in window)) {
      nodes.forEach(node => node.classList.add("is-visible"));
      return;
    }

    const observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.14 });

    nodes.forEach(node => observer.observe(node));
  }

  function initCopyButtons() {
    document.addEventListener("click", event => {
      const button = event.target.closest("[data-copy-command]");
      if (!button) return;

      const value = button.getAttribute("data-copy-command");
      if (!value) return;

      navigator.clipboard?.writeText(value).then(() => {
        const previous = button.dataset.copyLabel || button.textContent;
        button.dataset.copyLabel = previous;
        button.textContent = "Copied";
        button.disabled = true;
        window.setTimeout(() => {
          button.textContent = previous;
          button.disabled = false;
        }, 1200);
      });
    });
  }

  function initCounters() {
    const counters = qsa("[data-count]");
    if (!counters.length) return;

    const startCounter = node => {
      if (node.dataset.started === "true") return;
      node.dataset.started = "true";

      const target = Number(node.getAttribute("data-count") || "0");
      const duration = 1100;
      const start = performance.now();

      const tick = now => {
        const progress = Math.min((now - start) / duration, 1);
        const value = Math.round(target * progress);
        node.textContent = String(value);
        if (progress < 1) requestAnimationFrame(tick);
        else node.dataset.counted = "true";
      };

      requestAnimationFrame(tick);
    };

    if (!("IntersectionObserver" in window)) {
      counters.forEach(startCounter);
      return;
    }

    const observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          startCounter(entry.target);
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.35 });

    counters.forEach(node => observer.observe(node));
  }

  function initKineticText() {
    const nodes = qsa("[data-kinetic-text]");
    if (!nodes.length) return;

    nodes.forEach(node => {
      const text = (node.getAttribute("data-kinetic-text") || "").trim();
      if (!text) return;

      node.setAttribute("aria-label", text);
      node.textContent = "";

      text.split(/\s+/).forEach((word, index) => {
        const span = document.createElement("span");
        span.textContent = word;
        span.style.transitionDelay = index * 45 + "ms";
        node.appendChild(span);
      });
    });

    if (!("IntersectionObserver" in window)) {
      nodes.forEach(node => node.classList.add("is-live"));
      return;
    }

    const observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-live");
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.45 });

    nodes.forEach(node => observer.observe(node));
  }

  function initStoryShowcases() {
    const sections = qsa("[data-story-showcase]");
    if (!sections.length) return;

    const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    const syncSection = section => {
      const track = qs("[data-showcase-track]", section);
      const viewport = qs(".showcase__viewport", section);
      if (!track || !viewport) return;

      if (window.innerWidth <= 980 || prefersReducedMotion) {
        section.style.minHeight = "";
        track.style.transform = "";
        return;
      }

      const distance = Math.max(track.scrollWidth - viewport.clientWidth, 0);
      section.dataset.distance = String(distance);
      section.style.minHeight = window.innerHeight + distance + 220 + "px";
    };

    const update = () => {
      sections.forEach(section => {
        const track = qs("[data-showcase-track]", section);
        const distance = Number(section.dataset.distance || "0");

        if (!track || window.innerWidth <= 980 || prefersReducedMotion || !distance) {
          if (track) track.style.transform = "";
          return;
        }

        const total = Math.max(section.offsetHeight - window.innerHeight, 1);
        const progress = clamp((window.scrollY - section.offsetTop) / total, 0, 1);
        track.style.transform = "translate3d(" + (-distance * progress) + "px, 0, 0)";
      });
    };

    const syncAll = () => {
      sections.forEach(syncSection);
      update();
    };

    syncAll();
    window.addEventListener("resize", syncAll);
    window.addEventListener("scroll", update, { passive: true });
  }

  document.addEventListener("DOMContentLoaded", () => {
    initCursorSystem();
    initNav();
    initScrollProgress();
    initPageLinks();
    initChapterNav();
    initFloatingPageNav();
    initReveal();
    initCopyButtons();
    initCounters();
    initKineticText();
    initStoryShowcases();
  });
})();
