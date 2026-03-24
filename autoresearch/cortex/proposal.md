# Genius Cortex — Multi-Repo Orchestration Layer
*Proposition v1 — Autoresearch iteration 1*

---

## 1. Vision

**Genius Cortex** est le "cerveau" au-dessus de tous tes repos Genius Team. Un outil centralisé qui :
- Voit tous tes projets d'un coup d'œil
- S'assure que Genius Team est à jour partout
- Partage la mémoire et les comportements entre projets
- Pilote l'activité multi-repos

**Analogie :** Si Genius Team est ton équipe AI sur un projet, Genius Cortex est le **CTO** qui supervise tous les projets.

---

## 2. Features Possibles (classées par impact)

### 🔴 Tier 1 — Core (MVP)

**F1. Dashboard Multi-Repos**
- Liste de tous les repos avec Genius Team installé
- Pour chaque repo : version GT actuelle, statut (à jour / outdated), dernière activité
- Scan automatique d'un dossier parent (ex: `~/Projects/`)
- Un clic = upgrade le repo

**F2. Shared Behaviors (Bibliothèque de Réflexes)**
- Fichier central `~/.genius-cortex/behaviors/` avec des règles partagées
- Exemples de behaviors :
  - `prove-before-fix.md` — "Toujours prouver l'hypothèse avant de corriger"
  - `post-fix-audit.md` — "Après chaque fix, mini-audit pour vérifier pas de régression"
  - `no-guessing.md` — "Pas d'hypothèses — vérifier, lire le code, reproduire d'abord"
  - `test-first.md` — "Écrire le test avant le code"
- Injectés automatiquement dans le CLAUDE.md de chaque projet au runtime
- Importable/exportable : `cortex behaviors export`, `cortex behaviors import <url>`
- Community marketplace : partager ses behaviors sur GitHub

**F3. Centralized Memory (Mémoire Partagée)**
- `~/.genius-cortex/memory/` pour les souvenirs cross-projets
- Catégories :
  - `reflexes/` — comportements de dev (voir F2)
  - `preferences/` — préférences utilisateur ("je n'aime pas X", "toujours utiliser Y")
  - `learnings/` — leçons apprises ("sur le projet Z, on a découvert que...")
  - `contacts/` — infos sur les personnes/clients partagées
- Mécanisme de sync : Cortex injecte la mémoire pertinente dans chaque session
- Pas TOUT — seulement ce qui est générique et utile cross-projets

**F4. Version Monitor + Auto-Upgrade**
- Vérifie périodiquement si chaque repo est à jour
- Notification macOS quand une nouvelle version GT sort
- Un bouton "Upgrade All" pour mettre tous les repos à jour en un clic
- Dry-run par défaut, confirmation avant apply

### 🟠 Tier 2 — Power Features

**F5. Activity Feed**
- Timeline de toutes les activités GT sur tous les repos
- "14h — Projet X : genius-dev a implémenté le module auth"
- "15h — Projet Y : genius-qa a trouvé 3 bugs"
- Filtrable par projet, par agent, par date

**F6. Cross-Repo Context**
- Quand tu travailles sur le Projet A, Cortex peut injecter du contexte du Projet B
- Ex: "Dans le projet Utopia, on utilise Supabase comme ça..." quand tu travailles sur un autre projet qui utilise aussi Supabase
- Opt-in par projet

**F7. Health Dashboard**
- Score santé par repo : tests passent ? build OK ? dernière mise à jour ?
- Alertes si un repo a des problèmes non résolus depuis X jours
- Intégration CI/CD optionnelle

**F8. Session Launcher**
- Lancer une session Claude Code / Codex sur n'importe quel repo depuis le dashboard
- Avec les behaviors et la mémoire déjà injectés
- Choix du mode (CLI/IDE/Omni/Dual)

### 🟡 Tier 3 — Community & Advanced

**F9. Behavior Marketplace**
- Partager ses behaviors sur un registry (genre npm pour les réflexes dev)
- `cortex behaviors install @community/tdd-first`
- `cortex behaviors install @community/clean-architecture`
- Ratings, reviews, versioning

**F10. Multi-Agent Cross-Repo**
- Lancer un agent qui travaille sur plusieurs repos simultanément
- Ex: "Mets à jour l'API shared entre Projet A et Projet B"
- Coordination automatique

**F11. Analytics**
- Combien de tokens consommés par projet ?
- Quel agent est le plus utilisé ?
- Tendances sur le temps

---

## 3. Architectures Possibles

### Architecture A — CLI Tool (`cortex`)

```
~/.genius-cortex/
├── config.json          # repos list, settings
├── behaviors/           # shared behavior files
│   ├── prove-before-fix.md
│   └── post-fix-audit.md
├── memory/              # cross-project memory
│   ├── reflexes/
│   ├── preferences/
│   └── learnings/
└── cache/               # version cache, activity log
```

**Comment ça marche :**
- `cortex scan ~/Projects` → trouve tous les repos GT
- `cortex status` → affiche version de chaque repo
- `cortex upgrade --all` → upgrade tous les repos
- `cortex behaviors add "prove-before-fix"` → crée un behavior
- `cortex inject <repo>` → injecte behaviors + mémoire dans le CLAUDE.md du repo

**Avantages :** Simple, rapide à implémenter, pas de dépendance UI, scriptable
**Inconvénients :** Pas de dashboard visuel, pas de notifications push

### Architecture B — macOS Menubar App (Electron/Tauri)

```
Genius Cortex.app
├── Menubar icon (cerveau 🧠)
│   ├── Quick status de tous les repos
│   ├── Notification badge si outdated
│   └── Click → ouvre le dashboard
├── Dashboard window
│   ├── Liste des repos + statuts
│   ├── Activity feed
│   ├── Behaviors editor
│   └── Memory viewer
└── Background daemon
    ├── Watch filesystem pour nouveaux repos
    ├── Check GT versions périodiquement
    └── Inject behaviors au launch de Claude Code
```

