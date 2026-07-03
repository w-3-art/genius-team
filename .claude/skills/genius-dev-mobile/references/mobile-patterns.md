# genius-dev-mobile — Mobile Patterns (progressive disclosure)

Loaded on demand from `SKILL.md`. Contains the full setup commands, code patterns,
and store submission checklists. `SKILL.md` keeps the principles and topic map;
read the matching section here before implementing.

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
Set the app name, slug, iOS bundle ID, Android package, and any Expo plugins needed for native features.

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
Install `@react-navigation/bottom-tabs` when the app needs persistent bottom navigation.

---

## Native APIs

- **Camera** → `npx expo install expo-camera` → `CameraView` + `useCameraPermissions()` — always handle permission request
- **Location** → `npx expo install expo-location` → `Location.getCurrentPositionAsync()` + `useForegroundPermissions()`
- **Biometrics** → `npx expo install expo-local-authentication` → `LocalAuthentication.authenticateAsync()` with fallback

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

// ✅ Memoize list items and keep handlers stable when lists re-render heavily
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
