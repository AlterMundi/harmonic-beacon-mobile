# PoC: React Native (Expo) — LiveKit Dual-Audio Mix

Branch: `poc/react-native`
Base: Existing Expo project on `main`

## Current State Assessment

The existing app **already has a working dual-audio mix** using `expo-av`:
- Source A (beacon): HTTP stream → `Audio.Sound` (`expo-av`)
- Source B (meditation): Local `.m4a` files → `Audio.Sound` (`expo-av`)
- Crossfader: Asymmetric curve in `meditate.tsx:handleMixChange()`
- Background audio: Configured (`staysActiveInBackground: true`)

### What Needs to Change

| Component | Current | PoC Target |
|---|---|---|
| Beacon source | HTTP stream (Lofi radio) | LiveKit WebRTC (`@livekit/react-native`) |
| Auth | Supabase (broken) | Hardcoded LiveKit token |
| Meditation source | Local files via `expo-av` | Same (no change needed) |
| Mix logic | `expo-av` volume on both | LiveKit track volume + `expo-av` volume |
| Background audio | `expo-av` config | LiveKit + `expo-av` coexistence |

### Key Risk: LiveKit WebRTC + expo-av Audio Session Conflict

`expo-av` sets `AVAudioSession` category via `Audio.setAudioModeAsync()`. LiveKit's `react-native-webrtc` also configures the audio session. These may conflict.

**Mitigation strategy:**
1. Let LiveKit configure the audio session (it needs `.playAndRecord`)
2. Configure `expo-av` to NOT override the audio session: use `Audio.setAudioModeAsync()` with `interruptionModeIOS: InterruptionModeIOS.MixWithOthers`
3. Test if both audio paths work simultaneously

---

## Implementation Plan

### Step 1: Install LiveKit Dependencies

```bash
npx expo install @livekit/react-native @livekit/react-native-webrtc
```

Also need to add Expo config plugin for WebRTC permissions:

```json
// app.json plugins
["@livekit/react-native-webrtc"]
```

**Note:** This requires a **development build** (not Expo Go), since LiveKit uses native modules. Set up with:
```bash
npx expo prebuild
npx expo run:android  # or run:ios
```

### Step 2: Token Generation

Create `utils/livekit-token.ts`:
```typescript
// For PoC: generate token locally using livekit-server-sdk
// OR hardcode a long-lived token from the webapp
export const LIVEKIT_URL = 'wss://live.altermundi.net';

// Option A: Hardcoded token (simplest for PoC)
export const BEACON_TOKEN = '<generate with livekit-cli>';

// Option B: Generate from API key/secret (requires livekit-server-sdk)
// Not ideal for client-side, but OK for PoC
```

**Recommended for PoC:** Use `livekit-cli` to generate a 7-day token:
```bash
livekit-cli create-token \
  --api-key <KEY> --api-secret <SECRET> \
  --room beacon --identity mobile-poc-rn \
  --valid-for 168h \
  --join --canSubscribe --canPublishData=false --canPublish=false
```

### Step 3: Modify AudioContext — Replace HTTP Stream with LiveKit

**File:** `context/AudioContext.tsx`

Replace the `expo-av` beacon sound with LiveKit room connection:

```typescript
import { Room, RoomEvent, Track, RemoteTrack, AudioTrack } from 'livekit-client';
// Note: @livekit/react-native patches livekit-client for RN compatibility
import { registerGlobals } from '@livekit/react-native';

// Call once at app startup
registerGlobals();
```

**Key changes to AudioContext:**
1. Remove `LIVE_STREAM_URL` and `loadSound()` (HTTP stream)
2. Add LiveKit `Room` connection in `useEffect`
3. Store reference to beacon audio track
4. **Volume control**: The critical question — how to control LiveKit track volume in RN

**LiveKit RN volume control investigation:**
- `@livekit/react-native` wraps `livekit-client` which uses `react-native-webrtc`
- `RemoteAudioTrack` in livekit-client has no direct `.volume` setter
- On web, volume is via `HTMLAudioElement.volume` after `track.attach()`
- On RN, there's no HTMLAudioElement — audio plays through WebRTC natively
- **Possible approaches:**
  a. Use `RTCRtpReceiver` to modify audio levels (low-level WebRTC API)
  b. Route LiveKit audio through an `AudioContext` (Web Audio API — not available in RN)
  c. Use the LiveKit native SDK's volume API via a custom native module
  d. Mute/unmute the track and control a separate `expo-av` sound that re-encodes

**Approach (d) is a fallback** if direct volume fails: capture LiveKit audio → pipe to expo-av → control volume there. Complex but guaranteed to work.

**Approach (a) is the best path**: `react-native-webrtc` exposes `RTCRtpReceiver`. Check if the receiver's `track` has volume control in the native layer.

### Step 4: Audio Session Coexistence

```typescript
import { Audio, InterruptionModeIOS, InterruptionModeAndroid } from 'expo-av';

// Initialize audio BEFORE LiveKit connects
await Audio.setAudioModeAsync({
    playsInSilentModeIOS: true,
    staysActiveInBackground: true,
    // CRITICAL: allow mixing with WebRTC audio
    interruptionModeIOS: InterruptionModeIOS.MixWithOthers,
    interruptionModeAndroid: InterruptionModeAndroid.DuckOthers,
    shouldDuckAndroid: false, // We control volumes ourselves
    playThroughEarpieceAndroid: false,
});
```