**Avantages :** Visuellement riche, notifications natives, toujours visible
**Inconvénients :** Plus complexe à maintenir, Electron = lourd, Tauri = moins mature

### Architecture C — Hybrid (CLI + Web Dashboard local)

```
cortex daemon → runs on localhost:4200
cortex CLI    → scriptable commands
Web UI        → http://localhost:4200 dashboard
```

**Comment ça marche :**
- CLI pour les commandes rapides (`cortex status`, `cortex upgrade`)
- Daemon local qui watche les repos et sert un dashboard web
- Dashboard accessible dans le navigateur — pas besoin d'app native
- Notifications via Claude Channels (Telegram/Discord)

**Avantages :** Best of both worlds — CLI rapide + dashboard riche, pas de dépendance Electron
**Inconvénients :** Daemon à gérer, port local

### Architecture D — Claude Code Plugin (MCP Server)

```
genius-cortex-mcp/
├── server.ts            # MCP server
├── tools/
│   ├── cortex-status.ts
│   ├── cortex-upgrade.ts
│   ├── cortex-behaviors.ts
│   └── cortex-memory.ts
└── package.json
```

**Comment ça marche :**
- Cortex est un MCP server que tu ajoutes à Claude Code
- Depuis n'importe quelle session CC, tu peux appeler les outils Cortex
- "cortex_status" → montre tous tes repos
- "cortex_inject_behaviors" → charge les behaviors dans la session
- Fonctionne aussi via Claude Channels (Telegram)

**Avantages :** Intégration native CC, pas d'app séparée, fonctionne partout où CC tourne
**Inconvénients :** Pas de dashboard standalone, dépend de CC

### Architecture E — OpenClaw Plugin

```
~/.openclaw/extensions/genius-cortex/
├── SKILL.md
├── scripts/
│   ├── scan.sh
│   ├── status.sh
│   ├── upgrade.sh
│   └── inject.sh
└── memory/
```

**Comment ça marche :**
- Cortex comme skill OpenClaw
- Accessible depuis Discord/Telegram via Echo
- "genius-cortex status" → statut de tous les repos
- Dashboard via OpenClaw Canvas
- Mémoire centralisée dans OpenClaw memory

**Avantages :** Déjà dans ton écosystème, accessible mobile, pas d'install supplémentaire
**Inconvénients :** Dépend d'OpenClaw, pas standalone

---

## 4. Recommandation

### MVP recommandé : **Architecture C (CLI + Web Dashboard) avec brique MCP**

Pourquoi :
1. **CLI** = base solide, testable, scriptable, pas de dépendance UI
2. **Web dashboard local** = visuellement riche sans la lourdeur d'Electron
3. **MCP server inclus** = intégration native avec Claude Code
4. **Notifications via Channels** = alertes sur Telegram/Discord, pas besoin d'app native

### Stack suggéré :
- **CLI** : Node.js (même stack que GT, facilite la maintenance)
- **Dashboard** : HTML/CSS/JS statique servi par le daemon (comme les playgrounds GT)
- **MCP** : TypeScript (standard MCP SDK)
- **Config** : JSON + Markdown (cohérent avec GT)

### MVP Scope :
1. `cortex scan` → trouve les repos
2. `cortex status` → versions + santé
3. `cortex upgrade [--all]` → mise à jour
4. `cortex behaviors` → CRUD behaviors
5. `cortex dashboard` → ouvre le dashboard web local
6. MCP server pour intégration CC

---

## 5. Behaviors System — Design détaillé

### Format d'un behavior :
```markdown
---
name: prove-before-fix
category: debugging
priority: high
description: Always prove the hypothesis before attempting a fix
---

## Rule

When encountering a bug:
1. **READ** the relevant code first
2. **REPRODUCE** the issue with a concrete test or command
3. **PROVE** the root cause with evidence (logs, traces, test output)
4. Only THEN attempt a fix

## Anti-pattern
❌ "I think the bug is in X, let me change it and see"
✅ "The error trace shows X calls Y which returns null because Z. Here's the proof: [output]"
```

### Injection mechanism :
- Au lancement d'une session GT, Cortex injecte les behaviors actifs dans `~/.claude/CLAUDE.md` (user-level)
- Claude Code charge automatiquement `~/.claude/CLAUDE.md` dans toutes les sessions
- Les behaviors sont donc actifs PARTOUT sans modifier chaque repo

### Bibliothèque de départ :
1. `prove-before-fix` — prouver avant de corriger
2. `post-fix-audit` — audit post-correction
3. `read-before-write` — lire le code existant avant de modifier
4. `test-the-fix` — vérifier que la correction marche + pas de régression
5. `ask-dont-assume` — demander au lieu de supposer
6. `minimal-change` — modifier le minimum nécessaire
7. `explain-then-code` — expliquer l'approche avant de coder

---

## 6. Scores & Next Steps

### Évaluation de cette proposition :
- Complétude des features : 8/10 (manque détail implémentation)
- Faisabilité technique : 9/10 (stack connue, pas de magie)
- Différenciation marché : 8/10 (Conductor = multi-agent, Cortex = multi-repo + behaviors)
- Alignement vision Ben : 9/10 (couvre tous les points du brief audio)
- Effort MVP : ~2-3 semaines dev

### Ce qui reste à décider :
1. Architecture finale (reco C, mais Ben peut préférer)
2. Nom définitif (Genius Cortex ?)
3. Priorité features pour le MVP
4. Open source ou pas ?
5. Package manager (npm global ? Homebrew ?)
