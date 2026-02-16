---
name: genius-product-market-analyst
description: Market research and business strategy skill that validates product-market fit, analyzes competition, identifies market gaps, and proposes business models. Use for "market research", "competitor analysis", "validate idea", "business model", "product-market fit", "pricing", "TAM SAM SOM".
---

## ⚠️ MANDATORY ARTIFACT

**This skill MUST generate:**
- XML: `.claude/discovery/MARKET-ANALYSIS.xml`
- HTML Playground: `.genius/outputs/MARKET-ANALYSIS.html`

**Before transitioning to next skill:**
1. Verify XML exists
2. Verify HTML playground exists
3. Update state.json checkpoint
4. Announce transition

**If artifacts missing:** DO NOT proceed. Generate them first.

---

# Genius Product Market Analyst v9.0 — Strategic Intelligence

**Turn ideas into validated opportunities.**

## Memory Integration

### On Session Start
Read `@.genius/memory/BRIEFING.md` for project context and existing research.

### During Analysis
Append to `.genius/memory/decisions.json`:
```json
{"id": "d-XXX", "decision": "MARKET: [finding]", "reason": "source: [source], confidence: [level]", "timestamp": "ISO-date", "tags": ["market", "research"]}
```

### On Complete
Append to `.genius/memory/decisions.json`:
```json
{"id": "d-XXX", "decision": "MARKET ANALYSIS COMPLETE: TAM=[tam] | Opportunity=[gap]", "reason": "analysis done", "timestamp": "ISO-date", "tags": ["market", "complete"]}
```

---

## Analysis Framework

1. **OPPORTUNITY ASSESSMENT** — Problem validation, urgency, frequency, willingness to pay
2. **COMPETITIVE LANDSCAPE** — Direct/indirect competitors, positioning map
3. **MARKET SIZING** — TAM/SAM/SOM with bottom-up validation
4. **BUSINESS MODEL** — Revenue streams, pricing strategy, unit economics
5. **GO-TO-MARKET** — Channel strategy, launch approach

---

## Opportunity Score

```
SCORE = (Urgency x 2) + (Frequency x 2) + (WTP x 3)

25-35: Strong opportunity
15-24: Moderate — needs refinement
<15:   Weak — pivot or validate more
```

---

## Output: MARKET-ANALYSIS.xml

Structured XML with: executive summary, market size, opportunity assessment, competitors, positioning, business model, market risks, next steps.

---

## Playground Integration

### Flow avec Market Simulator

1. **Analyser le marché** — TAM/SAM/SOM, competitors, pricing (méthode classique)
2. **Générer le playground** — Copier le template et injecter les données
3. **Présenter au user** — Ouvrir pour simulation interactive
4. **Validation** — User ajuste, explore, copie le prompt output
5. **Continuer** — Le prompt output devient la stratégie marché validée

### Génération du Playground

```bash
# Copier le template
cp playgrounds/templates/market-simulator.html .genius/outputs/MARKET-ANALYSIS.html
```

Puis injecter les données en modifiant le bloc `const state = {...}` dans le HTML :

```javascript
const state = {
    price: [PRIX_UNITAIRE],           // ex: 49 (€/mois)
    tam: [TAILLE_MARCHE],             // ex: 500000 (utilisateurs)
    conversion: [TAUX_CONVERSION],     // ex: 2.5 (%)
    churn: [CHURN_MENSUEL],           // ex: 5 (%)
    cac: [COUT_ACQUISITION],          // ex: 25 (€)
    preset: 'realistic',
    competitors: [
        { 
            name: 'Votre produit', 
            color: '#58a6ff', 
            scores: { prix: [SCORE], features: [SCORE], ux: [SCORE], brand: [SCORE], support: [SCORE] }
        },
        { 
            name: '[COMPETITOR_1_NAME]', 
            color: '#f85149', 
            scores: { prix: [SCORE], features: [SCORE], ux: [SCORE], brand: [SCORE], support: [SCORE] }
        },
        // ... autres competitors
    ]
};
```

### Données à injecter

| Donnée | Type | Description | Exemple |
|--------|------|-------------|---------|
| `price` | number | Prix unitaire mensuel (€) | `49` |
| `tam` | number | Taille marché cible (utilisateurs) | `500000` |
| `conversion` | number | Taux de conversion estimé (%) | `2.5` |
| `churn` | number | Churn mensuel estimé (%) | `5` |
| `cac` | number | Coût d'acquisition client (€) | `25` |
| `competitors` | array | Liste des concurrents avec scores | voir ci-dessous |

#### Structure Competitor

```javascript
{
    name: "Nom du concurrent",
    color: "#hexcolor",  // #58a6ff (vous), #f85149 (rouge), #3fb950 (vert), #d29922 (orange)
    scores: {
        prix: 7,        // 1-10, compétitivité prix
        features: 8,    // 1-10, richesse fonctionnelle
        ux: 8,          // 1-10, qualité UX
        brand: 5,       // 1-10, notoriété/réputation
        support: 7      // 1-10, qualité support client
    }
}
```

### Projections automatiques

Le playground calcule automatiquement :
- **TAM/SAM/SOM** — SAM = 33% du TAM, SOM = 33% du SAM
- **LTV** — price × (1 / churn_rate)
- **LTV/CAC Ratio** — LTV / CAC (🟢 ≥3x, 🟡 2-3x, 🔴 <2x)
- **Payback** — CAC / price (en mois)
- **3 scénarios** — Pessimiste (×0.6), Réaliste, Optimiste (×1.5)

### Exemple de prompt à canvas

```
Ouvre le playground market simulator pour [PROJECT_NAME].
L'utilisateur va pouvoir :
- Ajuster les paramètres (prix, conversion, churn...)
- Voir les projections en temps réel
- Comparer avec les concurrents sur le radar
- Copier l'analyse stratégique finale
```

### Workflow utilisateur

1. **Explorer les scénarios** — Cliquer Pessimiste/Réaliste/Optimiste
2. **Affiner les paramètres** — Ajuster les sliders selon ses hypothèses
3. **Analyser la compétition** — Voir le radar chart
4. **Valider la stratégie** — Copier le prompt output
5. **Continuer avec Genius** — Coller le prompt pour définir la stratégie finale

---

## Handoffs

### From: genius-interviewer
Receives: DISCOVERY.xml with project context

### To: genius-specs
Provides: MARKET-ANALYSIS.xml, competitive positioning, pricing recommendation

### To: genius-marketer
Provides: Positioning map, target segments, competitive intelligence
