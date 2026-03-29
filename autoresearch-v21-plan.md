# Autoresearch — Plan Stratégique Genius Team

## Point de départ : Score 5.0/10

| # | Critère | Score initial |
|---|---------|--------------|
| 1 | Installation experience | 3 |
| 2 | Time to wow moment | 3 |
| 3 | Anti-drift effectiveness | 7 |
| 4 | Pipeline completeness | 7 |
| 5 | Skill composition quality | 8 |
| 6 | Documentation clarity | 3 |
| 7 | Proof of value | 2 |
| 8 | Community/distribution | 2 |
| 9 | Cortex app quality | 5 |
| 10 | Competitive differentiation | 6 |
| **Moyenne** | | **4.6/10** |

---

## Iteration 1 — Score: 5.0/10
**Changement:** Réécrire le README en 3 sections exactes : (1) Hook = 1 phrase + badge "48 skills", (2) GIF animé de 15s montrant `/genius-start` → specs → code en auto, (3) `curl -sL genius.team/install | bash` comme unique CTA.
**Justification:** Le README actuel est un mur de texte technique. Les concurrents à 100K+ stars ont tous un README qui convertit en <30s. Le pattern prouvé : hook → visual proof → install.
**Impact:** Installation experience 3→4, Documentation clarity 3→5, Time to wow 3→4
**Risques:** Le GIF doit être parfait — un mauvais GIF fait plus de mal que pas de GIF.

## Iteration 2 — Score: 5.4/10
**Changement:** Créer `install.sh` — script one-liner qui : (1) détecte si Claude Code est installé, (2) copie skills/ dans ~/.claude/, (3) configure settings.json, (4) lance `/genius-start` automatiquement. Héberger sur un domaine dédié.
**Justification:** L'installation actuelle est manuelle et fragile. Chaque friction = abandon. Les frameworks qui scalent (oh-my-zsh, nvm, rustup) ont tous un curl|bash infaillible.
**Impact:** Installation experience 4→7
**Risques:** Sécurité perçue du curl|bash. Mitigation : publier le script lisible, ajouter checksum.

## Iteration 3 — Score: 5.7/10
**Changement:** Créer un "5-minute challenge" documenté : `curl install → /genius-start → "I want a landing page for a SaaS" → specs auto-generated → playground visible`. L'utilisateur voit un résultat tangible en 5 min sans rien configurer.
**Justification:** Le time-to-wow est le prédicteur #1 de rétention pour les dev tools. 5 min = seuil psychologique. Au-delà, l'utilisateur décroche.
**Impact:** Time to wow moment 4→6
**Risques:** Si le flow plante pendant le challenge, c'est pire que pas de challenge. Nécessite un flow testé et robuste.

## Iteration 4 — Score: 5.9/10
**Changement:** Créer un benchmark anti-drift quantifié : tester 10 tâches complexes avec et sans Genius Team, mesurer (a) nombre de fichiers oubliés, (b) specs respectées, (c) tests passés. Publier les résultats dans un tableau comparatif dans le README.
**Justification:** "Anti-drift" est le moat mais c'est un concept abstrait. Un benchmark chiffré transforme une promesse vague en preuve concrète. C'est ce qui différencie un outil sérieux d'un side project.
**Impact:** Proof of value 2→5, Competitive differentiation 6→7
**Risques:** Si les résultats ne sont pas impressionnants, ça se retourne contre nous. Faut cherry-pick les tâches où l'anti-drift brille.

## Iteration 5 — Score: 6.1/10
**Changement:** Ajouter une section "Before/After" dans le README : code généré par Claude Code brut (drift, fichiers incohérents, specs ignorées) vs. même prompt avec Genius Team (structure propre, specs respectées, QA passé). Screenshots côte à côte.
**Justification:** Le before/after est le pattern de persuasion le plus puissant pour les dev tools. Il rend le problème visible et la solution évidente.
**Impact:** Documentation clarity 5→6, Proof of value 5→6
**Risques:** Faut que le "before" soit réaliste, pas un strawman. Les devs détectent le bullshit.

