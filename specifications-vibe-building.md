# Genius Team Platform — Vibe Building Specifications
**Version:** 1.0 — Draft
**Date:** 2026-02-18
**Auteur:** Ben Bellity + Echo (AI)

---

## Vision

> **"Vibe Building : de l'idée au lancement, en équipe, orchestré par l'AI."**

**Vibe Coding** = un dev + une AI pour coder vite.
**Vibe Building** = une équipe complète + des AIs spécialisées pour construire un produit de A à Z — de l'idéation au déploiement.

Genius Team est aujourd'hui le meilleur outil de Vibe Building pour une personne seule. La plateforme est l'extension naturelle pour les équipes — sans exclure les non-techniciens, en les incluant dans leur langage métier.

---

## Concept Clé : Le Cerveau Partagé

Chaque membre de l'équipe a son AI pair. Toutes les AIs partagent le même contexte de projet (`shared state`). Le CEO parle vision. Le marketer parle audience. Le dev parle code. L'AI orchestre et traduit.

```
SHARED PROJECT BRAIN (state.json)
         │
┌────────┼────────┬────────┬────────┐
▼        ▼        ▼        ▼        ▼
CEO    Designer  Marketer   Dev     PM
+ AI   + AI      + AI     + AI    + AI
Vision  UX/UI   Messaging  Code  Roadmap
```

---

## 1. Onboarding & Gestion d'Équipe

### 1.1 Création de compte
- Email/password + OAuth (Google, GitHub)
- Profil : nom, rôle (`founder`, `designer`, `marketer`, `dev`, `pm`, `qa`)
- Le rôle conditionne l'interface, les agents IA assignés, et les permissions

### 1.2 Création d'équipe & projet
1. Le fondateur crée une équipe + un projet sur genius.w3art.io
2. Invitation des membres par email (lien tokenisé, expire en 72h)
3. Chaque membre choisit son rôle à l'inscription
4. Setup des clés IA (voir section 2)

### 1.3 Gestion des permissions

| Permission | Owner | Admin | Member |
|------------|-------|-------|--------|
| Inviter des membres | ✅ | ✅ | ❌ |
| Modifier les settings | ✅ | ✅ | ❌ |
| Déployer | ✅ | ✅ | ❌ |
| Contribuer aux phases | ✅ | ✅ | ✅ |
| Voter | ✅ | ✅ | ✅ |
| Voir le terminal | ✅ | ✅ | ✅ (read-only) |
| Contrôler le terminal | ✅ | ✅ | ❌ |

---

## 2. Gestion des Clés IA

### 2.1 Mode v1 : BYO Keys (Bring Your Own)

Chaque utilisateur entre ses propres clés API :
- **Claude Code** → clé Anthropic API
- **Codex CLI** → clé OpenAI API
- Les clés sont chiffrées (AES-256) et ne transitent jamais en clair

### 2.2 Programme "Free Credits" (partenariat)

