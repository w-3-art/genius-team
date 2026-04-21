/* Genius Ecosystem — shared behaviors (i18n, cursor, scroll reveal, nav highlight) */

// ============================================================================
// i18n dictionary (EN default, FR alternative)
// ============================================================================
const I18N = {
  en: {
    'nav.ecosystem': 'Ecosystem',
    'nav.team': 'Genius Team',
    'nav.cortex': 'Cortex',
    'nav.revius': 'Revius',
    'nav.github': 'GitHub',
    'nav.start': 'Start building',

    // Home hero
    'home.hero.badge': 'Anyone can build',
    'home.hero.title.1': 'Turn any idea',
    'home.hero.title.2': 'into a real product.',
    'home.hero.title.em': 'Anyone',
    'home.hero.lead': 'Three tools that work together so you can imagine, build, review, and ship — even if you\'ve never written a line of code.',
    'home.hero.cta.primary': 'Meet the team',
    'home.hero.cta.secondary': 'How it works',
    'home.hero.trust.1': 'Open source',
    'home.hero.trust.2': 'Free forever (GT)',
    'home.hero.trust.3': 'Local-first',
    'home.hero.trust.4': 'Desktop app',

    // Home products section
    'home.products.label': 'Three products, one ecosystem',
    'home.products.title': 'A complete toolkit around you.',
    'home.products.desc': 'Each product plays a distinct role. Together they form the fastest path from raw idea to shipped product — with feedback loops that make you better at every cycle.',
    'home.products.team.eyebrow': 'Genius Team',
    'home.products.team.title': 'Build with direction.',
    'home.products.team.desc': 'An AI team of 54 specialists that guides you through every stage — from the first interview to deployment — and teaches you as you go.',
    'home.products.team.tag': 'Open source · Free forever',
    'home.products.team.link': 'Explore Genius Team',
    'home.products.cortex.eyebrow': 'Cortex',
    'home.products.cortex.title': 'See the bigger picture.',
    'home.products.cortex.desc': 'Your desktop command center. Track every project, share memory across repos, orchestrate recurring tasks — stay serene even when you juggle five builds at once.',
    'home.products.cortex.tag': 'Free beta · Paid later',
    'home.products.cortex.link': 'Explore Cortex',
    'home.products.revius.eyebrow': 'Revius',
    'home.products.revius.title': 'Get real feedback.',
    'home.products.revius.desc': 'A local-first review layer. Select a zone on your live app, drop an observation, and get AI-ready prompts and tasks that feed straight back into the team.',
    'home.products.revius.tag': 'Free beta · Paid later',
    'home.products.revius.link': 'Explore Revius',

    // Home showcase
    'home.showcase.label': 'A guided look',
    'home.showcase.title': 'See what you\'ll be working with.',
    'home.showcase.desc': 'Scroll through real views from the three products.',

    // Home loop
    'home.loop.label': 'The loop',
    'home.loop.title': 'Imagine. Build. Review. Iterate.',
    'home.loop.desc': 'A rhythm that turns beginners into builders. You stay in control at every checkpoint — the tools do the heavy lifting, not the thinking.',
    'home.loop.step1.num': 'Step 01',
    'home.loop.step1.title': 'Imagine',
    'home.loop.step1.desc': 'Describe the idea in your own words. Genius Team interviews you, researches the market, and turns vague instincts into a clear spec.',
    'home.loop.step1.product': 'Genius Team',
    'home.loop.step2.num': 'Step 02',
    'home.loop.step2.title': 'Build',
    'home.loop.step2.desc': 'The team picks the right stack, writes the code, and ships it — with quality checks after every task. You approve at 3 human checkpoints.',
    'home.loop.step2.product': 'Genius Team',
    'home.loop.step3.num': 'Step 03',
    'home.loop.step3.title': 'Review',
    'home.loop.step3.desc': 'Revius opens on your live app. Click a zone, talk or type what feels off, and it produces AI-ready tasks and prompts.',
    'home.loop.step3.product': 'Revius',
    'home.loop.step4.num': 'Step 04',
    'home.loop.step4.title': 'Iterate',
    'home.loop.step4.desc': 'Cortex feeds feedback back into the team, tracks progress across all your projects, and schedules recurring audits while you sleep.',
    'home.loop.step4.product': 'Cortex',

    // Home philosophy
    'home.philosophy.label': 'Our philosophy',
    'home.philosophy.title': 'The opposite of a black box.',
    'home.philosophy.desc': 'We don\'t want to replace you. We want to make you capable.',
    'home.philosophy.wrong.label': 'What we avoid',
    'home.philosophy.wrong.1': 'Code thrown over the wall with zero explanation.',
    'home.philosophy.wrong.2': 'Magic tools that break silently when you need them.',
    'home.philosophy.wrong.3': 'One-shot generators that leave you stuck on iteration 2.',
    'home.philosophy.wrong.4': 'Lock-in ecosystems that own your work.',
    'home.philosophy.right.label': 'What we stand for',
    'home.philosophy.right.1': 'A team that teaches while it works with you.',
    'home.philosophy.right.2': 'Transparent artifacts — you see every step, every decision.',
    'home.philosophy.right.3': 'A review loop so you improve every cycle.',
    'home.philosophy.right.4': 'Local-first, open source by default, your data stays yours.',

    // Home stats
    'home.stats.1.num': '54',
    'home.stats.1.label': 'AI specialists',
    'home.stats.2.num': '3',
    'home.stats.2.label': 'Tools, one loop',
    'home.stats.3.num': '100%',
    'home.stats.3.label': 'Local-first',
    'home.stats.4.num': 'MIT',
    'home.stats.4.label': 'Open source',

    // Home CTA
    'home.cta.title': 'Ready to build something you\'re proud of?',
    'home.cta.desc': 'Start with Genius Team. Open Cortex and Revius whenever you need the bigger picture or a second pair of eyes.',
    'home.cta.primary': 'Open Genius Team',
    'home.cta.secondary': 'Download Cortex',

    // Shared footer
    'footer.copy': 'Genius Ecosystem · Anyone can build.',

    // GT page
    'team.hero.badge': 'Open source · Free forever',
    'team.hero.title.1': 'An AI team',
    'team.hero.title.2': 'that teaches you to build.',
    'team.hero.title.em': 'teaches you',
    'team.hero.lead': '54 specialists, 2 phases, 3 human checkpoints. Every artifact is generated in the open — so you learn the craft while the team carries the load.',
    'team.hero.cta.primary': 'Read the getting started',
    'team.hero.cta.secondary': 'Browse the skills',
    'team.phases.label': 'Two phases',
    'team.phases.title': 'A rhythm that works for every project.',
    'team.phases.ideation.title': 'Phase 1 — Ideation',
    'team.phases.ideation.desc': 'Conversational. The team interviews you, analyses the market, drafts specs and architecture. You approve at three human checkpoints: specs, design, architecture.',
    'team.phases.execution.title': 'Phase 2 — Execution',
    'team.phases.execution.desc': 'Autonomous. An orchestrator dispatches tasks to specialised dev agents with a mandatory quality check after every task. You can sleep while it ships.',
    'team.features.label': 'What you get',
    'team.features.title': 'Everything a real team would give you.',
    'team.features.1.title': 'Specs, not wishes',
    'team.features.1.desc': 'Clear specifications written from your interview, not guessed from a prompt.',
    'team.features.2.title': 'Design options',
    'team.features.2.desc': 'Real design system options you choose from — not a generic template.',
    'team.features.3.title': 'Architecture you can read',
    'team.features.3.desc': 'A documented stack with trade-offs explained so you learn the why.',
    'team.features.4.title': 'QA after every task',
    'team.features.4.desc': 'A quick-check specialist runs after every change. Nothing ships broken.',
    'team.features.5.title': 'Playgrounds you can open',
    'team.features.5.desc': 'Every major skill produces an interactive HTML playground of its output.',
    'team.features.6.title': 'Mandatory pauses',
    'team.features.6.desc': 'Three user checkpoints keep you in the driver\'s seat — specs, design, architecture.',
    'team.install.label': 'Install',
    'team.install.title': 'One command and you\'re in.',
    'team.install.desc': 'Free forever, open source, MIT licensed. No account, no credit card.',
    'team.cta.title': 'Your team is one command away.',
    'team.cta.primary': 'View on GitHub',
    'team.cta.secondary': 'See Cortex',

    // Cortex page
    'cortex.hero.badge': 'Desktop app · Free beta',
    'cortex.hero.title.1': 'The cockpit for',
    'cortex.hero.title.2': 'everything you build.',
    'cortex.hero.title.em': 'cockpit',
    'cortex.hero.lead': 'A Tauri desktop app that sees all your projects at once — behaviors, rules, memory, personas, schedules, vault. One place to stay serene.',
    'cortex.hero.cta.primary': 'Download for macOS',
    'cortex.hero.cta.secondary': 'See the features',
    'cortex.features.label': 'What Cortex does',
    'cortex.features.title': 'One brain, every project.',
    'cortex.features.1.title': 'Multi-project dashboard',
    'cortex.features.1.desc': 'Status, health, active skill, next task — for every Genius Team repo you have.',
    'cortex.features.2.title': 'Shared memory',
    'cortex.features.2.desc': 'Save a decision or a pattern once. Every project learns from it.',
    'cortex.features.3.title': 'Behaviors & rules',
    'cortex.features.3.desc': 'Define what Claude Code should always do, or never do, across all your repos.',
    'cortex.features.4.title': 'Genius Store (MCP)',
    'cortex.features.4.desc': 'Skills are served on-demand via MCP — no bundling, no duplication, always up to date.',
    'cortex.features.5.title': 'Scheduler & triggers',
    'cortex.features.5.desc': 'Nightly QA, weekly audits, health checks — configure once, run forever.',
    'cortex.features.6.title': 'Vault',
    'cortex.features.6.desc': 'Store API keys globally or per project. Never hardcoded, never committed.',
    'cortex.pricing.label': 'Pricing',
    'cortex.pricing.title': 'Free during beta. Paid later — you\'ll know first.',
    'cortex.pricing.desc': 'Cortex is in open beta and free to use while we refine the experience. Once we ship the stable release, it will move to a paid license with a generous free tier. Everyone in the beta gets legacy access.',
    'cortex.cta.title': 'See every project at a glance.',
    'cortex.cta.primary': 'Download Cortex',
    'cortex.cta.secondary': 'View source',

    // Revius page
    'revius.hero.badge': 'Local-first · Free beta',
    'revius.hero.title.1': 'A kind, critical eye',
    'revius.hero.title.2': 'on what you just built.',
    'revius.hero.title.em': 'critical eye',
    'revius.hero.lead': 'Open Revius on your live app. Select a zone, say what feels off — by voice or text — and get AI-ready tasks and prompts that feed straight back into Genius Team.',
    'revius.hero.cta.primary': 'Try the beta',
    'revius.hero.cta.secondary': 'See how it works',
    'revius.flow.label': 'How a review works',
    'revius.flow.title': 'From gut feeling to actionable task.',
    'revius.flow.1.title': '1 · Start a session',
    'revius.flow.1.desc': 'Flip Revius on inside your dev server. The overlay stays out of the way until you need it.',
    'revius.flow.2.title': '2 · Select a zone',
    'revius.flow.2.desc': 'Click the part of the UI that feels wrong. Revius captures the selector, the screenshot, the context.',
    'revius.flow.3.title': '3 · Drop an observation',
    'revius.flow.3.desc': 'Type a note or record a voice note. Console warnings and errors are auto-captured in parallel.',
    'revius.flow.4.title': '4 · Generate insights',
    'revius.flow.4.desc': 'On stop, Revius writes tasks.md, prompts.md, and an HTML recap — ready for Genius Team to pick up.',
    'revius.features.label': 'Why local-first matters',
    'revius.features.title': 'Your review stays on your machine.',
    'revius.features.1.title': 'Your data, your disk',
    'revius.features.1.desc': 'SQLite + local files. No cloud. No leakage. Feedback you can share only with the people who need it.',
    'revius.features.2.title': 'Voice-first optional',
    'revius.features.2.desc': 'Talk about what feels off instead of typing it. Transcription is graceful if available.',
    'revius.features.3.title': 'Console capture',
    'revius.features.3.desc': 'Warnings and errors from your dev server are captured, deduplicated, and linked to the right zone.',
    'revius.features.4.title': 'Responsive preview',
    'revius.features.4.desc': 'Switch layouts without leaving the overlay. Review mobile, tablet, desktop in one session.',
    'revius.features.5.title': 'Plays with GT & Cortex',
    'revius.features.5.desc': 'Revius findings feed directly into Genius Team tasks and Cortex memory.',
    'revius.features.6.title': 'Vite & Next adapters',
    'revius.features.6.desc': 'Drop-in plugins for Vite and Next.js. Five minutes from install to first review.',
    'revius.pricing.label': 'Pricing',
    'revius.pricing.title': 'Free during beta. Paid later — beta users keep legacy perks.',
    'revius.pricing.desc': 'Revius is in open beta. Everything you see runs on your machine and stays free to use while we refine the experience. A paid license with a generous free tier will come later. Early users lock in a perpetual beta benefit.',
    'revius.cta.title': 'Give your app a kind second opinion.',
    'revius.cta.primary': 'Join the beta',
    'revius.cta.secondary': 'See Genius Team'
  },
  fr: {
    'nav.ecosystem': 'Écosystème',
    'nav.team': 'Genius Team',
    'nav.cortex': 'Cortex',
    'nav.revius': 'Revius',
    'nav.github': 'GitHub',
    'nav.start': 'Commencer',

    'home.hero.badge': 'Anyone can build',
    'home.hero.title.1': 'Transforme une idée',
    'home.hero.title.2': 'en vrai produit.',
    'home.hero.title.em': 'une idée',
    'home.hero.lead': 'Trois outils qui fonctionnent ensemble pour imaginer, construire, relire et livrer — même si tu n\'as jamais écrit une ligne de code.',
    'home.hero.cta.primary': 'Voir l\'équipe',
    'home.hero.cta.secondary': 'Comment ça marche',
    'home.hero.trust.1': 'Open source',
    'home.hero.trust.2': 'Gratuit à vie (GT)',
    'home.hero.trust.3': 'Local-first',
    'home.hero.trust.4': 'App desktop',

    'home.products.label': 'Trois produits, un écosystème',
    'home.products.title': 'Une boîte à outils complète autour de toi.',
    'home.products.desc': 'Chaque produit joue un rôle distinct. Ensemble, ils forment le chemin le plus court entre une idée brute et un produit livré — avec des boucles de feedback qui te rendent meilleur à chaque cycle.',
    'home.products.team.eyebrow': 'Genius Team',
    'home.products.team.title': 'Construis avec direction.',
    'home.products.team.desc': 'Une équipe IA de 54 spécialistes qui te guide à chaque étape — de la première interview jusqu\'au déploiement — et t\'enseigne le métier au passage.',
    'home.products.team.tag': 'Open source · Gratuit à vie',
    'home.products.team.link': 'Découvrir Genius Team',
    'home.products.cortex.eyebrow': 'Cortex',
    'home.products.cortex.title': 'Garde la vue d\'ensemble.',
    'home.products.cortex.desc': 'Ton cockpit desktop. Suis tous tes projets, partage la mémoire entre repos, orchestre les tâches récurrentes — reste serein même quand tu jongles avec cinq builds.',
    'home.products.cortex.tag': 'Beta gratuite · Payant plus tard',
    'home.products.cortex.link': 'Découvrir Cortex',
    'home.products.revius.eyebrow': 'Revius',
    'home.products.revius.title': 'Reçois du vrai feedback.',
    'home.products.revius.desc': 'Une couche de review locale. Sélectionne une zone de ton app live, ajoute une observation, et récupère des prompts et tâches prêts à nourrir l\'équipe.',
    'home.products.revius.tag': 'Beta gratuite · Payant plus tard',
    'home.products.revius.link': 'Découvrir Revius',

    'home.showcase.label': 'Un aperçu guidé',
    'home.showcase.title': 'Découvre les interfaces avec lesquelles tu vas travailler.',
    'home.showcase.desc': 'Fais défiler les vues réelles des trois produits.',

    'home.loop.label': 'La boucle',
    'home.loop.title': 'Imagine. Construis. Relis. Itère.',
    'home.loop.desc': 'Un rythme qui transforme les débutants en builders. Tu restes aux commandes à chaque checkpoint — les outils portent la charge, pas ta place.',
    'home.loop.step1.num': 'Étape 01',
    'home.loop.step1.title': 'Imagine',
    'home.loop.step1.desc': 'Décris l\'idée avec tes mots. Genius Team t\'interviewe, étudie le marché et transforme les intuitions vagues en spécification claire.',
    'home.loop.step1.product': 'Genius Team',
    'home.loop.step2.num': 'Étape 02',
    'home.loop.step2.title': 'Construis',
    'home.loop.step2.desc': 'L\'équipe choisit la bonne stack, écrit le code et le livre — avec un contrôle qualité après chaque tâche. Tu valides à 3 checkpoints humains.',
    'home.loop.step2.product': 'Genius Team',
    'home.loop.step3.num': 'Étape 03',
    'home.loop.step3.title': 'Relis',
    'home.loop.step3.desc': 'Revius s\'ouvre sur ton app live. Clique sur une zone, dis ce qui ne va pas à la voix ou au texte, et récupère des tâches prêtes pour l\'IA.',
    'home.loop.step3.product': 'Revius',
    'home.loop.step4.num': 'Étape 04',
    'home.loop.step4.title': 'Itère',
    'home.loop.step4.desc': 'Cortex réinjecte le feedback dans l\'équipe, suit les progrès sur tous tes projets et planifie les audits récurrents pendant que tu dors.',
    'home.loop.step4.product': 'Cortex',

    'home.philosophy.label': 'Notre philosophie',
    'home.philosophy.title': 'L\'opposé d\'une boîte noire.',
    'home.philosophy.desc': 'On ne veut pas te remplacer. On veut te rendre capable.',
    'home.philosophy.wrong.label': 'Ce qu\'on évite',
    'home.philosophy.wrong.1': 'Du code balancé par-dessus le mur, sans aucune explication.',
    'home.philosophy.wrong.2': 'Des outils magiques qui cassent silencieusement au moment critique.',
    'home.philosophy.wrong.3': 'Des générateurs one-shot qui te laissent bloqué à l\'itération 2.',
    'home.philosophy.wrong.4': 'Des écosystèmes fermés qui possèdent ton travail.',
    'home.philosophy.right.label': 'Ce qu\'on défend',
    'home.philosophy.right.1': 'Une équipe qui t\'apprend le métier pendant qu\'elle bosse avec toi.',
    'home.philosophy.right.2': 'Des artefacts transparents — tu vois chaque étape, chaque décision.',
    'home.philosophy.right.3': 'Une boucle de review pour progresser à chaque cycle.',
    'home.philosophy.right.4': 'Local-first, open source par défaut, tes données restent à toi.',

    'home.stats.1.num': '54',
    'home.stats.1.label': 'Spécialistes IA',
    'home.stats.2.num': '3',
    'home.stats.2.label': 'Outils, une boucle',
    'home.stats.3.num': '100%',
    'home.stats.3.label': 'Local-first',
    'home.stats.4.num': 'MIT',
    'home.stats.4.label': 'Open source',

    'home.cta.title': 'Prêt à construire quelque chose dont tu seras fier ?',
    'home.cta.desc': 'Commence avec Genius Team. Ouvre Cortex et Revius quand tu as besoin de la vue d\'ensemble ou d\'un second regard.',
    'home.cta.primary': 'Ouvrir Genius Team',
    'home.cta.secondary': 'Télécharger Cortex',

    'footer.copy': 'Genius Ecosystem · Anyone can build.',

    'team.hero.badge': 'Open source · Gratuit à vie',
    'team.hero.title.1': 'Une équipe IA',
    'team.hero.title.2': 'qui t\'apprend à construire.',
    'team.hero.title.em': 't\'apprend',
    'team.hero.lead': '54 spécialistes, 2 phases, 3 checkpoints humains. Chaque artefact est généré au grand jour — tu apprends le métier pendant que l\'équipe porte la charge.',
    'team.hero.cta.primary': 'Lire le getting started',
    'team.hero.cta.secondary': 'Parcourir les skills',
    'team.phases.label': 'Deux phases',
    'team.phases.title': 'Un rythme qui fonctionne pour chaque projet.',
    'team.phases.ideation.title': 'Phase 1 — Idéation',
    'team.phases.ideation.desc': 'Conversationnelle. L\'équipe t\'interviewe, analyse le marché, rédige les specs et l\'architecture. Tu valides à trois checkpoints humains : specs, design, architecture.',
    'team.phases.execution.title': 'Phase 2 — Exécution',
    'team.phases.execution.desc': 'Autonome. Un orchestrateur dispatche les tâches à des dev spécialisés avec un contrôle qualité obligatoire après chaque tâche. Tu peux dormir pendant que ça livre.',
    'team.features.label': 'Ce que tu reçois',
    'team.features.title': 'Tout ce qu\'une vraie équipe te donnerait.',
    'team.features.1.title': 'Des specs, pas des vœux',
    'team.features.1.desc': 'Une spécification claire écrite depuis l\'interview, pas devinée depuis un prompt.',
    'team.features.2.title': 'Options de design',
    'team.features.2.desc': 'De vraies options de design system à choisir — pas un template générique.',
    'team.features.3.title': 'Une architecture lisible',
    'team.features.3.desc': 'Une stack documentée avec les trade-offs expliqués pour que tu apprennes le pourquoi.',
    'team.features.4.title': 'QA après chaque tâche',
    'team.features.4.desc': 'Un spécialiste quick-check tourne après chaque changement. Rien ne part cassé.',
    'team.features.5.title': 'Des playgrounds à ouvrir',
    'team.features.5.desc': 'Chaque grande skill produit un playground HTML interactif de son output.',
    'team.features.6.title': 'Pauses obligatoires',
    'team.features.6.desc': 'Trois checkpoints utilisateur pour te garder aux commandes — specs, design, architecture.',
    'team.install.label': 'Installation',
    'team.install.title': 'Une commande et tu es dedans.',
    'team.install.desc': 'Gratuit à vie, open source, licence MIT. Pas de compte, pas de carte bancaire.',
    'team.cta.title': 'Ton équipe est à une commande.',
    'team.cta.primary': 'Voir sur GitHub',
    'team.cta.secondary': 'Découvrir Cortex',

    'cortex.hero.badge': 'App desktop · Beta gratuite',
    'cortex.hero.title.1': 'Le cockpit de',
    'cortex.hero.title.2': 'tout ce que tu construis.',
    'cortex.hero.title.em': 'cockpit',
    'cortex.hero.lead': 'Une app desktop Tauri qui voit tous tes projets d\'un coup — behaviors, règles, mémoire, personas, schedules, vault. Un seul endroit pour rester serein.',
    'cortex.hero.cta.primary': 'Télécharger pour macOS',
    'cortex.hero.cta.secondary': 'Voir les fonctionnalités',
    'cortex.features.label': 'Ce que fait Cortex',
    'cortex.features.title': 'Un cerveau, chaque projet.',
    'cortex.features.1.title': 'Tableau de bord multi-projets',
    'cortex.features.1.desc': 'État, santé, skill active, prochaine tâche — pour chaque repo Genius Team.',
    'cortex.features.2.title': 'Mémoire partagée',
    'cortex.features.2.desc': 'Enregistre une décision ou un pattern une fois. Tous tes projets en bénéficient.',
    'cortex.features.3.title': 'Behaviors & règles',
    'cortex.features.3.desc': 'Définis ce que Claude Code doit toujours faire, ou ne jamais faire, sur tous tes repos.',
    'cortex.features.4.title': 'Genius Store (MCP)',
    'cortex.features.4.desc': 'Les skills sont servies à la demande via MCP — pas de bundling, pas de doublon, toujours à jour.',
    'cortex.features.5.title': 'Scheduler & triggers',
    'cortex.features.5.desc': 'QA nocturne, audits hebdo, health checks — configure une fois, tourne à vie.',
    'cortex.features.6.title': 'Vault',
    'cortex.features.6.desc': 'Stocke les clés API globalement ou par projet. Jamais en dur, jamais commit.',
    'cortex.pricing.label': 'Tarification',
    'cortex.pricing.title': 'Gratuit pendant la beta. Payant plus tard — tu seras prévenu en premier.',
    'cortex.pricing.desc': 'Cortex est en beta ouverte et gratuit le temps qu\'on peaufine l\'expérience. Au moment du stable release, on passera à une licence payante avec un tier gratuit généreux. Les utilisateurs beta gardent un accès legacy.',
    'cortex.cta.title': 'Vois chaque projet d\'un coup d\'œil.',
    'cortex.cta.primary': 'Télécharger Cortex',
    'cortex.cta.secondary': 'Voir le code source',

    'revius.hero.badge': 'Local-first · Beta gratuite',
    'revius.hero.title.1': 'Un œil bienveillant',
    'revius.hero.title.2': 'sur ce que tu viens de construire.',
    'revius.hero.title.em': 'bienveillant',
    'revius.hero.lead': 'Ouvre Revius sur ton app live. Sélectionne une zone, dis ce qui ne va pas — à la voix ou au texte — et récupère des tâches et prompts prêts à nourrir Genius Team.',
    'revius.hero.cta.primary': 'Essayer la beta',
    'revius.hero.cta.secondary': 'Voir comment ça marche',
    'revius.flow.label': 'Comment se passe une review',
    'revius.flow.title': 'De l\'intuition à la tâche actionnable.',
    'revius.flow.1.title': '1 · Démarre une session',
    'revius.flow.1.desc': 'Active Revius dans ton dev server. L\'overlay reste discret jusqu\'à ce que tu en aies besoin.',
    'revius.flow.2.title': '2 · Sélectionne une zone',
    'revius.flow.2.desc': 'Clique sur la partie de l\'UI qui te dérange. Revius capture le sélecteur, la capture, le contexte.',
    'revius.flow.3.title': '3 · Ajoute une observation',
    'revius.flow.3.desc': 'Tape une note ou enregistre ta voix. Les warnings et erreurs console sont capturés en parallèle.',
    'revius.flow.4.title': '4 · Génère les insights',
    'revius.flow.4.desc': 'À l\'arrêt, Revius écrit tasks.md, prompts.md et un récapitulatif HTML — prêts pour Genius Team.',
    'revius.features.label': 'Pourquoi local-first',
    'revius.features.title': 'Ta review reste sur ta machine.',
    'revius.features.1.title': 'Tes données, ton disque',
    'revius.features.1.desc': 'SQLite + fichiers locaux. Pas de cloud. Pas de fuite. Un feedback que tu partages seulement à ceux qui doivent le voir.',
    'revius.features.2.title': 'Voice-first optionnel',
    'revius.features.2.desc': 'Parle de ce qui ne va pas plutôt que de le taper. Transcription quand disponible.',
    'revius.features.3.title': 'Capture console',
    'revius.features.3.desc': 'Warnings et erreurs de ton dev server sont capturés, dédupliqués et liés à la bonne zone.',
    'revius.features.4.title': 'Preview responsive',
    'revius.features.4.desc': 'Change de layout sans quitter l\'overlay. Relis mobile, tablet, desktop dans la même session.',
    'revius.features.5.title': 'Joue avec GT & Cortex',
    'revius.features.5.desc': 'Les findings Revius nourrissent directement les tâches Genius Team et la mémoire Cortex.',
    'revius.features.6.title': 'Adapters Vite & Next',
    'revius.features.6.desc': 'Plugins drop-in pour Vite et Next.js. Cinq minutes entre l\'install et la première review.',
    'revius.pricing.label': 'Tarification',
    'revius.pricing.title': 'Gratuit pendant la beta. Payant plus tard — les beta users gardent des avantages legacy.',
    'revius.pricing.desc': 'Revius est en beta ouverte. Tout tourne sur ta machine et reste gratuit le temps qu\'on peaufine l\'expérience. Une licence payante avec un tier gratuit généreux arrivera plus tard. Les early users verrouillent un bénéfice perpétuel.',
    'revius.cta.title': 'Offre à ton app un second regard bienveillant.',
    'revius.cta.primary': 'Rejoindre la beta',
    'revius.cta.secondary': 'Découvrir Genius Team'
  }
};

