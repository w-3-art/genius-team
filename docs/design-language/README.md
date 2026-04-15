# Genius Shared Design Language

Status: shared source of truth for the GT site and Cortex app UI.

## Direction

This language is built from:
- `proposition5` as the base system: editorial, warm, calm, premium
- `proposition1` as the energy accent layer: glow, motion, sharper CTA contrast

Visual target:
- warm dark surfaces
- gold-first accent system
- DM Sans as the primary typeface
- restrained motion, not noisy motion
- high clarity, low decoration overhead

## Non-negotiables

- One visual language across the GT site and the Cortex app.
- Cortex intelligence concepts stay readable and distinct from project artifacts.
- Do not introduce purple as a primary bias.
- Do not drift into generic SaaS gray.
- Keep emphasis on warmth, precision, and trust.

## File Map

- `tokens.json`
  - raw foundation tokens: colors, type, spacing, radius, shadow, motion
- `semantic.json`
  - mapped tokens for surfaces, text, navigation, actions, intelligence surfaces
- `motion.json`
  - durations, easings, and animation roles
- `copy.json`
  - canonical words, labels, and voice rules
- `tokens.css`
  - base CSS variables
- `components.css`
  - shared component primitives
- `site.css`
  - site shell and marketing surfaces
- `app.css`
  - Cortex app shell and control-tower surfaces

## Usage Rules

- Site pages must consume the shared language, not invent new colors or spacing.
- Cortex app screens must consume the same tokens and semantic roles.
- Intelligence layer UI must use the shared language, but remain visually distinct from project artifact views.
- Shared components should prefer semantic names like `surface`, `panel`, `chip`, `button`, `hero`, `metric`, `diff`, `provenance`.

## Intended Product Read

- Genius Team = build framework for each repo.
- Cortex = transverse control tower for multiple GT repos.
- Intelligence layer = Behaviors, Rules, Memory Bits, Personas, Code Bits, Glossary.

