---
name: genius-i18n
description: >-
  Internationalization (i18n) setup and translation workflow skill. Configures i18n
  frameworks, extracts translation strings, sets up locale routing, and handles RTL.
  Use when user says "add translations", "multi-language", "i18n setup", "locale",
  "RTL support", "translate the app", "French version", "international",
  "pluralization", "date formatting", "number formatting", "locale routing".
  Do NOT use for copy writing (genius-copywriter) or content creation (genius-content).
context: fork
agent: >-
  You are the Internationalization Engineer on the Genius Team. You configure
  i18n frameworks, design locale file structures, and set up translation workflows
  that scale to dozens of languages without breaking.
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - exec
hooks:
  pre: read .genius/state.json
  post: update .genius/state.json with i18n.framework and i18n.locales
---

# genius-i18n — Internationalization Setup & Translation Workflow

## Principles

1. **Extract early** — Hard-coded strings compound. Start with i18n, not after.
2. **Keys, not values** — Use semantic keys (`nav.home`) not content (`Home`).
3. **Never hard-code locale logic** — Use library-provided formatters for dates, numbers, plurals.
4. **RTL is a layout concern, not a component concern** — Use CSS logical properties.

---

## Step-by-Step Protocol

### Step 1 — Audit Current State

```bash
# Find hard-coded strings (not exhaustive but catches obvious ones)
grep -rn '"[A-Z][a-z]' src/ --include="*.tsx" --include="*.jsx" | grep -v "//" | head -30
grep -rn "'[A-Z][a-z]" src/ --include="*.tsx" --include="*.jsx" | grep -v "//" | head -30

# Check if i18n is already configured
ls src/i18n* src/locales* messages/ 2>/dev/null
cat package.json | grep -E "next-intl|i18next|react-i18next|vue-i18n|i18n"
```

### Step 2 — Framework Selection

| Framework | Best For | Features |
|-----------|----------|---------|
| **next-intl** | Next.js App Router | Server components, route-based locale, TypeScript-first |
| **react-i18next** | React (Vite, CRA, non-Next) | Battle-tested, rich ecosystem, namespace support |
| **vue-i18n** | Vue.js / Nuxt | Official Vue integration, composition API |
| **Expo Localization** | React Native / Expo | Device locale detection, Expo-native |
| **i18next** (core) | Any JS framework | Universal, framework-agnostic |

### Step 3 — Setup (Next.js + next-intl)

```bash
npm install next-intl
```

**Directory structure:**

```
messages/
  en.json
  fr.json
  ar.json       # RTL
  ja.json
src/
  i18n/
    routing.ts  # Locale config
    request.ts  # Server-side locale resolution
  middleware.ts
  app/
    [locale]/
      layout.tsx
      page.tsx
```

```typescript
// src/i18n/routing.ts
import { defineRouting } from 'next-intl/routing'

export const routing = defineRouting({
  locales: ['en', 'fr', 'de', 'ar', 'ja'],
  defaultLocale: 'en',
  localePrefix: 'as-needed', // /fr/... but /... for default locale
})
```

```typescript
// src/middleware.ts
import createMiddleware from 'next-intl/middleware'
import { routing } from './i18n/routing'

export default createMiddleware(routing)

export const config = {
  matcher: ['/((?!api|_next|_vercel|.*\\..*).*)', '/'],
}
```

```typescript
// src/i18n/request.ts
import { getRequestConfig } from 'next-intl/server'
import { routing } from './routing'

export default getRequestConfig(async ({ requestLocale }) => {
  let locale = await requestLocale
  if (!locale || !routing.locales.includes(locale as any)) {
    locale = routing.defaultLocale
  }
  return {
    locale,
    messages: (await import(`../../messages/${locale}.json`)).default,
  }
})
```

```tsx
// app/[locale]/layout.tsx
import { NextIntlClientProvider } from 'next-intl'
import { getMessages } from 'next-intl/server'

export default async function LocaleLayout({ children, params }) {
  const { locale } = await params
  const messages = await getMessages()

  return (
    <html lang={locale} dir={locale === 'ar' ? 'rtl' : 'ltr'}>
      <body>
        <NextIntlClientProvider messages={messages}>
          {children}
        </NextIntlClientProvider>
      </body>
    </html>
  )
}
```

### Step 4 — Locale File Structure

```json
// messages/en.json
{
  "nav": {
    "home": "Home",
    "pricing": "Pricing",
    "about": "About"
  },
  "auth": {
    "sign_in": "Sign in",
    "sign_up": "Sign up",
    "sign_out": "Sign out",
    "errors": {
      "invalid_credentials": "Invalid email or password.",
      "email_required": "Email is required."
    }
  },
  "dashboard": {
    "welcome": "Welcome back, {name}!",
    "items_count": "{count, plural, =0 {No items} one {# item} other {# items}}"
  }
}
```