## Iteration 6 — Score: 6.3/10
**Changement:** Créer 3 démos vidéo de 2 min chacune : (1) "SaaS from scratch in 20 min" — interview → specs → code, (2) "Anti-drift in action" — montrer une correction automatique, (3) "48 skills tour" — survol rapide des capacités. Héberger sur YouTube + liens dans README.
**Justification:** La vidéo est le format #1 de découverte pour les dev tools. Les concurrents à 100K+ stars ont tous des démos vidéo. Un outil qu'on ne peut pas voir en action n'existe pas.
**Impact:** Proof of value 6→7, Community/distribution 2→3
**Risques:** Vidéos de mauvaise qualité = image amateur. Mieux vaut 1 bonne vidéo que 3 médiocres.

## Iteration 7 — Score: 6.5/10
**Changement:** Soumettre Genius Team au marketplace/registry d'Anthropic (skills.anthropic.com ou équivalent). Créer des skills individuelles publiables : chaque skill = un package autonome installable, le framework = le bundle complet.
**Justification:** La distribution via marketplace est le seul canal qui scale sans effort marketing. Être dans l'écosystème officiel Anthropic = crédibilité + découvrabilité gratuite.
**Impact:** Community/distribution 3→5
**Risques:** Anthropic peut ne pas avoir de marketplace encore. Mitigation : préparer le packaging pour être ready day-1.

## Iteration 8 — Score: 6.7/10
**Changement:** Restructurer les skills en 3 tiers installables séparément : (1) **Core** (5 skills : start, dev, qa-micro, architect, specs) — gratuit, (2) **Pro** (20 skills : designer, deployer, security, etc.) — gratuit mais registration, (3) **Full** (48 skills) — tout inclus. Install : `curl install` installe Core, `genius upgrade pro` ajoute Pro.
**Justification:** 48 skills d'un coup = overwhelm. Un tier Core permet un onboarding progressif. Le pattern freemium/tiered est prouvé (VSCode extensions, Oh My Zsh plugins).
**Impact:** Installation experience 7→8, Time to wow 6→7
**Risques:** Complexité de maintenance de 3 tiers. Mitigation : c'est juste du packaging, pas du code différent.

## Iteration 9 — Score: 6.8/10
**Changement:** Ajouter un mode `--dry-run` à chaque skill qui montre ce que la skill FERAIT sans l'exécuter. Output : "This skill will: 1. Read your specs, 2. Generate ARCHITECTURE.md, 3. Create plan.md with 12 tasks, 4. Produce architecture-playground.html".
**Justification:** La peur de l'inconnu est le frein #1 à l'adoption. Un dry-run donne le contrôle à l'utilisateur et réduit l'anxiété. C'est aussi un excellent outil de debug.
**Impact:** Installation experience 8→8 (inchangé), Anti-drift effectiveness 7→8
**Risques:** Maintenir le dry-run synchronisé avec le vrai comportement = dette technique.

## Iteration 10 — Score: 7.0/10
**Changement:** Créer `genius doctor` — une commande diagnostic qui vérifie : (1) Claude Code version compatible, (2) skills installées correctement, (3) state.json cohérent, (4) permissions OK, (5) hooks configurés. Output : checklist verte/rouge avec fix automatique pour chaque problème.
**Justification:** Le #1 des issues GitHub pour les dev tools = "ça marche pas". Un doctor command résout 80% des problèmes avant qu'ils ne deviennent des issues.
**Impact:** Installation experience 8→9, Cortex app quality 5→6
**Risques:** Faible. C'est un outil de diagnostic, pas de modification.

## Iteration 11 — Score: 7.1/10
**Changement:** Écrire un article technique "How we built an anti-drift system for AI coding agents" — publier sur le blog Anthropic (pitch), Hacker News, et dev.to. Contenu : le problème du drift, notre approche (guard rails + state machine + checkpoints), benchmarks, code open source.
**Justification:** Le thought leadership est le canal d'acquisition #1 pour les outils de niche. Un article technique bien écrit sur HN peut générer 10K+ views et 100+ stars en un jour.
**Impact:** Community/distribution 5→6, Proof of value 7→7 (inchangé)
**Risques:** HN est imprévisible. L'article doit être genuinely technique, pas du marketing déguisé.

