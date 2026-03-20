# Autoresearch Program — Genius Team v19 + Website

## TIMELINE: 25 heures (deadline samedi 20 mars 20h)

## 3 CHANTIERS EN PARALLÈLE

---

## CHANTIER 1 — Veille & Research (Phase 1, ~2h)

### Claude Code Channels (annonce 20 mars 2026)
- Plugin-based: Telegram + Discord support
- Connect Claude Code session to messaging app
- Full filesystem, MCP, git access from phone
- Architecture: MCP server → messaging platform → Claude Code session
- Plugin architecture = extensible
- Sender allowlist for security
- **Impact Genius Team**: Claude Code Channels pourrait être un "mode" supplémentaire de Genius Team — vibe coder depuis son téléphone. Intégrer dans les docs/workflows.

### Claude Code v2.1.76 (mars 2026)
- Voice mode (push-to-talk, /voice, 20 langues)
- /loop command (cron jobs dans le terminal)
- 1M token context window pour Opus 4.6
- /effort (low/medium/high)
- /color (personnalisation session)
- /simplify, /batch
- MCP elicitation (tools ask for missing params)
- **Impact Genius Team**: 
  - Voice mode → genius-voice skill?
  - /loop → intégrer dans genius-experiments/autoresearch
  - 1M context → rethink compaction strategy
  - /effort → document dans TOOLS.md

### OpenAI Codex CLI
- Multi-agent orchestration, parallel tasks
- codex exec --profile preservation
- MCP + elicitation improvements
- OpenAI building desktop super app (ChatGPT + Codex + Browser)
- **Impact Genius Team**: update genius-orchestrator for Codex multi-agent patterns

### État actuel v18
- 42 skills, 4 modes (CLI/IDE/Omni/Dual)
- Autoresearch framework
- 90% routing accuracy benchmark
- Playground templates with design tokens
- Session durability fix (postCompaction)

---

## CHANTIER 2 — Plan v19 Release (Phase 2, ~3h)

### Angle v19: "Claude Channels + Voice + Mobile Vibe Coding"

**Features à ajouter:**
1. **Claude Code Channels integration** — nouveau mode ou doc pour setup Telegram/Discord comme interface Genius Team
2. **Voice mode guide** — comment utiliser /voice avec Genius Team
3. **1M context optimization** — adapter compaction strategy pour Opus 4.6 1M
4. **/loop integration** — utiliser /loop pour monitoring et autoresearch natif
5. **Effort levels** — documenter /effort dans chaque skill quand pertinent
6. **Skills refresh** — update des skills pour les nouvelles features CC
7. **Multi-engine parity** — Codex CLI multi-agent support

**Livrables v19:**
- VERSION bump → 19.0.0
- CHANGELOG.md entry
- Scripts upgrade.sh updated
- README.md updated
- TOOLS.md updated (CC v2.1.76, Codex latest)
- configs/ updated (4 modes)
- New/updated skills as needed
- Website updated

---

## CHANTIER 3 — Site Web (Phase 3, ~15h avec autoresearch)

### Base: Proposition 3 (Premium Gold)
- C'est la meilleure selon Ben
- Hero page = bon début mais incomplet vs site actuel
- Compléter tout en restant aéré et simple
- Possibilité de pages supplémentaires

### À faire:
1. Auditer P3 actuelle vs site index.html actuel — lister tout ce qui manque
2. Compléter P3 avec les sections manquantes
3. Potentiellement: sous-pages (docs, getting-started, changelog)
4. Intégrer les nouvelles features v19 dans le site
5. Messaging: vibe coding, anyone can build, honest
6. Autoresearch itératif: build → score → improve → commit → repeat

### Mesures:
1. Visual impact (€50K+ look)
2. Clarity (<3s comprehension)
3. Completeness (vs current site)
4. Messaging (vibe coding, honest)
5. Responsive
6. Technical quality

---

## EXÉCUTION

### Phase 1 (heures 1-2): Research
- [x] Claude Code Channels
- [x] Claude Code v2.1.76 features
- [x] Codex CLI updates
- [ ] Genius Veils des 7 derniers jours (sessions history)
- [ ] Audit site actuel vs P3

### Phase 2 (heures 2-5): Plan v19
- [ ] Feature list finalisée
- [ ] Skills à créer/modifier
- [ ] Release checklist

### Phase 3 (heures 5-25): Construction + Autoresearch
- [ ] Site P3 complété
- [ ] v19 code changes
- [ ] Tests
- [ ] Autoresearch itérations (target 15+)
- [ ] Push final
