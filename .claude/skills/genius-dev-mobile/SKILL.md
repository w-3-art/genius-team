---
name: genius-dev-mobile
description: >-
  Specialized mobile development skill. Builds React Native / Expo apps for iOS and Android.
  Handles native APIs (camera, location, push notifications, biometrics), navigation,
  offline-first patterns, and App Store submission prep.
  Use when task involves "React Native", "Expo", "mobile app", "iOS", "Android",
  "push notifications", "mobile navigation", "native features".
  Do NOT use for web frontend (genius-dev-frontend) or pure backend APIs (genius-dev-backend).
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

# Genius Dev Mobile v17 — Native Experience Builder

**One codebase, two platforms, zero compromises.**

---

## Mode Compatibility

| Mode | Behavior |
|------|----------|
| **CLI** | Full Expo CLI execution, simulator commands, EAS build triggers |
| **IDE** (VS Code/Cursor) | Use Expo Go for live preview; Cursor handles component editing |
| **Omni** | Claude handles architecture; switch to best model for native-specific code |
| **Dual** | Claude designs navigation/state; Codex implements screen boilerplate |

---

## Core Principles

1. **Cross-platform by default**: Write once, test on both iOS and Android
2. **Offline-first**: Assume connectivity is unreliable; cache aggressively
3. **Native feel**: Respect platform conventions (iOS vs Android patterns)
4. **Performance**: FlatList over ScrollView for lists, avoid unnecessary re-renders
5. **Privacy**: Request permissions only when needed, explain why in UI

---

## Project Detection

```bash
# Detect Expo vs bare React Native
cat package.json | grep -E '"expo"|"react-native"'
ls app.json 2>/dev/null && cat app.json | grep '"expo"'
ls expo.json 2>/dev/null && echo "Expo project"
```

---

## Expo Setup & Configuration

### New project
```bash
npx create-expo-app@latest MyApp --template blank-typescript
cd MyApp
npx expo start
```

### Key config in `app.json`
```json
{
  "expo": {
    "name": "MyApp",
    "slug": "my-app",
    "version": "1.0.0",
    "ios": {
      "bundleIdentifier": "com.company.myapp",
      "buildNumber": "1"
    },
    "android": {
      "package": "com.company.myapp",
      "versionCode": 1
    },
    "plugins": [
      "expo-camera",
      "expo-location",
      ["expo-notifications", { "icon": "./assets/notification-icon.png" }]
    ]
  }
}
```

### EAS Build (production)
```bash
npm install -g eas-cli
eas login
eas build:configure
eas build --platform all  # iOS + Android
```

---

## Navigation (React Navigation)

### Setup
```bash
npm install @react-navigation/native @react-navigation/native-stack
npx expo install react-native-screens react-native-safe-area-context
```

### Stack Navigator pattern
```tsx
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

type RootStackParamList = {
  Home: undefined;
  Profile: { userId: string };
  Settings: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export function AppNavigator() {
  return (
    <NavigationContainer>
      <Stack.Navigator initialRouteName="Home">
        <Stack.Screen name="Home" component={HomeScreen} />
        <Stack.Screen name="Profile" component={ProfileScreen} />
        <Stack.Screen name="Settings" component={SettingsScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
```

### Tab Navigator (bottom tabs)
```bash
npm install @react-navigation/bottom-tabs
```

```tsx
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
const Tab = createBottomTabNavigator();

<Tab.Navigator screenOptions={{ tabBarActiveTintColor: '#007AFF' }}>
  <Tab.Screen name="Home" component={HomeScreen} options={{ tabBarIcon: ... }} />
  <Tab.Screen name="Search" component={SearchScreen} />
  <Tab.Screen name="Profile" component={ProfileScreen} />
</Tab.Navigator>
```

---

## Native APIs

### Camera → `npx expo install expo-camera` → `CameraView` + `useCameraPermissions()` — always handle permission request
### Location → `npx expo install expo-location` → `Location.getCurrentPositionAsync()` + `useForegroundPermissions()`
### Biometrics → `npx expo install expo-local-authentication` → `LocalAuthentication.authenticateAsync()` with fallback

---

## Offline Storage

### MMKV (fastest — preferred for simple KV)
```bash
npx expo install react-native-mmkv
```
```tsx
import { MMKV } from 'react-native-mmkv';
const storage = new MMKV();

storage.set('user.token', token);
const token = storage.getString('user.token');
storage.delete('user.token');
```

### AsyncStorage (cross-platform, larger data)
```bash
npx expo install @react-native-async-storage/async-storage
```
```tsx
import AsyncStorage from '@react-native-async-storage/async-storage';

await AsyncStorage.setItem('key', JSON.stringify(data));
const data = JSON.parse(await AsyncStorage.getItem('key') ?? 'null');
```