// ============================================================================
// i18n application
// ============================================================================
const LANG_KEY = 'genius-lang';
const DEFAULT_LANG = 'en';

function getCurrentLang() {
  const saved = localStorage.getItem(LANG_KEY);
  if (saved === 'en' || saved === 'fr') return saved;
  // Auto-detect from browser
  const browser = (navigator.language || 'en').toLowerCase();
  return browser.startsWith('fr') ? 'fr' : DEFAULT_LANG;
}

function setLang(lang) {
  if (lang !== 'en' && lang !== 'fr') return;
  localStorage.setItem(LANG_KEY, lang);
  document.documentElement.lang = lang;
  applyTranslations(lang);
  updateLangToggle(lang);
  // Re-split words in hero titles (applyTranslations wrote fresh text)
  document.querySelectorAll('.hero__title').forEach((t) => { t.dataset.split = '0'; });
  splitTitleWords();
  // Reveal immediately so users see text
  document.querySelectorAll('.hero__title').forEach((t) => t.classList.add('is-visible'));
}

function applyTranslations(lang) {
  const dict = I18N[lang] || I18N[DEFAULT_LANG];
  document.querySelectorAll('[data-i18n]').forEach((el) => {
    const key = el.getAttribute('data-i18n');
    if (dict[key] !== undefined) {
      // Support {{em}} placeholder for gold-emphasis words inside titles
      const value = dict[key];
      if (el.hasAttribute('data-i18n-em')) {
        const emKey = el.getAttribute('data-i18n-em');
        const emWord = dict[emKey] || '';
        el.innerHTML = value.split(emWord).join(`<em>${emWord}</em>`);
      } else {
        el.textContent = value;
      }
    }
  });
  document.querySelectorAll('[data-i18n-attr]').forEach((el) => {
    const spec = el.getAttribute('data-i18n-attr');
    spec.split(';').forEach((pair) => {
      const [attr, key] = pair.split(':').map((s) => s.trim());
      if (attr && key && dict[key] !== undefined) {
        el.setAttribute(attr, dict[key]);
      }
    });
  });
}