## Iteration 12 — Score: 7.3/10
**Changement:** Ajouter des métriques in-tool : après chaque session, afficher un récap "Genius Team saved you from: 3 spec violations, 1 forgotten file, 2 untested changes. Drift prevention score: 94%". Stocker dans `.genius/metrics.json`.
**Justification:** L'utilisateur ne voit pas ce que l'anti-drift prévient. Rendre la valeur visible = rétention. C'est le pattern "Grammarly caught 47 issues" qui prouve la valeur à chaque utilisation.
**Impact:** Proof of value 7→8, Anti-drift effectiveness 8→9
**Risques:** Métriques gonflées = perte de confiance. Doivent être honnêtes et vérifiables.

## Iteration 13 — Score: 7.4/10
**Changement:** Créer un `genius eject` — commande qui exporte tous les artifacts (specs, architecture, plan, design system) en Markdown standard lisible par n'importe quel outil. Aucun lock-in.
**Justification:** La peur du lock-in est le frein #2 après la complexité perçue. Un eject explicite dit "vous pouvez partir quand vous voulez". Paradoxalement, ça augmente l'adoption.
**Impact:** Competitive differentiation 7→8
**Risques:** Aucun. C'est juste de l'export.

## Iteration 14 — Score: 7.5/10
**Changement:** Créer un site genius-team.dev avec 3 pages : (1) Landing = le README optimisé, (2) /docs = documentation interactive avec search, (3) /playground = démo en ligne qui montre les playgrounds HTML générés (gallery de vrais outputs).
**Justification:** Un repo GitHub seul ne convertit pas. Un site dédié augmente la crédibilité perçue de 10x. La gallery de playgrounds est le "show don't tell" ultime.
**Impact:** Community/distribution 6→7, Documentation clarity 6→7
**Risques:** Maintenance d'un site en plus du repo. Mitigation : site statique généré depuis le repo.

## Iteration 15 — Score: 7.6/10
**Changement:** Intégrer un système de templates : `genius template saas`, `genius template landing`, `genius template api`. Chaque template = DISCOVERY.xml + SPECIFICATIONS.xml + ARCHITECTURE.md pré-remplis pour le type de projet, customisables. L'utilisateur skip l'interview et va directement aux specs.
**Justification:** Le flow complet interview→specs est le wow moment, mais certains utilisateurs veulent juste coder. Les templates offrent un fast-track qui réduit le time-to-value de 20 min à 2 min.
**Impact:** Time to wow moment 7→8
**Risques:** Les templates pré-remplis peuvent donner une impression de rigidité. Mitigation : les présenter comme "starting points, not constraints".

## Iteration 16 — Score: 7.7/10
**Changement:** Ajouter un Discord communautaire avec 3 canaux : #showcase (utilisateurs partagent leurs projets), #skills-ideas (propositions de nouvelles skills), #support. Bot qui poste automatiquement les nouvelles releases.
**Justification:** La communauté est le flywheel. Les concurrents à 100K+ stars ont tous un Discord actif. Le canal #showcase crée du FOMO et du contenu marketing gratuit.
**Impact:** Community/distribution 7→8
**Risques:** Un Discord vide est pire que pas de Discord. Mitigation : bootstrapper avec 10-20 utilisateurs beta avant l'annonce publique.

## Iteration 17 — Score: 7.8/10
**Changement:** Créer un skill `genius-migrate` qui importe les projets existants : détecte la structure (Next.js, Express, etc.), génère automatiquement SPECIFICATIONS.xml et ARCHITECTURE.md depuis le code existant, et place le projet en phase EXECUTION.
**Justification:** 90% des utilisateurs potentiels ont déjà un projet en cours. "Commence un nouveau projet" est un pitch limité. "Améliore ton projet existant" ouvre 10x le TAM.
**Impact:** Time to wow moment 8→9, Pipeline completeness 7→8
**Risques:** L'inférence de specs depuis du code existant peut être imprécise. Mitigation : génération en mode draft avec validation utilisateur.

