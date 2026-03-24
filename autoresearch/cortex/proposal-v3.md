# Genius Cortex — Proposition v3 (Autoresearch Iteration 3)
*Architecture complète + Toutes les features + Plan d'implémentation*

---

## Vision Finale

Genius Cortex est le **système nerveux central** de tous tes projets de vibe coding. Une app desktop macOS (menubar + dashboard) qui :
- Voit tous tes projets, leur santé, leur version
- Partage comportements, mémoire, skills, config entre tous les projets
- Permet de créer, lancer, monitorer et gérer tous tes projets depuis un seul endroit
- Se synchronise entre toutes tes machines
- Se connecte via Telegram/WhatsApp pour le mobile

---

## Concepts Complets (16)

### Gouvernance
| Concept | Description | Stockage |
|---------|-------------|----------|
| **Behaviors** | Comment je travaille (prove-before-fix, post-fix-audit...) | `~/.genius-cortex/behaviors/` |
| **Habits** | Behaviors + tracking (l'agent a-t-il suivi ?) | `~/.genius-cortex/habits/` |
| **Rules** | Ce que je ne fais JAMAIS (jamais push main sans review) | `~/.genius-cortex/rules/` |

### Mémoire
| Concept | Description | Stockage |
|---------|-------------|----------|
| **Memory Bits** | Fragments cross-projets ("Ben préfère Supabase") | `~/.genius-cortex/memory/` |
| **Glossary** | Vocabulaire partagé ("MVP = X pour moi") | `~/.genius-cortex/glossary.md` |
| **Personas** | Profils contexte client (CJ Intelligence = vocab + contraintes) | `~/.genius-cortex/personas/` |

### Configuration
| Concept | Description | Stockage |
|---------|-------------|----------|
| **Global Skills** | Skills GT centralisés, injectés par projet au runtime | `~/.genius-cortex/skills/` |
| **Global MCPs** | Serveurs MCP partagés entre projets | `~/.genius-cortex/mcps/` |
| **Default Config** | Config CC parfaite (~/.claude/, CLAUDE.md base) | `~/.genius-cortex/config/` |
| **Templates** | Starters pour nouveaux projets (SaaS, API, mobile...) | `~/.genius-cortex/templates/` |
| **Code Bits** | Snippets réutilisables cross-repos | `~/.genius-cortex/codebits/` |

### Infrastructure
| Concept | Description | Stockage |
|---------|-------------|----------|
| **Vault** | Env vars, tokens, URLs, liens centralisés | `~/.genius-cortex/vault/` (chiffré) |
| **Registry** | Liste de tous les repos + état | `~/.genius-cortex/registry.json` |
| **Sync** | Sync multi-machines (behaviors, memory, config, vault) | Cloud layer |

### Intelligence
| Concept | Description | Stockage |
|---------|-------------|----------|
| **Genius Watch** | Veille IA quotidienne filtrée pour tes outils | `~/.genius-cortex/watch/` |
| **Heartbeat** | Logique OpenClaw soul/agents adaptée à Cortex | `~/.genius-cortex/heartbeat/` |

---

## Features Complètes (18)

### Core
| # | Feature | Description | Priority |
|---|---------|-------------|----------|
| 1 | **Dashboard** | Vue globale de tous les repos : version, santé, dernière activité | P0 |
| 2 | **Global Update** | Upgrade GT dans tous les repos en un clic | P0 |
| 3 | **Behavior Engine** | CRUD + injection + tracking des behaviors | P0 |
| 4 | **Memory Store** | Mémoire cross-projets avec search | P0 |
| 5 | **Project Factory** | "Nouveau projet" → questions → repo → GitHub → GT → Claude | P0 |

### Power
| # | Feature | Description | Priority |
|---|---------|-------------|----------|
| 6 | **Cortex Chat** | Chat unifié — questions meta + routing vers projets + bouton Quick Launch | P1 |
| 7 | **Vault** | Centralisation env vars/tokens, déploiement par projet | P1 |
| 8 | **Behavior Store** | Browse + install behaviors de la communauté | P1 |
| 9 | **Monitoring** | Alertes, QA automatisés, statut par catégorie/étape | P1 |
| 10 | **Quick Launch** | Bouton → ouvre terminal dans le bon repo avec tout configuré | P1 |

### Advanced
| # | Feature | Description | Priority |
|---|---------|-------------|----------|
| 11 | **Genius Watch** | Veille IA quotidienne filtrée | P2 |
| 12 | **Cross-Project Search** | "Où ai-je déjà implémenté Stripe ?" | P2 |
| 13 | **Auto-QA Scheduler** | "Tous les lundis, QA sur tous les repos actifs" | P2 |
| 14 | **Session History** | Historique sessions CC/Codex tous repos | P2 |
| 15 | **Project Health Score** | Score santé par projet (tests, GT version, TODOs) | P2 |
| 16 | **Dependency Watch** | Alertes mises à jour dépendances partagées | P2 |
| 17 | **Sync Cloud** | Synchronisation multi-machines (iCloud ou backend) | P2 |
| 18 | **Onboarding Flow** | Briefing contextuel pour nouveau dev sur un projet | P2 |

---

## Architecture Technique

### Stack
- **App** : Tauri 2.0 (Rust backend + Webview frontend)
  - Menubar icon avec status en temps réel
  - Dashboard window en HTML/CSS/JS (React ou Svelte)
  - Background daemon pour monitoring + sync
- **CLI** : Node.js (distribution npm — `genius-cortex`)
- **MCP Server** : TypeScript (intégration Claude Code native)
- **Sync** : iCloud Drive (MVP) ou backend custom (V2)
- **Vault** : AES-256 chiffrement local, keychain macOS pour la master key
- **Messaging** : Connecteur Telegram/WhatsApp via Channels ou OpenClaw

### Architecture Système

```
┌─────────────────── Genius Cortex ───────────────────┐
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │            Tauri App (macOS)                    │ │
│  │  ┌──────────┐ ┌──────────┐ ┌───────────────┐  │ │
│  │  │ Menubar  │ │Dashboard │ │  Cortex Chat  │  │ │
│  │  │ Icon     │ │ (WebView)│ │  (WebView)    │  │ │
│  │  └────┬─────┘ └────┬─────┘ └──────┬────────┘  │ │
│  │       └──────────────┼─────────────┘            │ │
│  └──────────────────────┼──────────────────────────┘ │
│                         │                            │
│  ┌──────────────────────┼──────────────────────────┐ │
│  │              Cortex Core (Rust/Node)             │ │
│  │                                                  │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐│ │
│  │  │ Registry │ │ Behavior │ │  Memory Engine   ││ │
│  │  │ Manager  │ │ Engine   │ │  (search+inject) ││ │
│  │  └──────────┘ └──────────┘ └──────────────────┘│ │
│  │                                                  │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐│ │
│  │  │  Vault   │ │ Skill    │ │  Project Factory ││ │
│  │  │ (crypto) │ │ Injector │ │  (create+config) ││ │
│  │  └──────────┘ └──────────┘ └──────────────────┘│ │
│  │                                                  │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐│ │
│  │  │  Watch   │ │  Sync    │ │  MCP Server      ││ │
│  │  │  Engine  │ │  Layer   │ │  (CC plugin)     ││ │
│  │  └──────────┘ └──────────┘ └──────────────────┘│ │
│  └──────────────────────────────────────────────────┘ │
│                         │                            │
│  ┌──────────┐ ┌────────┴───────┐ ┌──────────────┐  │
│  │ CLI      │ │ Telegram/WA    │ │  Claude Code  │  │
│  │ (npm)    │ │ (Channels)     │ │  (MCP)        │  │
│  └──────────┘ └────────────────┘ └──────────────┘  │
└──────────────────────────────────────────────────────┘
         │              │              │
    ┌────┴───┐    ┌────┴───┐    ┌────┴───┐
    │ Repo A │    │ Repo B │    │ Repo C │    ...
    └────────┘    └────────┘    └────────┘
```

### Injection Flow (comment Cortex alimente chaque projet)

```
Session CC démarre sur Repo A
         │
         ▼
Cortex MCP détecte le repo
         │
         ▼
Lit registry.json → identifie le projet
         │
         ▼
Injecte dans la session :
├── Active behaviors (depuis ~/.genius-cortex/behaviors/)
├── Relevant memory bits (depuis ~/.genius-cortex/memory/)
├── Active skills (depuis ~/.genius-cortex/skills/)
├── Project persona (si configuré)
├── Relevant code bits
└── Env vars du vault (si autorisé)
         │
         ▼
Claude Code travaille avec tout le contexte Cortex
         │
         ▼
En fin de session, Cortex capture :
├── Nouvelles memory bits
├── Habit tracking (behaviors suivis ?)
└── Activity log
```

### Vault — Sécurité

```
~/.genius-cortex/vault/
├── master.key         # Référence vers macOS Keychain
├── global.env.enc     # Env vars globales (chiffrées AES-256)
├── projects/
│   ├── utopia.env.enc
│   ├── artts.env.enc
│   └── cinefi.env.enc
└── tokens.enc         # API keys, OAuth tokens
```

- Master key dans macOS Keychain (pas sur disque)
- Chaque fichier .env chiffré individuellement
- `cortex vault get SUPABASE_URL --project utopia` → déchiffre + retourne
- `cortex vault inject utopia` → crée le `.env` dans le repo
- Jamais de secrets en clair dans les fichiers Cortex

### Sync Layer

```
Machine A (iMac)          iCloud Drive           Machine B (MacBook)
~/.genius-cortex/  ──sync──→  ~/Library/       ──sync──→  ~/.genius-cortex/
                              Mobile Documents/
                              genius-cortex/
```

MVP : iCloud Drive natif macOS. Zéro backend à gérer.
- Behaviors, memory, config, registry, vault (chiffré) → sync automatique
- Les repos eux-mêmes → git (pas Cortex)
- Conflit resolution : last-write-wins pour les fichiers simples, merge pour les listes

---

## Project Factory — Flow Détaillé

```
User: "Je veux créer un nouveau projet"

Cortex:
  1. "Comment s'appelle ton projet ?" → my-saas-app
  2. "Quel template ?" → [SaaS] [Landing Page] [API] [Mobile] [Custom]
  3. "Quel persona client ?" → [CJ Intelligence] [Aucun] [Nouveau...]
  4. "Quels skills spécifiques ?" → [Défaut GT] [+ crypto] [+ SEO] [Custom]
  5. "Repo GitHub ?" → [Créer w-3-art/my-saas-app] [Repo existant] [Pas de GitHub]

Cortex exécute :
  → mkdir ~/Projects/my-saas-app
  → cd ~/Projects/my-saas-app && git init
  → Applique le template choisi
  → Installe GT (bash create.sh)
  → Injecte le persona
  → Configure les skills
  → Copie les env vars du vault
  → gh repo create w-3-art/my-saas-app --private
  → git push
  → Ouvre un terminal avec Claude Code lancé + /genius-start

Total : ~30 secondes du "je veux un nouveau projet" à "Claude est prêt à coder"
```

---

## Cortex Chat — Design

Le chat Cortex est un **hub intelligent** :

**Mode Meta (questions sur les projets) :**
> User: "Quel projet utilise Supabase ?"
> Cortex: "3 projets : Utopia (v2.1), CJ Intelligence (v1.0), My-SaaS (setup en cours)"

**Mode Action (routing vers un projet) :**
> User: "Ajoute un endpoint /api/billing au projet Utopia"
> Cortex: "Je vais ouvrir Utopia dans Claude Code."
> [Bouton: 🚀 Ouvrir Utopia dans Claude Code]
> → Clic → Terminal s'ouvre dans ~/Projects/utopia avec CC lancé et le prompt pré-rempli

**Mode Factory :**
> User: "Nouveau projet"
> Cortex: → lance le flow Project Factory (voir ci-dessus)

---

## Genius Watch — Design

Feed quotidien, filtré pour tes outils :

```
┌─── Genius Watch — 24 mars 2026 ───────────────────┐
│                                                     │
│ 🔵 Claude Code v2.1.77                             │
│ Fix race condition background tasks. New --bare     │
│ flag for scripted mode.                             │
│ Impact: tes autoresearch loops seront plus stables  │
│ [Voir le changelog] [Mettre à jour CC]              │
│                                                     │
│ 🟢 Codex CLI 0.108.2                               │
│ MCP elicitation improvements.                       │
│ Impact: genius-experiments plus fiable              │
│ [Voir] [Ignorer]                                    │
│                                                     │
│ 📝 Best Practice: CLAUDE.md                        │
│ Anthropic recommande désormais d'inclure des        │
│ examples négatifs dans les rules.                   │
│ [Appliquer à tous les projets] [Lire l'article]    │
│                                                     │
└─────────────────────────────────────────────────────┘
```

Sources : GitHub releases API, Anthropic changelog, Codrops, HN/Reddit filtré, npm advisories.

---

## Plan d'Implémentation — "Build Everything"

### Sprint 1 — Fondations (Semaine 1-2)
- Scaffold Tauri 2.0 app + menubar
- Cortex Core : registry, scan, status
- CLI : `cortex init`, `cortex scan`, `cortex status`
- File structure + config system
- Dashboard v1 : liste repos + versions

### Sprint 2 — Behaviors + Memory (Semaine 2-3)
- Behavior Engine : CRUD, activation, injection dans ~/.claude/CLAUDE.md
- 7 starter behaviors
- Memory Store : add, search, show
- Habit tracking basique
- Rules system
- Dashboard : behaviors panel + memory viewer

### Sprint 3 — Project Factory + Vault (Semaine 3-4)
- Project Factory : template, persona, GitHub, GT install, CC launch
- Templates : SaaS, Landing Page, API, Mobile (4 starters)
- Vault : chiffrement, keychain, inject par projet
- Quick Launch : bouton → terminal + CC
- Dashboard : bouton "New Project" + vault manager

### Sprint 4 — Skills + MCPs + Chat (Semaine 4-5)
- Global Skills injection
- Global MCPs config
- Cortex Chat : meta questions + routing + factory
- MCP Server pour intégration CC native
- Code Bits : capture + search + inject

### Sprint 5 — Watch + Monitoring + Sync (Semaine 5-6)
- Genius Watch : feed + sources + filtrage
- Monitoring : health scores + alertes
- Auto-QA scheduler
- Sync layer (iCloud)
- Cross-project search

### Sprint 6 — Connecteurs + Polish (Semaine 6-7)
- Connecteur Telegram (via Channels)
- Connecteur WhatsApp (via OpenClaw)
- Glossary, Personas, Onboarding
- Behavior Store (communauté)
- Session History
- Dependency Watch
- Polish UI + tests

### Sprint 7 — Beta (Semaine 7-8)
- Tests end-to-end
- Documentation
- Site web Cortex
- Beta release

**Total : ~8 semaines pour la version complète**

---

## Business Model

### Free Tier
- ✅ CLI complet
- ✅ Dashboard local
- ✅ 5 repos
- ✅ 10 behaviors
- ✅ Memory basique (100 bits)
- ✅ 2 templates
- ✅ Vault (20 secrets)
- ✅ Quick Launch

### Pro ($12/mois)
- ∞ Repos
- ∞ Behaviors
- ∞ Memory
- ∞ Templates
- ∞ Vault
- Genius Watch
- Auto-QA Scheduler
- Cross-Project Search
- Sync Cloud (multi-machines)
- Behavior Store (communauté)
- Priority updates

### Team ($25/mois par siège)
- Tout Pro +
- Shared behaviors entre membres
- Shared memory
- Shared vault (permissions)
- Team dashboard
- Onboarding flows
- Admin panel

---

## Scores Autoresearch v3

| Criterion | Score | Notes |
|-----------|-------|-------|
| Feature completeness | 10/10 | 18 features, 16 concepts, all Ben's asks covered |
| Technical feasibility | 8/10 | Tauri + Node + MCP = proven stack, vault crypto = needs care |
| Differentiation | 10/10 | Nobody does multi-repo governance + shared behaviors + project factory |
| User experience | 9/10 | Menubar + dashboard + chat + CLI + mobile = 5 access points |
| Business viability | 9/10 | Clear free→pro→team path, behaviors marketplace = network effects |
| Implementation effort | 6/10 | ~8 weeks = ambitious but doable with vibe coding |
| Ecosystem fit | 10/10 | Builds ON TOP of GT/CC/Codex/OpenClaw, doesn't compete |

**Overall: 8.9/10**
