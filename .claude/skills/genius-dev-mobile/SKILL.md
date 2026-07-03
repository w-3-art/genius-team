---
name: genius-dev-mobile
description: >-
  Specialized mobile development skill. Builds React Native / Expo apps for iOS and Android.
  Handles native APIs (camera, location, push notifications, biometrics), navigation,
  offline-first patterns, and App Store submission prep.
  Use when task involves "React Native", "Expo", "mobile app", "iOS", "Android",
  "push notifications", "mobile navigation", "native features", "mobile version",
  "build for mobile", "mobile-responsive" (when meaning a native app, not CSS media queries).
  Do NOT use for responsive web design or CSS media queries (genius-dev-frontend).
  Do NOT use for pure backend APIs (genius-dev-backend).
context: fork
agent: genius-dev-mobile
user-invocable: false
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Glob(*)
  - Grep(*)
  - Bash(npm *)
  - Bash(npx *)
  - Bash(node *)
  - Bash(git diff*)
  - Bash(git status*)
hooks:
  PostToolUse:
    - type: command
      command: "bash -c 'echo \"[$(date +%H:%M:%S)] MOBILE: $TOOL_NAME\" >> .genius/dev.log 2>/dev/null || true'"
  Stop:
    - type: command
      command: "bash -c 'echo \"MOBILE COMPLETE: $(date)\" >> .genius/dev.log 2>/dev/null || true'"
      once: true
---

# Genius Dev Mobile v22 — Native Experience Builder

**One codebase, two platforms, zero compromises.**
All setup commands, code patterns, and store checklists: `references/mobile-patterns.md`
(matching § per topic below).

## Core Principles

1. **Cross-platform by default**: Write once, test on both iOS and Android
2. **Offline-first**: Assume connectivity is unreliable; cache aggressively
3. **Native feel**: Respect platform conventions (iOS vs Android patterns)
4. **Performance**: FlatList over ScrollView for lists, avoid unnecessary re-renders
5. **Privacy**: Request permissions only when needed, explain why in UI

## Workflow

1. **Detect the project** — Expo vs bare React Native via package.json / app.json
   (commands: § Project Detection).
2. **Setup / config** — `create-expo-app` for new projects; app.json (name, slug, iOS
   bundle ID, Android package, plugins); EAS Build for production (§ Expo Setup & Configuration).
3. **Implement with the standard patterns:**

| Topic | Pattern (reference §) |
|-------|----------------------|
| Navigation | React Navigation typed Stack Navigator; bottom-tabs when persistent nav needed (§ Navigation) |
| Native APIs | expo-camera / expo-location / expo-local-authentication — always handle permissions, biometrics with fallback (§ Native APIs) |
| Offline storage | MMKV for simple KV (preferred), AsyncStorage for larger cross-platform data; fetchWithCache offline-first pattern: cached-first, background refresh, stale indicator (§ Offline Storage) |
| Push notifications | expo-notifications + expo-device: handler config, physical-device check, permission request, Expo push token to backend, received listener (§ Push Notifications) |
| Performance | Virtualized FlatList (`getItemLayout`, `initialNumToRender`, `maxToRenderPerBatch`), memoized list items, stable handlers (§ Performance) |

4. **Test on simulator** — `npx expo start` (`--ios` / `--android` / `--tunnel` for
   physical device via Expo Go) (§ Testing on Simulator).
5. **Store prep** — iOS + Android submission checklists: bundle/package IDs, icons,
   privacy descriptions, permissions, EAS build + submit (§ App Store Submission Prep).

## Output

Mark `.genius/outputs/state.json` complete for `genius-dev-mobile` with a fresh timestamp.

## Handoff

- → **genius-qa-micro**: Detox E2E tests, Jest unit tests
- → **genius-dev-backend**: API endpoints the mobile app needs
- → **genius-dev-api**: Third-party SDK integrations (RevenueCat, Amplitude, etc.)
- → **genius-security**: Secure storage review, certificate pinning

## Playground Update

Refresh the existing dashboard tab with real mobile progress data and point the user to `.genius/DASHBOARD.html`.

## Definition of Done

- [ ] App builds and changed mobile flows run without new errors
- [ ] Platform-specific behaviors are verified or explicitly documented
- [ ] Required backend or SDK dependencies are coordinated with handoff skills
- [ ] genius-qa-micro validation completed for the task
- [ ] Dashboard or progress output reflects the delivered mobile work