function updateLangToggle(lang) {
  document.querySelectorAll('.lang-toggle').forEach((btn) => {
    const en = btn.querySelector('.lang-en');
    const fr = btn.querySelector('.lang-fr');
    if (en && fr) {
      en.classList.toggle('lang-active', lang === 'en');
      fr.classList.toggle('lang-active', lang === 'fr');
    }
  });
}

// ============================================================================
// Enhanced cursor (ring + snap dot + ambient glow + particle trail)
// ============================================================================
function setupCursor() {
  const canHover = window.matchMedia('(hover: hover) and (pointer: fine)').matches;
  const reduced  = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (!canHover || reduced) return;

  const ring = document.querySelector('[data-cursor-ring]');
  const dot  = document.querySelector('[data-cursor-dot]');
  const glow = document.querySelector('[data-cursor-glow]');
  const trailCanvas = document.querySelector('[data-cursor-trail]');
  if (!ring && !dot && !glow) return;

  // Mouse targets
  let mx = window.innerWidth / 2, my = window.innerHeight / 2;
  // Lagging follow positions
  let rx = mx, ry = my;  // ring
  let gx = mx, gy = my;  // glow

  // Particle trail
  let ctx = null;
  const particles = [];
  if (trailCanvas) {
    trailCanvas.width = window.innerWidth * devicePixelRatio;
    trailCanvas.height = window.innerHeight * devicePixelRatio;
    trailCanvas.style.width = window.innerWidth + 'px';
    trailCanvas.style.height = window.innerHeight + 'px';
    ctx = trailCanvas.getContext('2d');
    ctx.scale(devicePixelRatio, devicePixelRatio);
    window.addEventListener('resize', () => {
      trailCanvas.width = window.innerWidth * devicePixelRatio;
      trailCanvas.height = window.innerHeight * devicePixelRatio;
      trailCanvas.style.width = window.innerWidth + 'px';
      trailCanvas.style.height = window.innerHeight + 'px';
      ctx = trailCanvas.getContext('2d');
      ctx.scale(devicePixelRatio, devicePixelRatio);
    });
  }

  document.addEventListener('mousemove', (e) => {
    mx = e.clientX; my = e.clientY;
    if (dot) {
      dot.style.left = mx + 'px';
      dot.style.top = my + 'px';
    }
    // Emit a trail particle on movement
    if (ctx) {
      particles.push({
        x: mx, y: my,
        vx: (Math.random() - 0.5) * 0.4,
        vy: (Math.random() - 0.5) * 0.4,
        life: 1,
        size: 1.5 + Math.random() * 2,
        color: Math.random() > 0.75 ? [232, 130, 95] : [212, 165, 116],
      });
      if (particles.length > 120) particles.splice(0, particles.length - 120);
    }
  }, { passive: true });

  document.addEventListener('mousedown', () => ring?.classList.add('is-click'));
  document.addEventListener('mouseup',   () => ring?.classList.remove('is-click'));
  document.addEventListener('mouseleave', () => {
    if (ring) ring.style.opacity = '0';
    if (dot) dot.style.opacity = '0';
    if (glow) glow.style.opacity = '0';
  });
  document.addEventListener('mouseenter', () => {
    if (ring) ring.style.opacity = '';
    if (dot) dot.style.opacity = '';
    if (glow) glow.style.opacity = '';
  });

  // Hover enlargement on interactives
  document.addEventListener('mouseover', (e) => {
    if (!ring) return;
    const tgt = e.target.closest('a, button, input, textarea, select, [role="button"], .lang-toggle');
    if (tgt) ring.classList.add('is-hover');
  });
  document.addEventListener('mouseout', (e) => {
    if (!ring) return;
    const tgt = e.target.closest('a, button, input, textarea, select, [role="button"], .lang-toggle');
    if (tgt) ring.classList.remove('is-hover');
  });

  function frame() {
    // Ring eases to mouse (tighter lag)
    rx += (mx - rx) * 0.22;
    ry += (my - ry) * 0.22;
    if (ring) {
      ring.style.left = rx + 'px';
      ring.style.top = ry + 'px';
    }
    // Glow eases slower (softer trail)
    gx += (mx - gx) * 0.08;
    gy += (my - gy) * 0.08;
    if (glow) {
      glow.style.left = gx + 'px';
      glow.style.top = gy + 'px';
    }
    // Particle update
    if (ctx) {
      ctx.clearRect(0, 0, window.innerWidth, window.innerHeight);
      for (let i = particles.length - 1; i >= 0; i--) {
        const p = particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.life -= 0.024;
        if (p.life <= 0) {
          particles.splice(i, 1);
          continue;
        }
        ctx.beginPath();
        ctx.fillStyle = `rgba(${p.color[0]},${p.color[1]},${p.color[2]},${p.life * 0.75})`;
        ctx.arc(p.x, p.y, p.size * p.life, 0, Math.PI * 2);
        ctx.fill();
      }
    }
    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
}

// ============================================================================
// Hero title word-by-word wrap + reveal
// ============================================================================
function splitTitleWords() {
  document.querySelectorAll('.hero__title').forEach((title) => {
    if (title.dataset.split === '1') return;
    title.dataset.split = '1';
    title.querySelectorAll('span[data-i18n]').forEach((span) => {
      // Walk childNodes: preserve element nodes (<em>, etc.) as whole words,
      // split text nodes into individual word wrappers.
      const out = document.createDocumentFragment();
      span.childNodes.forEach((node) => {
        if (node.nodeType === Node.TEXT_NODE) {
          const parts = (node.textContent || '').split(/(\s+)/);
          parts.forEach((p) => {
            if (!p) return;
            if (/\s+/.test(p)) {
              out.appendChild(document.createTextNode(p));
            } else {
              const wrap = document.createElement('span');
              wrap.className = 'word';
              wrap.textContent = p;
              out.appendChild(wrap);
            }
          });
        } else if (node.nodeType === Node.ELEMENT_NODE) {
          // Wrap element (e.g. <em>) in a .word span so reveal applies to it too.
          const wrap = document.createElement('span');
          wrap.className = 'word';
          wrap.appendChild(node.cloneNode(true));
          out.appendChild(wrap);
        }
      });
      span.innerHTML = '';
      span.appendChild(out);
    });
  });
}

function revealHeroTitleSoon() {
  const titles = document.querySelectorAll('.hero__title');
  titles.forEach((t) => {
    // small stagger after mount
    requestAnimationFrame(() => {
      setTimeout(() => t.classList.add('is-visible'), 80);
    });
  });
}

// ============================================================================
// Parallax layers (hero aurora / sweep / decorative orbs)
// ============================================================================
function setupParallax() {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  const layers = Array.from(document.querySelectorAll('[data-parallax]'));
  if (!layers.length) return;
  let ticking = false;
  function update() {
    const scrollY = window.scrollY;
    for (const el of layers) {
      const rate = parseFloat(el.dataset.parallax || '0.12');
      el.style.transform = `translate3d(0, ${(scrollY * rate).toFixed(2)}px, 0)`;
    }
    ticking = false;
  }
  window.addEventListener('scroll', () => {
    if (!ticking) {
      requestAnimationFrame(update);
      ticking = true;
    }
  }, { passive: true });
  update();
}

// ============================================================================
// Scroll-velocity typography — tiny "is-scrolling" toggle
// ============================================================================
function setupScrollVelocity() {
  let timer = null;
  window.addEventListener('scroll', () => {
    document.documentElement.classList.add('is-scrolling');
    clearTimeout(timer);
    timer = setTimeout(() => document.documentElement.classList.remove('is-scrolling'), 160);
  }, { passive: true });
}

// ============================================================================
// Stats counter — counts up on reveal
// ============================================================================
function setupCounters() {
  const nums = document.querySelectorAll('.stat-num');
  if (!nums.length) return;
  const animate = (el) => {
    const raw = el.textContent.trim();
    const match = raw.match(/^(\d+)(.*)$/);
    if (!match) return;
    const target = parseInt(match[1], 10);
    const suffix = match[2] || '';
    if (!Number.isFinite(target) || target === 0) return;
    const start = performance.now();
    const duration = 1200;
    const from = 0;
    function step(now) {
      const t = Math.min(1, (now - start) / duration);
      const eased = 1 - Math.pow(1 - t, 3);
      const v = Math.round(from + (target - from) * eased);
      el.textContent = v + suffix;
      if (t < 1) requestAnimationFrame(step);
      else {
        el.textContent = target + suffix;
        el.classList.add('is-popped');
        setTimeout(() => el.classList.remove('is-popped'), 520);
      }
    }
    requestAnimationFrame(step);
  };
  const io = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        animate(entry.target);
        io.unobserve(entry.target);
      }
    });
  }, { threshold: 0.4 });
  nums.forEach((el) => io.observe(el));
}