### Offline-first pattern
```tsx
// 1. Show cached data immediately
// 2. Fetch fresh data in background
// 3. Update UI when fresh data arrives
// 4. If fetch fails, show cached data with stale indicator

async function fetchWithCache<T>(key: string, fetcher: () => Promise<T>): Promise<T> {
  const cached = storage.getString(key);
  if (cached) setData(JSON.parse(cached)); // show immediately
  
  try {
    const fresh = await fetcher();
    storage.set(key, JSON.stringify(fresh));
    setData(fresh);
    return fresh;
  } catch (e) {
    if (!cached) throw e; // no fallback
    return JSON.parse(cached); // return stale
  }
}
```

---

## Push Notifications (Expo Notifications)

```bash
npx expo install expo-notifications expo-device
```

```tsx
import * as Notifications from 'expo-notifications';

// Configure notification behavior
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

// Register for push notifications
async function registerForPushNotifications() {
  if (!Device.isDevice) return null; // Must be physical device
  
  const { status } = await Notifications.requestPermissionsAsync();
  if (status !== 'granted') return null;
  
  const token = (await Notifications.getExpoPushTokenAsync({
    projectId: Constants.expoConfig?.extra?.eas?.projectId,
  })).data;
  
  return token; // Send this to your backend
}

// Listen for notifications
useEffect(() => {
  const sub = Notifications.addNotificationReceivedListener(notification => {
    console.log('Received:', notification);
  });
  return () => sub.remove();
}, []);
```

---

## Performance

```tsx
// ✅ FlatList for long lists (virtualized)
<FlatList
  data={items}
  keyExtractor={(item) => item.id}
  renderItem={({ item }) => <ItemRow item={item} />}
  getItemLayout={(_, index) => ({ length: 60, offset: 60 * index, index })}
  initialNumToRender={15}
  maxToRenderPerBatch={10}
/>

// ✅ Memoize list items
const ItemRow = memo(({ item }) => <View>...</View>);

// ✅ useCallback for handlers passed to list items
const handlePress = useCallback((id: string) => { ... }, []);

// ❌ Avoid anonymous functions in renderItem
```

---

## Testing on Simulator

```bash
# Start Expo
npx expo start

# Open iOS simulator
npx expo start --ios

# Open Android emulator
npx expo start --android

# Run on physical device via Expo Go
npx expo start --tunnel  # if on different network
```

---

## App Store Submission Prep

### iOS checklist
- [ ] Bundle identifier set (`com.company.app`)
- [ ] App icons: 1024x1024 in `assets/`
- [ ] Privacy descriptions in `app.json` (`NSCameraUsageDescription`, etc.)
- [ ] Build with EAS: `eas build --platform ios --profile production`
- [ ] Submit: `eas submit --platform ios`

### Android checklist
- [ ] Package name set (`com.company.app`)
- [ ] Keystore managed by EAS (auto)
- [ ] Permissions declared in `app.json`
- [ ] Build: `eas build --platform android --profile production`
- [ ] Submit: `eas submit --platform android`

---

## Output

Update `.genius/outputs/state.json` on completion:

```bash
jq --arg ts "$(date -Iseconds)" '.skill = "genius-dev-mobile" | .status = "complete" | .updatedAt = $ts' .genius/outputs/state.json > .genius/outputs/state.json.tmp && mv .genius/outputs/state.json.tmp .genius/outputs/state.json 2>/dev/null || true
```

---

## Handoff

- → **genius-qa-micro**: Detox E2E tests, Jest unit tests
- → **genius-dev-backend**: API endpoints the mobile app needs
- → **genius-dev-api**: Third-party SDK integrations (RevenueCat, Amplitude, etc.)
- → **genius-security**: Secure storage review, certificate pinning

---

## Playground Update (MANDATORY)

After completing your task:
1. **DO NOT create a new HTML file** — update the existing genius-dashboard tab
2. Open `.genius/DASHBOARD.html` and update YOUR tab's data section with real project data
3. If your tab doesn't exist yet, add it to the dashboard (hidden tabs become visible on first real data)
4. Remove any mock/placeholder data from your tab
5. Tell the user: `📊 Dashboard updated → open .genius/DASHBOARD.html`

## Definition of Done

- [ ] App builds and changed mobile flows run without new errors
- [ ] Platform-specific behaviors are verified or explicitly documented
- [ ] Required backend or SDK dependencies are coordinated with handoff skills
- [ ] genius-qa-micro validation completed for the task
- [ ] Dashboard or progress output reflects the delivered mobile work