### Step 5 — Using Translations in Components

```tsx
// Server component
import { getTranslations } from 'next-intl/server'

export default async function Page() {
  const t = await getTranslations('dashboard')
  return <h1>{t('welcome', { name: 'Alice' })}</h1>
}

// Client component
'use client'
import { useTranslations } from 'next-intl'

export function NavItem() {
  const t = useTranslations('nav')
  return <a href="/">{t('home')}</a>
}

// Pluralization
const t = useTranslations('dashboard')
t('items_count', { count: 5 }) // "5 items"
t('items_count', { count: 1 }) // "1 item"
t('items_count', { count: 0 }) // "No items"
```

### Step 6 — Date, Number & Currency Formatting

```tsx
import { useFormatter } from 'next-intl'

function PriceDisplay({ amount, date }: { amount: number; date: Date }) {
  const format = useFormatter()

  return (
    <>
      {/* Currency — locale-aware */}
      <span>{format.number(amount, { style: 'currency', currency: 'USD' })}</span>
      {/* en: $29.00 | fr: 29,00 $ US | de: 29,00 $ */}

      {/* Relative time */}
      <span>{format.relativeTime(date)}</span>
      {/* en: "3 days ago" | fr: "il y a 3 jours" */}

      {/* Absolute date */}
      <span>{format.dateTime(date, { dateStyle: 'long' })}</span>
      {/* en: "March 10, 2026" | fr: "10 mars 2026" | ja: "2026年3月10日" */}
    </>
  )
}
```

### Step 7 — RTL Support

```css
/* ✅ Use CSS logical properties — they flip automatically with dir="rtl" */

/* Physical (avoid for RTL) → Logical (use this) */
/* margin-left → margin-inline-start */
/* margin-right → margin-inline-end */
/* padding-left → padding-inline-start */
/* padding-right → padding-inline-end */
/* border-left → border-inline-start */
/* text-align: left → text-align: start */

.nav-item {
  padding-inline: 1rem;
  margin-inline-end: 0.5rem;
  border-inline-start: 2px solid var(--brand);
}

/* For transforms that don't auto-flip */
[dir="rtl"] .arrow-icon {
  transform: scaleX(-1);
}
```

### Step 8 — String Extraction Workflow

```bash
# i18next-parser — extract strings from source code
npm install --save-dev i18next-parser

# i18next-parser.config.js
module.exports = {
  locales: ['en', 'fr', 'de'],
  defaultNamespace: 'common',
  output: 'messages/$LOCALE.json',
  input: ['src/**/*.{ts,tsx}'],
  keepRemoved: false,  // Remove keys no longer in source
}

# Run extraction
npx i18next-parser
```

### Step 9 — CI/CD: Missing Key Detection

```yaml
# .github/workflows/i18n-check.yml
name: i18n Check
on: [push, pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - name: Check missing translation keys
        run: |
          node -e "
          const en = require('./messages/en.json');
          const fr = require('./messages/fr.json');
          function getKeys(obj, prefix = '') {
            return Object.entries(obj).flatMap(([k, v]) =>
              typeof v === 'object' ? getKeys(v, prefix + k + '.') : [prefix + k]
            );
          }
          const missing = getKeys(en).filter(k => {
            const keys = k.split('.');
            let fr_val = fr;
            for (const key of keys) {
              if (!fr_val[key]) return true;
              fr_val = fr_val[key];
            }
            return false;
          });
          if (missing.length) {
            console.error('Missing FR keys:', missing);
            process.exit(1);
          }
          console.log('All keys present ✅');
          "
```

---

## Output

Update `.genius/state.json`:

```json
{
  "i18n": {
    "framework": "next-intl",
    "locales": ["en", "fr", "de", "ar"],
    "default_locale": "en",
    "rtl_locales": ["ar"],
    "messages_path": "messages/",
    "locale_routing": true,
    "ci_check": true
  }
}
```

---

## Handoff

- **→ genius-copywriter** — Provide locale file templates for professional translation
- **→ genius-dev-frontend** — Apply CSS logical properties across all components
- **→ genius-accessibility** — Ensure `lang` and `dir` attributes are set correctly on `<html>`


---

## Definition of Done

Internationalization work MUST be:
1. **Complete coverage**: Every user-visible string extracted to translation file
2. **Verified**: Run `i18n-check` or equivalent to verify no missing keys
3. **RTL tested**: If supporting Arabic/Hebrew/Persian, layout tested in RTL mode
4. **Pluralization handled**: All plural forms configured (not just 1/many)
5. **Date/time/currency**: All locale-sensitive values use locale-aware formatting

Never mark i18n complete without running a missing-key scan.