// ============================================================================
// Pinned horizontal scroll — .pin-section > .pin-sticky > .pin-track
// Dynamic height: vertical scroll distance is sized to horizontal track width
// so every card fully passes before the pin releases. Extra padding gives
// breathing room at start/end so the animation feels smooth, not rushed.
// ============================================================================
function setupPinSections() {
  if (window.matchMedia('(max-width: 860px)').matches) return;
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  const sections = document.querySelectorAll('.pin-section');
  if (!sections.length) return;
  const state = [];
  for (const section of sections) {
    const track = section.querySelector('.pin-track');
    const progressFill = section.querySelector('.pin-progress__fill');
    if (!track) continue;
    state.push({ section, track, progressFill });
  }

  // Gentle ease so the horizontal track holds at start/end and moves briskly
  // through the middle — feels more cinematic than pure linear.
  function ease(t) {
    // smoothstep
    return t * t * (3 - 2 * t);
  }

  function sizeSections() {
    const viewport = window.innerHeight;
    for (const s of state) {
      const trackWidth = s.track.scrollWidth;
      const horizontalDistance = Math.max(0, trackWidth - window.innerWidth);
      // Give one viewport of head-room + the full horizontal distance +
      // a little extra at the end so the last card lingers.
      const height = viewport + horizontalDistance + viewport * 0.35;
      s.section.style.height = height + 'px';
      s.horizontalDistance = horizontalDistance;
    }
  }

  function update() {
    const viewport = window.innerHeight;
    for (const s of state) {
      const rect = s.section.getBoundingClientRect();
      const total = s.section.offsetHeight - viewport;
      const raw = Math.max(0, Math.min(1, -rect.top / total));
      const progress = ease(raw);
      const distance = s.horizontalDistance ?? Math.max(0, s.track.scrollWidth - window.innerWidth);
      s.track.style.transform = `translate3d(${-(distance * progress).toFixed(2)}px, 0, 0)`;
      if (s.progressFill) s.progressFill.style.width = (raw * 100).toFixed(1) + '%';
    }
  }

  let ticking = false;
  const onScroll = () => {
    if (!ticking) {
      requestAnimationFrame(() => { update(); ticking = false; });
      ticking = true;
    }
  };
  window.addEventListener('scroll', onScroll, { passive: true });
  window.addEventListener('resize', () => {
    sizeSections();
    update();
  });
  // Initial sizing runs after images/fonts layout settles
  sizeSections();
  update();
  // Re-size once fonts/images have finished loading (track width can grow)
  if (document.fonts && document.fonts.ready) {
    document.fonts.ready.then(() => { sizeSections(); update(); }).catch(() => {});
  }
  window.addEventListener('load', () => { sizeSections(); update(); });
}

