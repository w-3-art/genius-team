# Genius ecosystem marketing site

This `docs/` folder is the **marketing / product site** for the Genius ecosystem
(Genius Team, Cortex, Revius). It is a self-contained unit that **deploys
separately from the framework, skills, and templates** that make up the rest of
this repository. Nothing under `docs/` is loaded into a Genius Team session or
copied into scaffolded target projects.

## What lives here

- **Product pages** — `index.html`, `cortex.html`, `revius.html`,
  `genius-team.html`, plus `mockups/`.
- **Assets** — `assets/`, `design-language/`, `brand/`, `img/`, and the
  screenshots referenced by the pages under `screenshots/` (excluding the
  regenerable groups listed below).
- **Deploy config** — `vercel.json` (domain alias + rewrites + updater headers),
  `.vercel/project.json` (project/domain binding), `sitemap.xml`, `robots.txt`.
- **Updater artifacts** — `updates/latest.json` + the Tauri bundles served to the
  Cortex desktop auto-updater.

## How it deploys (two separate targets, one logical site)

1. **Static (Vercel).** `.github/workflows/deploy.yml` runs `vercel --prod` on any
   push touching `docs/**` and publishes this folder to **https://genius.w3art.io**.
   The GitHub Actions checkout only contains git-tracked files, so **any asset a
   page references must stay tracked** or it will 404 in production.
2. **Dynamic host (Railway).** The repo-root [`server.js`](../server.js) is the
   Node/Hono host for this same folder. It serves the static pages, the
   `POST /api/chat` proxy (CORS-allowlisted + per-IP rate-limited — see the
   `CHAT_RATE_LIMIT_*` / `ALLOWED_CHAT_ORIGINS` block at the top of `server.js`),
   and the Tauri updater endpoints under `/updates/*`. `server.js` and the
   root `package.json` (`"genius-team-site"`) belong to this site unit even
   though they physically sit at the repo root.

## Binary / asset policy (why some files are gitignored)

- **Versioned:** every image a page links to (`screenshots/cortex/`,
  `screenshots/mockups/`, `screenshots/revius/`, the top-level playground
  captures, `img/`, `assets/`). Untracking these breaks the live site.
- **Gitignored (regenerable, not served):** `screenshots/site-preview/` (Playwright
  meta-captures of the site itself), `screenshots/scroll-test/`,
  `screenshots/audit/`. Kept on disk locally; excluded from the repo.
- **Oversized release artifacts** (`updates/*.dmg`, `updates/*.app.tar.gz`) are
  still tracked **only because the updater serves them from this domain**. They
  are the main source of git-history bloat and should move to GitHub Releases so
  they can be untracked — see the ecosystem plan (P5-05 follow-ups).

## Planned full extraction

The long-term intent is to move this site into its own repository. That is **not**
a plain `git mv docs/ site/`: it also requires updating `server.js`
(`DOCS_DIR`), the `deploy.yml` `paths:` filter, the Vercel project root, and
**re-binding the `genius.w3art.io` domain**. Because it touches the live domain
binding it is a deliberate, owner-run migration, not an in-repo refactor.