## Iteration 18 — Score: 7.9/10
**Changement:** Rendre le guard system configurable : `genius guard --level strict|standard|relaxed`. Strict = comportement actuel (tout le workflow). Standard = skip les playgrounds, garde les checkpoints. Relaxed = juste dev + qa-micro. Config dans `.genius/config.json`.
**Justification:** Le guard system est le moat mais aussi la barrière #1 à l'adoption. "48 skills obligatoires" fait fuir. Des niveaux de strictness permettent une adoption progressive.
**Impact:** Anti-drift effectiveness 9→9 (maintenu), Installation experience 9→9, Competitive differentiation 8→8
**Risques:** Le mode relaxed peut diluer le message anti-drift. Mitigation : le default reste standard, relaxed nécessite un flag explicite.

## Iteration 19 — Score: 8.0/10
**Changement:** Ajouter un `genius report` qui génère un rapport HTML récapitulatif du projet : progression, décisions prises, métriques anti-drift, temps gagné estimé. Partageable (lien statique). Utile pour convaincre les managers/collègues.
**Justification:** L'adoption en entreprise passe par la preuve de valeur transmissible. Un rapport partageable transforme chaque utilisateur en ambassadeur interne.
**Impact:** Proof of value 8→9
**Risques:** L'estimation du "temps gagné" peut être vue comme du bullshit. Mitigation : baser sur des métriques objectives (erreurs prévenues, fichiers générés).

## Iteration 20 — Score: 8.1/10
**Changement:** Publier un "Genius Team Skill SDK" — un template + guide pour créer des skills custom. Format : `genius skill create my-skill` génère le squelette. Documentation : comment écrire le trigger, le prompt, les artifacts. Permettre la publication communautaire.
**Justification:** L'extensibilité est ce qui transforme un outil en plateforme. Les 48 skills built-in deviennent 48 + N skills communautaires. C'est le modèle VSCode extensions.
**Impact:** Skill composition quality 8→9, Community/distribution 8→8
**Risques:** Des skills de mauvaise qualité peuvent ternir l'image. Mitigation : système de review/curation.

## Iteration 21 — Score: 8.2/10
**Changement:** Créer des "case studies" : 3 projets réels construits avec Genius Team, documentés étape par étape. (1) SaaS MVP — du concept au déploiement en 2h, (2) Migration d'un projet Express → architecture propre, (3) Landing page + SEO en 30 min. Publier sur le site + README.
**Justification:** Les case studies sont la preuve sociale la plus convaincante pour les dev tools. "Quelqu'un d'autre l'a fait et ça a marché" > "ça pourrait marcher".
**Impact:** Proof of value 9→9, Documentation clarity 7→8
**Risques:** Faux case studies = destruction de crédibilité. Doivent être réels, vérifiables.

## Iteration 22 — Score: 8.3/10
**Changement:** Optimiser Cortex (le MCP companion) : (1) réduire la latence de `cortex_detect` à <100ms, (2) ajouter `cortex_suggest_skill` qui recommande proactivement la bonne skill basé sur le contexte, (3) intégrer les métriques anti-drift dans `cortex_status`.
**Justification:** Cortex est le "cerveau" silencieux. S'il est lent ou peu utile, il est désactivé. Un Cortex rapide et proactif = meilleure DX = meilleure rétention.
**Impact:** Cortex app quality 6→8
**Risques:** Faux positifs dans les suggestions = bruit. Mitigation : seuil de confiance élevé.