// ============================================================================
// Zoom-in section — .zoom-section > .zoom-sticky > .zoom-frame
// Scale follows a bell curve with a dwell plateau at maximum, so the image
// grows as you scroll in, holds briefly, then gracefully eases out.
// ============================================================================
function setupZoomSections() {
  if (window.matchMedia('(max-width: 860px)').matches) return;
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  const sections = document.querySelectorAll('.zoom-section');
  if (!sections.length) return;
  const items = [];
  sections.forEach((section) => {
    const frame = section.querySelector('.zoom-frame');
    const label = section.querySelector('.zoom-label');
    if (frame) items.push({ section, frame, label });
  });

  // Remap progress so zoom-in runs from 0→0.4, dwells 0.4→0.7, zoom-out 0.7→1.
  function remap(raw) {
    if (raw < 0.4) return raw / 0.4;         // ramp in
    if (raw < 0.7) return 1;                 // hold
    return 1 - (raw - 0.7) / 0.3 * 0.15;     // slight ease-out to 0.85
  }

  function update() {
    const viewport = window.innerHeight;
    for (const it of items) {
      const rect = it.section.getBoundingClientRect();
      const total = it.section.offsetHeight - viewport;
      const raw = Math.max(0, Math.min(1, -rect.top / total));
      const p = remap(raw);
      const minScale = 0.7;
      const maxScale = 1.14;
      const scale = minScale + (maxScale - minScale) * p;
      const radius = 22 - p * 16;
      it.frame.style.transform = `translate3d(0,0,0) scale(${scale.toFixed(3)})`;
      it.frame.style.borderRadius = radius + 'px';
      if (it.label) {
        // Label fades as the image grows
        const labelOpacity = 1 - p * 0.85;
        const labelY = -14 * p;
        it.label.style.opacity = labelOpacity.toFixed(2);
        it.label.style.transform = `translate(-50%, ${labelY}px)`;
      }
    }
  }
  let ticking = false;
  window.addEventListener('scroll', () => {
    if (!ticking) {
      requestAnimationFrame(() => { update(); ticking = false; });
      ticking = true;
    }
  }, { passive: true });
  window.addEventListener('resize', update);
  update();
}

