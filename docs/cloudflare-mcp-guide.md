# Cloudflare Code Mode MCP — Guide genius-dev

## Qu'est-ce que Code Mode ?

Cloudflare Code Mode est un pattern MCP qui réduit le coût en tokens de l'accès à une API externe de **1,17M tokens → ~1 000 tokens**.

Au lieu de définir des centaines de tools MCP avec leurs schemas JSON, un server Code Mode n'expose que 2 tools :
- `run_code(code)` — exécute du code dans un sandbox Cloudflare Workers
- `get_docs(topic)` — récupère la documentation à la demande

## Pourquoi c'est important pour genius-dev

genius-dev travaille sur du code. Quand un projet a besoin d'intégrer des APIs externes (Stripe, Supabase, Resend, etc.), sans Code Mode chaque connexion MCP coûte des dizaines de milliers de tokens juste pour les définitions de tools.

Avec Code Mode, genius-dev peut avoir accès à **5-10 APIs simultanément** pour ~1 000 tokens fixes.

## Utilisation dans genius-dev

### Prérequis
- Un MCP server Cloudflare Code Mode actif (local ou distant)
- Configuré dans `.claude/settings.json` ou `mcp_servers.json`

### Configuration MCP (settings.json)

```json
{
  "mcpServers": {
    "cloudflare-code-mode": {
      "command": "npx",
      "args": ["cloudflare-mcp-server"],
      "env": {
        "CLOUDFLARE_API_TOKEN": "${CLOUDFLARE_API_TOKEN}"
      }
    }
  }
}
```

### Pattern genius-dev avec Code Mode

Quand genius-dev a besoin d'intégrer une API :

1. **Sans Code Mode** : MCP expose 200+ tools → 500K tokens de définitions → contexte saturé
2. **Avec Code Mode** : MCP expose `run_code` + `get_docs` → 1K tokens → genius-dev génère du code JS qui appelle l'API directement

Exemple d'usage dans genius-dev :
```
get_docs("stripe create payment intent")
→ Returns: minimal doc for that specific operation

run_code(`
  const stripe = require('stripe')(process.env.STRIPE_KEY);
  const intent = await stripe.paymentIntents.create({ amount: 2000, currency: 'eur' });
  return intent;
`)
→ Returns: execution result with real data
```

## Activation dans genius-dev SKILL.md

Si `GENIUS_MCP_CODE_MODE=true` est dans l'environnement, genius-dev peut utiliser ce pattern :
- Préférer `run_code()` pour tester des intégrations API avant d'écrire le code définitif
- Utiliser `get_docs()` pour récupérer uniquement la doc nécessaire (pas tout le schema)
- Résultat : intégrations API plus rapides, moins de tokens, sandbox sécurisé

## Ressources
- Blog Cloudflare : https://blog.cloudflare.com/code-mode-mcp/
- MCP server npm : `npx cloudflare-mcp-server`