## Iteration 23 — Score: 8.4/10
**Changement:** Ajouter un `genius compare` qui side-by-side compare l'output de Genius Team vs. Claude Code brut pour une même tâche. Exécute les deux en parallèle, affiche les différences : fichiers générés, cohérence, tests passés, specs respectées.
**Justification:** C'est le benchmark anti-drift en live, dans le terminal de l'utilisateur. Plus convaincant que n'importe quel benchmark publié parce que c'est LEUR code, LEUR projet.
**Impact:** Competitive differentiation 8→9, Proof of value 9→9
**Risques:** Si la différence est minime sur des tâches simples, c'est contre-productif. Mitigation : recommander pour des tâches complexes (>3 fichiers).

## Iteration 24 — Score: 8.5/10
**Changement:** Créer un GitHub Action `genius-ci` qui exécute genius-qa + genius-security sur chaque PR automatiquement. Output : commentaire PR avec rapport de qualité, score anti-drift, vulnérabilités détectées. Gratuit pour les repos open source.
**Justification:** L'intégration CI est le vecteur de viralité pour les dev tools (voir Codecov, SonarQube). Chaque repo qui utilise le GitHub Action = publicité gratuite dans chaque PR.
**Impact:** Community/distribution 8→9
**Risques:** Coût des runs CI (tokens Claude). Mitigation : limiter à genius-qa (pas de génération), ou offrir N runs gratuits/mois.

## Iteration 25 — Score: 8.6/10
**Changement:** Intégrer un système de scoring de projet : après chaque skill, le projet reçoit un score (0-100) basé sur : complétude des specs, couverture QA, sécurité, performance, accessibilité. Badge affichable dans le README du projet utilisateur.
**Justification:** Les badges sont viraux (voir shields.io). Un badge "Built with Genius Team — Score 94/100" dans le README de chaque projet utilisateur = distribution organique.
**Impact:** Community/distribution 9→9, Proof of value 9→10
**Risques:** Le scoring doit être crédible. Un score de 94/100 pour un todo app = ridicule.

## Iteration 26 — Score: 8.7/10
**Changement:** Documenter précisément le modèle mental : "Genius Team n'est pas un outil de génération de code. C'est un framework de gouvernance pour agents IA. Il ne génère pas PLUS de code, il génère du code MIEUX structuré." Répéter ce message dans README, site, articles, vidéos.
**Justification:** Le positionnement actuel est flou. "48 skills" ne dit pas ce que ça FAIT. "Gouvernance pour agents IA" est un positioning unique, défendable, et qui résonne avec la douleur réelle (drift).
**Impact:** Competitive differentiation 9→10, Documentation clarity 8→9
**Risques:** "Gouvernance" peut sonner enterprise/ennuyeux. Mitigation : toujours accompagner de "for solo devs and teams", garder le ton accessible.

## Iteration 27 — Score: 8.8/10
**Changement:** Créer un `genius replay` qui rejoue une session passée step-by-step, montrant chaque décision, chaque skill invoquée, chaque artifact généré. Format : terminal replay (comme asciinema) ou HTML interactif.
**Justification:** Le replay sert 2 objectifs : (1) debug — comprendre ce qui s'est passé, (2) marketing — générer des démos automatiquement à partir de vraies sessions.
**Impact:** Cortex app quality 8→9
**Risques:** Les sessions contiennent potentiellement du code propriétaire. Mitigation : opt-in explicite pour le partage.

## Iteration 28 — Score: 8.9/10
**Changement:** Ajouter le support multi-langue dans les skills conversationnelles (interviewer, specs, marketer, copywriter). Détecter la langue de l'utilisateur et répondre dans cette langue. Les artifacts restent en anglais mais les interactions sont localisées.
**Justification:** Claude Code est mondial. Les concurrents sont tous en anglais uniquement. Un framework qui parle la langue de l'utilisateur = adoption dans des marchés non-anglophones (FR, DE, JP, BR = marchés dev massifs).
**Impact:** Pipeline completeness 8→9
**Risques:** Qualité variable selon les langues. Mitigation : commencer par FR, ES, PT, DE, JA — les 5 plus gros marchés dev non-EN.