**Audio Session Conflict Mitigation (CRITICAL):**

LiveKit's `react-native-webrtc` will reconfigure `AVAudioSession` to `.playAndRecord` when connecting, which may override our `MixWithOthers` setting. Additionally, `.playAndRecord` defaults to earpiece output, not speaker.

**Required steps:**
1. **Log the actual session state** after LiveKit connects to verify our config wasn't overridden:
```typescript
// After room.connect() resolves, log iOS audio session state
// Use expo-av's Audio.getPermissionsAsync() or a native module to inspect
console.log('[AudioSession] Post-connect state — verify MixWithOthers is active');
```

2. **Re-apply audio config** in the room connected callback:
```typescript
room.on(RoomEvent.Connected, async () => {
    // Re-apply our audio session config — LiveKit may have overridden it
    await Audio.setAudioModeAsync({
        playsInSilentModeIOS: true,
        staysActiveInBackground: true,
        interruptionModeIOS: InterruptionModeIOS.MixWithOthers,
        interruptionModeAndroid: InterruptionModeAndroid.DuckOthers,
        shouldDuckAndroid: false,
        playThroughEarpieceAndroid: false,
    });
    console.log('[AudioSession] Re-applied MixWithOthers after LiveKit connected');
});
```

3. **Test earpiece vs speaker**: `.playAndRecord` defaults to earpiece on iOS. If audio is barely audible after LiveKit connects, this is why. Set `playThroughEarpieceAndroid: false` and test with `defaultToSpeaker` option if available.

### Step 5: Crossfader Integration

Modify `handleMixChange()` in `meditate.tsx`:
```typescript
const handleMixChange = (value: number) => {
    setMixValue(value);
    if (value <= 0.5) {
        const beaconVol = 1.0 - (value * 0.3);
        const medVol = value * 2;
        setBeaconVolume(beaconVol);    // → LiveKit track volume (TBD API)
        setMeditationVolume(medVol);   // → expo-av Sound.setVolumeAsync()
    } else {
        const beaconVol = (1 - value) * 1.7;
        setMeditationVolume(1.0);
        setBeaconVolume(beaconVol);
    }
};
```

### Step 6: Background Audio Configuration

**iOS (app.json):**
```json
{
  "ios": {
    "infoPlist": {
      "UIBackgroundModes": ["audio"],
      "NSMicrophoneUsageDescription": "Required for audio sessions"
    }
  }
}
```

**Android (app.json):**
```json
{
  "android": {
    "foregroundService": {
      "type": "mediaPlayback"
    }
  }
}
```

LiveKit maintains its WebSocket/WebRTC connection in background on both platforms IF the audio session is active.

### Step 7: Lock Screen Controls

Use `expo-av`'s built-in lock screen integration (limited) or `react-native-track-player` for richer controls.

**Lightweight approach (expo-av):**
- iOS: `Audio.setAudioModeAsync` with `staysActiveInBackground: true` enables basic now-playing info
- Set `Audio.Sound` metadata for lock screen display

**Full approach (react-native-track-player):**
- Replace meditation `expo-av` sound with `TrackPlayer`
- Provides full lock screen controls (play/pause/seek/metadata)
- But: `TrackPlayer` manages a single queue — beacon stays on LiveKit separately

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| LiveKit track volume not controllable in RN | HIGH | BLOCKING | Try RTCRtpReceiver API; fallback to native module |
| expo-av and WebRTC audio session conflict on iOS | MEDIUM | HIGH | Configure InterruptionModeIOS.MixWithOthers |
| Background audio stops after ~30s on iOS | MEDIUM | BLOCKING | Ensure UIBackgroundModes includes "audio" |
| Fader latency across JS bridge | LOW | MEDIUM | Acceptable for slow fader movement; measure actual ms |
| Dev build required (no Expo Go) | CERTAIN | LOW | Use `expo prebuild` + `expo run:android` |
| react-native-webrtc compatibility issues | MEDIUM | HIGH | Pin to version known-good with LiveKit SDK |

---

## File Changes Summary

| File | Action |
|---|---|
| `package.json` | Add `@livekit/react-native`, `@livekit/react-native-webrtc` |
| `app.json` | Add WebRTC plugin, background modes, foreground service |
| `context/AudioContext.tsx` | Replace HTTP stream with LiveKit Room connection |
| `context/AuthContext.tsx` | Gut entirely — replace with hardcoded token |
| `app/(tabs)/meditate.tsx` | Update fader to control LiveKit volume |
| `app/(tabs)/index.tsx` | Update Live tab for LiveKit connection status |
| `utils/livekit-token.ts` | New — token management |
| `RESULTS.md` | New — test results |

---

## Definition of Done

- [ ] App connects to LiveKit `beacon` room and receives audio
- [ ] Local meditation plays simultaneously via expo-av
- [ ] Fader controls volumes of both sources independently
- [ ] Locking phone does not stop either audio source
- [ ] Lock screen shows meditation controls (play/pause at minimum)
- [ ] All 10 tests from POC_SPEC.md executed and documented