// ============================================================================
// Scroll reveal
// ============================================================================
function setupReveal() {
  const SELECTOR = '.reveal, .reveal-up, .reveal-down, .reveal-left, .reveal-right, .reveal-zoom, .reveal-tilt, .stagger';
  const all = () => document.querySelectorAll(SELECTOR);
  if (!('IntersectionObserver' in window)) {
    all().forEach((el) => el.classList.add('is-visible'));
    return;
  }
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    all().forEach((el) => el.classList.add('is-visible'));
    return;
  }
  const io = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-visible');
        io.unobserve(entry.target);
      }
    });
  }, { threshold: 0.08, rootMargin: '0px 0px -6% 0px' });
  all().forEach((el) => io.observe(el));

  // Safety net for full-page screenshot tools.
  setTimeout(() => {
    all().forEach((el) => {
      if (!el.classList.contains('is-visible')) {
        const r = el.getBoundingClientRect();
        if (r.top < document.documentElement.scrollHeight) {
          el.classList.add('is-visible');
        }
      }
    });
  }, 2500);
}

// ============================================================================
// Scroll progress bar
// ============================================================================
function setupScrollProgress() {
  const bar = document.querySelector('[data-scroll-progress]');
  if (!bar) return;
  const onScroll = () => {
    const doc = document.documentElement;
    const scrolled = window.scrollY;
    const max = doc.scrollHeight - window.innerHeight;
    const pct = max > 0 ? Math.min(1, scrolled / max) : 0;
    bar.style.width = (pct * 100).toFixed(2) + '%';
  };
  onScroll();
  window.addEventListener('scroll', onScroll, { passive: true });
}