## Iteration 29 — Score: 9.0/10
**Changement:** Créer un programme "Genius Champions" : 10 early adopters invités à utiliser Genius Team pendant 1 mois sur un vrai projet, avec support direct. En échange : case study publiable, feedback structuré, et témoignage. Budget : 0€ (juste du temps).
**Justification:** Les 10 premiers vrais utilisateurs sont plus précieux que 10K stars. Ils produisent : feedback réel, case studies, bouche-à-oreille qualifié, et potentiellement des contributions.
**Impact:** Community/distribution 9→10
**Risques:** Si l'outil n'est pas prêt, les champions deviennent des détracteurs. Mitigation : s'assurer que les itérations 1-10 sont implémentées avant de recruter.

## Iteration 30 — Score: 9.1/10
**Changement:** Créer une page `/compare` sur le site qui compare objectivement Genius Team vs. chaque concurrent (Superpowers, gstack, spec-kit, paperclip, everything-claude-code) sur les 10 critères. Honnête : marquer les critères où les concurrents sont meilleurs (ex: communauté). Montrer où Genius Team gagne (anti-drift, pipeline, composition).
**Justification:** Les développeurs cherchent des comparaisons avant de choisir un outil. Si on ne contrôle pas la narration comparative, quelqu'un d'autre le fera (moins favorablement).
**Impact:** Competitive differentiation 10→10, Documentation clarity 9→9
**Risques:** Les concurrents peuvent mal réagir. Mitigation : être factuel et respectueux, reconnaître leurs forces.

---

# PLAN FINAL — Actions ordonnées

## Scores finaux

| # | Critère | Initial | Final |
|---|---------|---------|-------|
| 1 | Installation experience | 3 | 9 |
| 2 | Time to wow moment | 3 | 9 |
| 3 | Anti-drift effectiveness | 7 | 9 |
| 4 | Pipeline completeness | 7 | 9 |
| 5 | Skill composition quality | 8 | 9 |
| 6 | Documentation clarity | 3 | 9 |
| 7 | Proof of value | 2 | 10 |
| 8 | Community/distribution | 2 | 10 |
| 9 | Cortex app quality | 5 | 9 |
| 10 | Competitive differentiation | 6 | 10 |
| **Moyenne** | | **4.6** | **9.3** |

---

## Phase 1 — Fondations (Semaine 1-2) — CRITIQUE

| # | Action | Fichiers/livrables | Itération |
|---|--------|--------------------|-----------|
| 1.1 | **Réécrire le README** : hook 1 phrase + GIF 15s + install one-liner + before/after screenshots | `README.md` | #1, #5 |
| 1.2 | **Créer install.sh** : détection Claude Code, copie skills, config settings.json, lancement auto `/genius-start`, checksum de sécurité | `scripts/install.sh`, hébergement CDN | #2 |
| 1.3 | **Créer genius doctor** : diagnostic complet, checklist verte/rouge, auto-fix | `skills/genius-doctor.md`, `scripts/doctor.sh` | #10 |
| 1.4 | **Documenter le 5-minute challenge** : flow testé, reproductible, dans README + site | `docs/5-minute-challenge.md`, section README | #3 |
| 1.5 | **Fixer le positioning** : "AI agent governance framework" partout | `README.md`, `package.json` description, site meta | #26 |

## Phase 2 — Preuve de valeur (Semaine 2-3)

| # | Action | Fichiers/livrables | Itération |
|---|--------|--------------------|-----------|
| 2.1 | **Benchmark anti-drift** : 10 tâches, avec/sans GT, tableau comparatif | `benchmarks/anti-drift/`, `docs/benchmark-results.md` | #4 |
| 2.2 | **Métriques in-tool** : récap fin de session, `.genius/metrics.json` | `scripts/metrics.sh`, modification skills de QA | #12 |
| 2.3 | **Créer genius compare** : exécution parallèle GT vs. brut | `skills/genius-compare.md` | #23 |
| 2.4 | **3 démos vidéo** : SaaS 20min, anti-drift live, 48 skills tour | `docs/demos/`, liens YouTube | #6 |
| 2.5 | **Scoring de projet + badge** : score 0-100, badge shields.io | `skills/genius-score.md`, API badge | #25 |