Au lieu de revendre des tokens (risque légal), la plateforme :
- Se positionne comme **canal d'acquisition partenaire** d'Anthropic et OpenAI
- Négocie des **crédits offerts** pour les nouvelles équipes (ex: $50 de crédits Claude à l'inscription)
- Génère des revenus via l'onboarding premium et les services (voir section 8)

### 2.3 Choix du moteur par phase

```
Phase Discovery   → Claude ou Codex (configurable)
Phase Market      → Claude ou Codex
Phase Dev         → Claude Code OU Codex CLI OU Dual Mode
Phase Review      → Dual Mode recommandé (Claude build, Codex challenge)
```

---

## 3. Interface Chat — genius-bot (Telegram)

### 3.1 Création assistée du chat d'équipe

1. Fondateur clique "Créer le chat équipe" sur la plateforme
2. La plateforme crée un groupe Telegram privé automatiquement
3. Tous les membres invités sont ajoutés
4. @genius-bot est ajouté et se présente en tant qu'orchestrateur

### 3.2 Architecture des bots

```
@genius-bot (orchestrateur)
  ├── @genius-interviewer-bot   → Phase Discovery (questions, reformulations)
  ├── @genius-market-bot        → Phase Market (analyse, insights)
  ├── @genius-design-bot        → Phase Design (UX guidance, system design)
  ├── @genius-dev-bot           → Phase Dev (code snippets, architecture)
  ├── @genius-qa-bot            → Phase QA (test scenarios, critères)
  └── @genius-vote-bot          → Votes & consensus
```

**Comportement :**
- @genius-bot anime et oriente la discussion selon la phase active
- Chaque bot est invoqué automatiquement quand sa phase commence
- Les bots lisent le `shared state` pour contextualiser leurs réponses
- Support voice notes → transcription auto → réponse IA

### 3.3 Interactions typiques

```
👤 Marie (Designer): "Je veux un design épuré, inspiré d'Apple"
🤖 @genius-design-bot: "Parfait. Pour un style Apple-like, voici 
   les principes clés pour votre projet TaskFlow : [...]
   Je mets à jour le Design System dans le dashboard."

👤 Thomas (CEO): "On devrait plutôt cibler les PME"
🤖 @genius-market-bot: "Thomas, j'analyse... 83% des utilisateurs 
   actuels en découverte correspondent au profil PME.
   Je soumets une révision de l'ICP à l'équipe. /vote lancé."
```

---

## 4. Système de Consensus & Votes

### 4.1 Paramètre Consensus

Configurable par projet :
```
consensus_mode: "human" | "bot"
```

- **human** : Le Lead désigné tranche. Le bot présente les arguments de chaque camp de façon synthétique.
- **bot** : L'AI tranche sur la base des specs, des meilleures pratiques, et du contexte projet.

### 4.2 Mécanisme de vote

Déclenché par `@genius-vote-bot` ou par n'importe quel membre :

```
/vote "Stack frontend : Next.js ou Nuxt.js ?"
→ Options : Next.js · Nuxt.js · M'en remettre à l'AI
→ Timer : 2h (configurable)
→ Quorum : 50%+1 (configurable)
→ Si timer expiré sans quorum → consensus_mode prend le relai
```

**Types de votes :**
- Choix technique (stack, architecture, tooling)
- Priorité feature (que build-on en premier ?)
- Validation de phase (passage à l'étape suivante)
- Décision business (pricing, pivot, cible)

**Résultat :** Automatiquement logué dans `shared/decisions.json` avec rationale et historique des votes.

---

## 5. Dashboard Web

### 5.1 Vue d'ensemble

Interface web accessible par tous les membres depuis n'importe quel navigateur. Aucune installation requise. Mis à jour en temps réel via WebSocket.

### 5.2 Onglets — Phases Genius Team

```
[🎯 Discovery] [📊 Market] [📋 Specs] [🎨 Design] [💻 Dev] [🧪 QA] [🚀 Deploy]
```

Chaque onglet affiche le **playground complet** de la phase (pas un résumé) :
- Indicateur live : "Qui travaille dessus maintenant" (avatars)
- Historique des contributions par membre
- Bouton "Demander révision" → notif dans le chat Telegram
- Statut : Pending · In Progress · In Review · Completed

### 5.3 Vues additionnelles

**🗺️ Team Map**
- Qui fait quoi en ce moment
- Disponibilité de chaque membre
- Tâches assignées vs en attente

**📊 Project Progress**
- % completion par phase
- Timeline estimée vs réelle
- Velocity de l'équipe

**💬 Decisions Log**
- Toutes les décisions prises (manuelles + AI)
- Contexte, date, décideur
- Possibilité de revenir en arrière (revert decision)

**🗳️ Votes actifs**
- Votes en cours avec countdown
- Résultats des votes passés

---

## 6. Web CLI — Terminal Intégré

### 6.1 Philosophie

Le terminal n'est pas caché aux non-techniciens — il est **visible en mode spectateur**. Voir l'AI coder en temps réel crée le "WOW moment" qui engage les membres non-techniques.

```
Non-tech member → Voit le terminal live (read-only)
                → Voit l'AI générer du code
                → "Take Control" button disponible
                → WOW moment + sentiment d'ownership
```

### 6.2 Stack technique

```
Frontend : xterm.js (terminal emulator)
Backend  : node-pty (pseudo-terminal côté serveur)
Protocole: WebSocket (bidirectionnel)
Container: Sandbox isolé par projet (Docker ou VM légère)
```

### 6.3 Fonctionnement

- Terminal complet dans le browser
- Claude Code ou Codex CLI pré-installés dans le container
- Le repo du projet est pré-cloné
- Accès en écriture : `dev` et `lead` uniquement
- Accès en lecture (live view) : tous les membres
- Push/pull git intégré avec feedback visuel

### 6.4 Visible dans

- Onglet **Dev** du dashboard (principal)
- Panel rétractable sur tous les autres onglets pour les devs

---

## 7. Déploiement & Setup Externe

### 7.1 Mode Guidé (Guide-Me)

La plateforme guide l'équipe pas-à-pas pour configurer les services externes :

```
Étape 1 : GitHub → Créer repo + push code initial
Étape 2 : Vercel → Connecter repo + premier déploiement frontend
Étape 3 : Railway → Provisionner backend + base de données
Étape 4 : Stripe → Configurer les paiements (si applicable)
Étape 5 : Resend/Loops → Email transactionnel
```

Chaque étape : instructions illustrées + validation automatique quand c'est fait.

### 7.2 Mode Autopilot (Clé-en-Main)

La plateforme agit via OAuth sur les services externes :

```
OAuth GitHub → Créer repo, configurer branch protection, add collaborators
OAuth Vercel → Créer projet, setup domaine custom, env variables
OAuth Railway → Provision DB, déployer backend, setup secrets
```

L'utilisateur autorise une seule fois chaque service. La plateforme gère le reste.

**Résultat :** L'équipe reçoit les URLs de prod + les credentials dans un dashboard sécurisé.

---

## 8. Modèle de Revenus (v1)

| Source | Description | Montant estimé |
|--------|-------------|----------------|
| 💰 **Abonnement plateforme** | Freemium → Team → Pro | 0 / 49€ / 99€/mois |
| 🤝 **Onboarding premium** | Setup complet accompagné par l'équipe | 299-999€ one-shot |
| 🎓 **Vibe Building bootcamp** | Formation équipe (4h, async ou live) | 199€/participant |
| 🔌 **Setup Autopilot** | Configuration clé-en-main tous services | 199-499€ one-shot |
| 🤝 **Partenariat Anthropic/OpenAI** | Crédits offerts aux nouveaux users via deal partenaire | TBD |

### Plans

| Plan | Prix | Limites |
|------|------|---------|
| **Free** | 0€ | 1 projet · 3 membres · BYO keys |
| **Team** | 49€/mois | 5 projets · 10 membres · BYO keys |
| **Pro** | 99€/mois | Projets illimités · Membres illimités · Autopilot deploy |
| **Enterprise** | Sur devis | White-label · SLA · Support dédié |

---

## 9. Stack Technique

```
Frontend    : Next.js 15 (App Router) + Tailwind
Backend     : Node.js + Fastify (API) + WebSocket
Database    : Supabase (PostgreSQL + Auth + Realtime + Storage)
Auth        : Supabase Auth (email + OAuth Google/GitHub)
Telegram    : Grammy.js (bots multi-instances)
Web CLI     : xterm.js + node-pty + WebSocket
AI Layer    : Anthropic SDK + OpenAI SDK (routing selon config user)
Real-time   : Supabase Realtime (dashboard) + Socket.io (terminal)
Containers  : Docker (sandbox Web CLI par projet)
Deploy      : Vercel (frontend) + Railway (backend + bots + containers)
Paiements   : Stripe (abonnements + one-shots)
Email       : Resend (invitations, notifications)
```

---

## 10. Modèle de Données

```
User
  ├── id, email, name, role
  └── api_keys (chiffrées)

Team
  ├── id, name, owner_id
  └── members → User[] (via Membership)

Project
  ├── id, team_id, name, engine (claude|codex|dual)
  ├── consensus_mode (human|bot)
  ├── current_phase
  └── phases → Phase[]

Phase
  ├── id, project_id, type (discovery|market|specs|...)
  ├── status (pending|in-progress|review|completed)
  ├── assigned_to → User[]
  └── artifacts → Artifact[]

Artifact
  ├── id, phase_id, type, content (JSON)
  └── created_by (human|ai), created_at

Decision
  ├── id, project_id, question, outcome
  ├── decided_by (user_id | "ai")
  └── context, created_at

Vote
  ├── id, project_id, question, options[]
  ├── timer_ends_at, quorum
  ├── status (active|resolved|expired)
  └── votes → VoteChoice[]

Message
  ├── id, project_id, source (telegram|platform)
  ├── sender (user_id | bot_name)
  └── content, created_at
```

---

## 11. Ce qu'on a déjà (réutilisable)

| Asset | Réutilisé comment |
|-------|-------------------|
| `project-dashboard.html` | Base du Dashboard Web (portée en React) |
| 12 playgrounds HTML | Onglets du dashboard |
| `state.json` schema | Modèle de données Project/Phase |
| 25 skills Genius Team | Logique des bots Telegram |
| xterm.js (Jarvis) | Web CLI intégré |
| `genius-dual-engine` skill | Mode Dual pour la phase Dev |
| Scripts `create.sh` / `setup.sh` | Onboarding Autopilot |

---

## 12. Roadmap

### v1 — "Founder + Dev" (MVP)
- [ ] Auth + teams + invitations
- [ ] Shared state en temps réel
- [ ] Dashboard avec 7 onglets (phases)
- [ ] Telegram bot (genius-bot orchestrateur)
- [ ] BYO API keys
- [ ] Web CLI (read-only spectateur + contrôle dev)

### v2 — "Full Team"
- [ ] Bots spécialisés par phase
- [ ] Système de votes
- [ ] Mode Dual intégré dans le dashboard
- [ ] Deploy guidé (Guide-Me)

### v3 — "Scale"
- [ ] Deploy Autopilot
- [ ] Programme partenariat Anthropic/OpenAI
- [ ] Onboarding premium en libre-service
- [ ] Analytics & reporting

---

## Méta-note

La plateforme est elle-même buildée en **Vibe Building** — en utilisant Genius Team pour se construire. C'est le meilleur demo possible et le meilleur argument marketing : **"On a buildé cette plateforme avec notre propre outil."**

---

*Document vivant — à mettre à jour au fil des décisions d'équipe.*