// ============================================================================
// Horizontal scroll showcase — keyboard support
// ============================================================================
function setupShowcaseKeyboard() {
  const showcase = document.querySelector('[data-showcase-scroller]');
  if (!showcase) return;
  showcase.setAttribute('tabindex', '0');
  showcase.addEventListener('keydown', (e) => {
    const card = showcase.querySelector('.showcase__card');
    const step = card ? card.getBoundingClientRect().width + 20 : 300;
    if (e.key === 'ArrowRight') { showcase.scrollBy({ left: step, behavior: 'smooth' }); e.preventDefault(); }
    if (e.key === 'ArrowLeft')  { showcase.scrollBy({ left: -step, behavior: 'smooth' }); e.preventDefault(); }
  });
}

// ============================================================================
// Nav current page highlight
// ============================================================================
function highlightCurrentPage() {
  const page = location.pathname.split('/').pop() || 'index.html';
  document.querySelectorAll('.nav__links a[data-page], .nav-drawer__links a[data-page]').forEach((a) => {
    if (a.getAttribute('data-page') === page.replace('.html', '')) {
      a.setAttribute('aria-current', 'page');
    }
  });
}

// ============================================================================
// Mobile nav (hamburger + full-screen drawer)
// ============================================================================
function setupMobileNav() {
  const burger = document.querySelector('[data-nav-burger]');
  const drawer = document.querySelector('[data-nav-drawer]');
  if (!burger || !drawer) return;
  const closeBtn = drawer.querySelector('[data-nav-drawer-close]');
  const drawerLinks = drawer.querySelectorAll('[data-nav-drawer-link]');

  const openDrawer = () => {
    drawer.classList.add('is-open');
    drawer.setAttribute('aria-hidden', 'false');
    burger.setAttribute('aria-expanded', 'true');
    burger.setAttribute('aria-label', 'Close menu');
    document.body.classList.add('nav-drawer-open');
    // Focus the close button for keyboard users
    setTimeout(() => { closeBtn && closeBtn.focus(); }, 80);
  };
  const closeDrawer = () => {
    drawer.classList.remove('is-open');
    drawer.setAttribute('aria-hidden', 'true');
    burger.setAttribute('aria-expanded', 'false');
    burger.setAttribute('aria-label', 'Open menu');
    document.body.classList.remove('nav-drawer-open');
    burger.focus();
  };
  const toggleDrawer = () => {
    if (drawer.classList.contains('is-open')) closeDrawer();
    else openDrawer();
  };

  burger.addEventListener('click', (e) => {
    e.preventDefault();
    toggleDrawer();
  });
  if (closeBtn) closeBtn.addEventListener('click', (e) => { e.preventDefault(); closeDrawer(); });

  // Clicking any link inside drawer closes it (browser will navigate after)
  drawerLinks.forEach((a) => {
    a.addEventListener('click', () => {
      // Defer so same-page anchor links still scroll smoothly
      setTimeout(closeDrawer, 20);
    });
  });

  // ESC key closes drawer
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && drawer.classList.contains('is-open')) {
      closeDrawer();
    }
  });

  // If viewport grows past breakpoint while drawer is open, close it
  const mql = window.matchMedia('(min-width: 861px)');
  const onMql = () => {
    if (mql.matches && drawer.classList.contains('is-open')) closeDrawer();
  };
  if (mql.addEventListener) mql.addEventListener('change', onMql);
  else if (mql.addListener) mql.addListener(onMql);
}

// ============================================================================
// Lang toggle wiring
// ============================================================================
function setupLangToggle() {
  document.querySelectorAll('.lang-toggle').forEach((btn) => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const next = getCurrentLang() === 'en' ? 'fr' : 'en';
      setLang(next);
    });
  });
}

// ============================================================================
// Boot
// ============================================================================
function boot() {
  const lang = getCurrentLang();
  document.documentElement.lang = lang;
  applyTranslations(lang);
  updateLangToggle(lang);
  splitTitleWords();
  setupCursor();
  setupReveal();
  setupScrollProgress();
  setupShowcaseKeyboard();
  setupParallax();
  setupScrollVelocity();
  setupCounters();
  setupPinSections();
  setupZoomSections();
  highlightCurrentPage();
  setupLangToggle();
  setupMobileNav();
  revealHeroTitleSoon();
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', boot);
} else {
  boot();
}