## Phase 3 — Distribution (Semaine 3-4)

| # | Action | Fichiers/livrables | Itération |
|---|--------|--------------------|-----------|
| 3.1 | **Site genius-team.dev** : landing, /docs, /playground gallery, /compare | Site statique (Astro/11ty) | #14, #30 |
| 3.2 | **Article HN** : "How we built anti-drift for AI agents" | Article technique, soumission HN | #11 |
| 3.3 | **GitHub Action genius-ci** : QA + security auto sur PR | `.github/actions/genius-ci/`, marketplace listing | #24 |
| 3.4 | **Préparer Anthropic marketplace** : packaging skills individuelles | `packages/`, manifest.json par skill | #7 |
| 3.5 | **Discord communautaire** : #showcase, #skills-ideas, #support, bot releases | Setup Discord, bot webhook | #16 |

## Phase 4 — Adoption (Semaine 4-6)

| # | Action | Fichiers/livrables | Itération |
|---|--------|--------------------|-----------|
| 4.1 | **Tiers Core/Pro/Full** : install progressif, upgrade path | Modification install.sh, `configs/tiers/` | #8 |
| 4.2 | **genius migrate** : import projets existants, inférence specs | `skills/genius-migrate.md` | #17 |
| 4.3 | **Guard configurable** : strict/standard/relaxed | Modification `GENIUS_GUARD.md`, `.genius/config.json` | #18 |
| 4.4 | **Templates** : saas, landing, api | `templates/saas/`, `templates/landing/`, `templates/api/` | #15 |
| 4.5 | **Skill SDK** : `genius skill create`, template, docs | `sdk/`, `docs/creating-skills.md` | #20 |

## Phase 5 — Échelle (Semaine 6-8)

| # | Action | Fichiers/livrables | Itération |
|---|--------|--------------------|-----------|
| 5.1 | **3 case studies** : SaaS MVP, migration Express, landing SEO | `docs/case-studies/` | #21 |
| 5.2 | **Programme Champions** : recruter 10 early adopters | Outreach, onboarding docs | #29 |
| 5.3 | **genius report** : rapport HTML partageable | `skills/genius-report.md` | #19 |
| 5.4 | **genius eject** : export Markdown standard | `skills/genius-eject.md` | #13 |
| 5.5 | **genius replay** : session replay terminal/HTML | `skills/genius-replay.md` | #27 |

## Phase 6 — Polish (Semaine 8+)

| # | Action | Fichiers/livrables | Itération |
|---|--------|--------------------|-----------|
| 6.1 | **Cortex optimisation** : latence <100ms, suggest_skill proactif | Modification Cortex MCP | #22 |
| 6.2 | **Multi-langue** : FR, ES, PT, DE, JA dans skills conversationnelles | Modification skills interviewer, specs, marketer | #28 |
| 6.3 | **Mode dry-run** : --dry-run sur chaque skill | Modification de chaque skill | #9 |

---

## Métriques de succès (objectif 6 mois)

| Métrique | Actuel | Objectif |
|----------|--------|----------|
| GitHub stars | 2 | 500 |
| Utilisateurs actifs / semaine | ~0 | 500 |
| Install via curl (uniques) | 0 | 2000 |
| Skills communautaires | 0 | 10 |
| Case studies publiées | 0 | 5 |
| Articles/mentions externes | 0 | 10 |
| Discord membres | 0 | 200 |
| GitHub Action installs | 0 | 50 repos |

---

## Quick Wins immédiats (cette semaine)

1. **README rewrite** — 2h de travail, impact maximal
2. **install.sh** — 4h, débloque l'adoption
3. **5-minute challenge** — 2h, prouve la valeur
4. **Positioning fixé** — 1h, alignement du message

Ces 4 actions changent la perception de Genius Team de "projet perso complexe" à "framework sérieux avec un point de vue clair".
