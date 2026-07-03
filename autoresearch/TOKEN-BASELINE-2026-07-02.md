# TOKEN BASELINE — Genius Team

> **Date:** 2026-07-02
> **Item:** P0-13 (Phase 0 — plan d'amélioration Genius)
> **Repo:** `genius-team`
> **But:** point de comparaison officiel pour l'objectif **-71%** du token diet de l'overhaul.

Ce document mesure ce qui est chargé dans le contexte d'une session GT « type ». Toutes
les valeurs sont des **tokens approximatifs** dérivés du nombre de caractères, avec deux
bornes couramment utilisées :

- borne basse = `chars / 4` (anglais dense, code, markdown)
- borne haute = `chars / 3.5` (français + ponctuation + markdown structuré)

Le vrai coût tokenizer réel se situe entre les deux. On raisonne en fourchette, pas en
valeur exacte, pour ne pas se mentir sur la précision.

---

## 1. Méthodologie reproductible

Toutes les mesures ci-dessous sont issues des commandes exactes suivantes, exécutées
depuis la racine du repo `genius-team`.

### 1.1 Compter les caractères d'un fichier

```bash
wc -c CLAUDE.md
wc -c .genius/GT-WORKFLOW.md
```

### 1.2 Fichiers SKILL.md (55 skills)

```bash
# Nombre de skills
find .claude/skills -name SKILL.md | wc -l          # -> 55

# Total caractères de tous les SKILL.md
find .claude/skills -name SKILL.md -exec cat {} + | wc -c   # -> 345687
```

### 1.3 Descriptions frontmatter (ce que Claude Code charge au démarrage)

Claude Code ne charge PAS les SKILL.md entiers au démarrage : il charge uniquement le
`name` + `description` du frontmatter YAML de chaque skill (l'« index » des skills). Extrait
et mesuré via le script Python `scratchpad/measure.py` (joint ci-dessous, section 6), qui
parse le bloc `---...---` de chaque fichier.

### 1.4 Sortie réelle du hook SessionStart

Le hook `SessionStart` (défini dans `.claude/settings.json`) a été **exécuté réellement**
pour mesurer sa sortie injectée dans le contexte :

```bash
# Reproduction : on rejoue la commande exacte du hook SessionStart de settings.json
# et on capture stdout (c'est ce qui est injecté dans le contexte au démarrage).
OUT=$(bash -c '<commande SessionStart de .claude/settings.json>'); printf '%s' "$OUT" | wc -c
```

Deux régimes ont été mesurés :
- **cold start** (1ʳᵉ session : `BRIEFING.md` absent → `memory-recover.sh` s'exécute) : **1143 chars**
- **steady state** (`BRIEFING.md` existe → recover sauté) : **477 chars**

Note d'effet de bord : exécuter ce hook a généré des artefacts (`.genius/state.json`,
`.genius/memory/BRIEFING.md`, event logs, `decisions.json`). Ce sont des fichiers auto-générés
non suivis ; aucun fichier existant n'a été modifié ou supprimé.

### 1.5 Statistiques par-skill (mean/médiane)

Tailles individuelles agrégées et triées par `scratchpad/measure.py` (via `os.path.getsize`
+ `statistics.mean/median`).

---

## 2. STARTUP — coût d'ouverture d'une session GT

### 2a. Coût natif Claude Code (toujours chargé au démarrage)

| Composant | Chars | Tokens `/4` | Tokens `/3.5` |
|---|---:|---:|---:|
| `CLAUDE.md` (projet) | 2 997 | 749 | 856 |
| Index des 55 skills (`name` + `description` frontmatter) | 27 007 | 6 752 | 7 716 |
| Sortie hook `SessionStart` (steady state, inclut l'entête BRIEFING) | 477 | 119 | 136 |
| **TOTAL STARTUP (natif)** | **30 481** | **7 620** | **8 709** |

> C'est le **coût plancher** payé à chaque session GT avant même le premier message
> utilisateur. Le poste dominant est l'index des 55 descriptions (~88 % du startup natif).

### 2b. Contexte GT « effectif » (fichiers de facto injectés en session)

Ces fichiers ne sont pas des imports `@` de `CLAUDE.md`, mais le harness GT les injecte de
facto (règles chargées à chaque opération fichier ; `GT-WORKFLOW.md` lu en début de flow).
On les compte à part pour ne pas gonfler artificiellement le plancher natif.

| Composant | Chars | Tokens `/4` | Tokens `/3.5` |
|---|---:|---:|---:|
| `.genius/GT-WORKFLOW.md` | 4 267 | 1 067 | 1 219 |
| `.claude/rules/*.md` (8 fichiers, injectés sur opérations fichier) | 9 461 | 2 365 | 2 703 |
| **Sous-total contexte GT** | **13 728** | **3 432** | **3 922** |
| **STARTUP EFFECTIF (2a + 2b)** | **44 209** | **11 052** | **12 631** |

### 2c. Variantes / postes annexes

| Poste | Chars | Tokens `/4` | Tokens `/3.5` | Nature |
|---|---:|---:|---:|---|
| Hook `SessionStart` — cold start (1ʳᵉ session, avec `memory-recover`) | 1 143 | 286 | 327 | ponctuel |
| `BRIEFING.md` complet (généré) | 341 | 85 | 97 | inclus dans le hook |
| Hook `UserPromptSubmit` (reminder coding) | ~600 | ~150 | ~171 | **par prompt de code**, pas au startup |

---

## 3. PER-SKILL — coût de chargement d'un skill complet

Quand un skill s'active, Claude Code charge son `SKILL.md` **entier** (l'incrément réel est
le fichier moins sa description déjà comptée au startup, soit ~473 chars de moins en moyenne).

| Mesure | Chars | Tokens `/4` | Tokens `/3.5` |
|---|---:|---:|---:|
| Total des 55 `SKILL.md` | 345 687 | 86 422 | 98 768 |
| **Moyenne / skill** | **6 285** | **1 571** | **1 796** |
| **Médiane / skill** | **6 862** | **1 716** | **1 961** |
| Min (`genius-*` le plus court) | 829 | 207 | 237 |
| Max (`genius-dev-web3`) | 12 841 | 3 210 | 3 669 |

> Un flow GT typique enchaîne plusieurs skills. À titre indicatif, un flow Phase 1 complet
> (interviewer → PMA → specs → designer → marketer → copywriter → integration → architect,
> soit ~8 skills) coûte environ **8 × 1 571 ≈ 12 600 tokens** (borne basse) à **8 × 1 796 ≈
> 14 400 tokens** (borne haute), en plus du startup.

---

## 4. Les 5 plus gros contributeurs

### 4a. Par `SKILL.md` complet (coût de chargement d'un skill)

| # | Skill | Chars | Tokens `/4` | Tokens `/3.5` |
|---|---|---:|---:|---:|
| 1 | `genius-dev-web3` | 12 841 | 3 210 | 3 669 |
| 2 | `genius-team` | 11 330 | 2 832 | 3 237 |
| 3 | `genius-dev` | 9 816 | 2 454 | 2 805 |
| 4 | `genius-content` | 9 590 | 2 398 | 2 740 |
| 5 | `genius-dev-backend` | 9 576 | 2 394 | 2 736 |

### 4b. Par description frontmatter (coût au STARTUP — cible prioritaire du diet)

| # | Skill | Chars desc | Tokens `/4` | Tokens `/3.5` |
|---|---|---:|---:|---:|
| 1 | `genius-dev-web3` | 1 352 | 338 | 386 |
| 2 | `genius-dev` | 1 048 | 262 | 299 |
| 3 | `genius-crypto` | 672 | 168 | 192 |
| 4 | `genius-dev-mobile` | 635 | 159 | 181 |
| 5 | `genius-scheduler` | 605 | 151 | 173 |

> Description moyenne : **473 chars/skill** (~118-135 tok). Les descriptions sont le levier
> #1 du token diet au startup : elles sont payées à **chaque** session, pour **tous** les
> skills, qu'ils soient utilisés ou non. Réduire l'index de 55 descriptions de 27 007 chars
> est le gain le plus rentable.

---

## 5. Synthèse pour l'objectif -71%

| Référence baseline | Tokens `/4` | Tokens `/3.5` |
|---|---:|---:|
| **Startup natif** (§2a) | **7 620** | **8 709** |
| **Startup effectif** (§2b, avec GT-WORKFLOW + rules) | **11 052** | **12 631** |
| Coût moyen d'un skill chargé (§3) | 1 571 | 1 796 |
| Total des 55 skills si tous chargés (§3) | 86 422 | 98 768 |

**Cibles -71% (à atteindre par l'overhaul) :**

| Baseline | Valeur actuelle (`/4`) | Cible -71% (`/4`) | Valeur actuelle (`/3.5`) | Cible -71% (`/3.5`) |
|---|---:|---:|---:|---:|
| Startup natif | 7 620 | **2 210** | 8 709 | **2 526** |
| Startup effectif | 11 052 | **3 205** | 12 631 | **3 663** |
| Index des 55 descriptions | 6 752 | **1 958** | 7 716 | **2 238** |

Levier principal identifié : **l'index des 55 descriptions frontmatter** (§4b) domine le
startup. Un chargement à la demande (MCP / genius-store, cf. plan overhaul) qui n'exposerait
au démarrage qu'un sous-ensemble de descriptions courtes est le chemin direct vers -71%.

---

## 6. Script de mesure (reproductible)

Script utilisé pour §1.3, §3, §4 (`scratchpad/measure.py`) — parse le frontmatter YAML,
agrège les tailles, calcule moyenne/médiane et top-5. À re-lancer pour toute nouvelle mesure :

```python
import os, re, glob, statistics
SKILLS = sorted(glob.glob(".claude/skills/*/SKILL.md"))
def toks(n): return (round(n/4), round(n/3.5))
def frontmatter(p):
    t = open(p, encoding="utf-8").read()
    m = re.match(r"^---\n(.*?)\n---\n", t, re.S)
    return m.group(1) if m else ""
def field(fm, key):
    m = re.search(r"^"+key+r":\s*(.*?)(?=\n[a-zA-Z_]+:\s|\Z)", fm, re.S|re.M)
    return m.group(1).strip() if m else ""
# descriptions (startup index)
desc_total = sum(len(field(frontmatter(p), "description")) for p in SKILLS)
name_total = sum(len(field(frontmatter(p), "name")) for p in SKILLS)
print("index chars:", desc_total + name_total + 2*len(SKILLS), toks(desc_total+name_total+2*len(SKILLS)))
# full SKILL.md
sizes = [os.path.getsize(p) for p in SKILLS]
print("total:", sum(sizes), "mean:", round(statistics.mean(sizes)), "median:", round(statistics.median(sizes)))
```

Commandes shell de vérification rapide :

```bash
find .claude/skills -name SKILL.md | wc -l                    # 55
find .claude/skills -name SKILL.md -exec cat {} + | wc -c     # 345687
wc -c CLAUDE.md .genius/GT-WORKFLOW.md                        # 2997 / 4267
find .claude/rules -name '*.md' -exec cat {} + | wc -c        # 9461
```

---

## 7. Notes et hypothèses

- **Approximation chars→tokens** : `/4` et `/3.5` sont des bornes empiriques, pas le
  tokenizer réel. Pour un chiffrage exact, utiliser l'endpoint `count_tokens` de l'API
  Anthropic sur le contexte assemblé (hors scope de cet item, lecture seule).
- **`GT-WORKFLOW.md` et `.claude/rules/`** ne sont pas des imports `@` de `CLAUDE.md` : ils
  sont classés en « contexte effectif » (§2b) car injectés par le harness/flow GT, pas par
  le mécanisme natif d'auto-load de Claude Code.
- **BRIEFING.md** varie selon l'historique projet ; mesuré ici sur un projet vierge
  (`NOT_STARTED`, 341 chars). Sur un projet mature il grossit — c'est une source de dérive
  à re-mesurer avant/après overhaul.
- **Le hook `SessionStart` a été exécuté** conformément à la consigne ; effet de bord =
  création d'artefacts `.genius/` non suivis (aucun fichier existant touché).
- Baseline figée au **2026-07-02** ; toute comparaison future doit rejouer les commandes de
  §1 et §6 sur le même repo pour être valide.

---

## After P4-03 (progressive disclosure)

> **Date de mesure :** 2026-07-03 — item P4-03 (Phase 4). Les 12 plus gros `SKILL.md` ont
> été réduits au niveau 1-2 (rôle, triggers, workflow essentiel), les détails verbeux
> (exemples longs, templates, checklists exhaustives) déplacés dans un `references/*.md`
> chargé à la demande. Frontmatter `name`/`description` **inchangé** (routing identique).
> Méthode : `wc -c` avant (HEAD) → après (working tree).

### Avant → après par skill traité (bytes)

| Skill | Avant | Après | Gain | Fichier references |
|---|---:|---:|---:|---|
| `genius-dev-web3` | 12 841 | 5 883 | -54,2 % | `web3-details.md` |
| `genius-team` | 11 330 | 5 952 | -47,5 % | `routing-details.md` |
| `genius-dev` | 9 993 | 5 529 | -44,7 % | `dev-details.md` |
| `genius-orchestrator` | 9 889 | 5 992 | -39,4 % | `execution-details.md` |
| `genius-content` | 9 590 | 3 998 | -58,3 % | `content-templates.md` |
| `genius-dev-backend` | 9 576 | 3 836 | -59,9 % | `backend-patterns.md` |
| `genius-designer` | 8 951 | 5 058 | -43,5 % | `design-details.md` |
| `genius-accessibility` | 8 951 | 4 026 | -55,0 % | `a11y-details.md` |
| `genius-omni-router` | 8 638 | 4 889 | -43,4 % | `omni-routing-details.md` |
| `genius-playground-generator` | 8 552 | 4 830 | -43,5 % | `playground-details.md` |
| `genius-dev-mobile` | 8 288 | 4 309 | -48,0 % | `mobile-patterns.md` |
| `genius-skill-creator` | 8 266 | 4 835 | -41,5 % | `skill-templates.md` |
| **TOTAL (12 skills)** | **114 865** | **59 137** | **-48,5 %** | |

### Gain sur un `skill_get` typique (niveau 1-2 seul)

Un `skill_get` (chargement du `SKILL.md` complet à l'activation, via Store ou natif) sur
un de ces 12 skills ne paie plus que le niveau 1-2 ; le `references/*.md` n'est lu que si
le skill en a réellement besoin (progressive disclosure niveau 3).

| Mesure (sur les 12 skills traités) | Avant | Après | Gain |
|---|---:|---:|---:|
| Moyenne bytes / skill | 9 572 | 4 928 | **-48,5 %** |
| Médiane bytes / skill | 9 264 | 4 862 | -47,5 % |
| Moyenne tokens `/4` / `skill_get` | 2 393 | 1 232 | -1 161 tok |
| Moyenne des gains par skill | | | **-48,2 %** |
| Médiane des gains par skill | | | **-46,1 %** |

> Lecture : un `skill_get` typique sur un gros skill coûte désormais **~1 160 tokens de
> moins** (borne `/4`). Aucune perte d'information : tout le contenu retiré est dans le
> `references/*.md` du skill (liens relatifs vérifiés) ; `validate-skills.sh` reste vert
> (0 erreur, 2 warnings pré-existants genius-import), 0 skill > 10 KB parmi les traités,
> descriptions frontmatter (index startup) strictement inchangées.
