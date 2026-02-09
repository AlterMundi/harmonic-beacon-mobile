# Dual-Audio Mix PoC — Technical Audit

**Date**: 2026-02-09
**Scope**: `POC_SPEC.md`, `POC_REACT_NATIVE.md`, `POC_FLUTTER.md`, `GAP_ANALYSIS.md`, existing codebase
**Status**: Audit complete, fixes applied

---

## Verdict

**Good framing, but the React Native path has an under-addressed blocking risk.**

The documents are well-structured and the PoC is correctly scoped as a focused go/no-go validation. However, there were significant issues that needed resolution before starting implementation. This audit identifies all findings and documents the fixes applied.

---

## 1. Blocking Issue: LiveKit Track Volume in React Native

The central question of the entire PoC was left unresolved in the plan.

`POC_REACT_NATIVE.md` Step 3 correctly identifies that `RemoteAudioTrack` in `@livekit/react-native` has **no direct volume API**. Four approaches are listed (a-d), but:

| Approach | Assessment |
|---|---|
| **(a)** `RTCRtpReceiver` volume control | Speculative. `react-native-webrtc` does not expose per-track volume on the receiver. No evidence this works. |
| **(b)** Web Audio API | Not available in React Native. Dead end. |
| **(c)** Custom native module | Feasible but adds days of platform-specific work (Kotlin + Swift). Undercuts the 7-day timeline. |
| **(d)** Route LiveKit through expo-av | Described as "guaranteed to work" but there's no mechanism to capture WebRTC audio output and pipe it into an expo-av Sound instance. This is approach (c) in disguise. |

**Recommendation:** Do a **2-hour spike** on LiveKit RN volume control before committing to the 7-day plan. If it fails, the Flutter path is the clear winner since `livekit_client` has first-class `track.setVolume(double)`.

---

## 2. Audio Session Conflict (Both Paths)

Both plans acknowledge that LiveKit's WebRTC layer and the meditation player will fight over the platform audio session. The original mitigations were weak:

- **RN plan:** "Configure `InterruptionModeIOS.MixWithOthers`" — but LiveKit's `react-native-webrtc` sets `.playAndRecord` (enables mic, defaults to earpiece). Setting MixWithOthers first may be overridden when LiveKit connects.
- **Flutter plan:** "Set `audio_session` BEFORE LiveKit connects" — same problem. LiveKit's native SDK may reconfigure the session.

### Fix Applied

Both plans now include concrete mitigation steps:
1. Log the actual `AVAudioSession` category after LiveKit connects to detect overrides
2. Re-apply audio session config in a `RoomEvent.Connected` callback
3. Test earpiece vs speaker output (`.playAndRecord` defaults to earpiece, not speaker)

---

## 3. Inconsistencies Found and Fixed

| Item | Was | Fixed To | File |
|---|---|---|---|
| Token TTL | 24h in POC_SPEC.md, 7d in script | 7 days everywhere | `POC_SPEC.md` |
| `shouldDuckAndroid` | `true` in AudioContext.tsx | `false` (we control volumes via crossfader) | `AudioContext.tsx` |
| Audio mode options | 3 options set | 6 options set (added `interruptionModeIOS`, `interruptionModeAndroid`, `playThroughEarpieceAndroid`) | `AudioContext.tsx` |
| Mic permission text | "This app does not use the microphone" | "Required for WebRTC audio sessions with the live beacon" | `app.json` |
| Lock screen in RN DoD | Missing | Added "Lock screen shows meditation controls" | `POC_REACT_NATIVE.md` |
| Flutter BeaconService API | Used `addListener`/`removeListener` (v1.x) | Updated to `on<Event>()` callbacks (v2.x) | `POC_FLUTTER.md` |

---

## 4. Missing Elements Added

### 4a. Decision Framework (added to POC_SPEC.md)
- Guidelines for all scoring scenarios (both pass, one passes, neither passes)
- Switching cost factors explicitly listed (UI rewrite, team ramp-up, CI/CD, iOS builds)
- Threshold: Flutter must lead by >= 0.5 AND score 3.0 on crossfader smoothness to justify a rewrite

### 4b. Reconnection Strategy (added to POC_SPEC.md)
- `RoomEvent.Reconnecting` / `RoomEvent.Reconnected` handlers required
- UI indicator for beacon reconnection state
- Meditation must continue uninterrupted during reconnection
- Also added reconnection event handlers to Flutter BeaconService code

### 4c. Local Dev Server (added to POC_SPEC.md)
- Docker command for local LiveKit server as fallback
- Dev mode credentials documented
- Prevents blocking if production server has issues during PoC week

### 4d. Audio Focus Edge Cases (added to POC_SPEC.md)
- Bluetooth headphones connect/disconnect
- Another music app starts playing
- Voice assistant activation
- Not required for pass, but should be documented in RESULTS.md

### 4e. Build Configuration Note (added to POC_SPEC.md)
- `expo prebuild --clean` required after adding background audio config
- Expo Go will not work with native modules
- Development builds are required for both paths

---

## 5. Code Accuracy Issues

### 5a. Flutter BeaconService API — Fixed
`POC_FLUTTER.md` Step 3 used `_room!.addListener(_onRoomEvent)` which doesn't match `livekit_client` v2.x API.

**Before:** Single listener function with type-checking
**After:** Event-specific `on<T>()` callbacks, `dispose()` instead of `removeListener`, added reconnection event handlers, fixed participant track iteration

### 5b. Token Script — Acceptable with Caveats
`scripts/generate-livekit-token.js` manually implements JWT signing with HMAC-SHA256. This works but is fragile. LiveKit tokens have a specific grant structure.

**Recommendation:** Verify the generated token works against the real server before starting the PoC. Consider switching to `livekit-server-sdk` if issues arise, but the current script is acceptable for a PoC.

### 5c. expo-av Deprecation Warning
The project uses `expo-av` v16.0.8 (Expo SDK 54). `expo-av` is deprecated and will be replaced by `expo-audio` in a future SDK version. This does not affect the PoC (short-lived), but the Phase roadmap in GAP_ANALYSIS.md (12-17 weeks) should plan for migration to `expo-audio` if the RN path is chosen.

### 5d. AudioContext.tsx Constants — Fixed
Initial fix used removed constant names (`Audio.INTERRUPTION_MODE_IOS_MIX_WITH_OTHERS`). Corrected to SDK 54 enum imports: `InterruptionModeIOS.MixWithOthers` and `InterruptionModeAndroid.DuckOthers` imported from `expo-av`.

---

## 6. Timeline Risk Assessment

The 7-day timeline is aggressive for both paths:

| Day | RN Path Risk | Flutter Path Risk |
|---|---|---|
| 1-2 | Dev build setup (no more Expo Go) + LiveKit SDK. **Volume control spike could consume both days.** | Creating Flutter project from scratch + Dart patterns |
| 3-4 | Audio session conflict debugging could stall crossfader | Same risks, but `setVolume()` should work immediately |
| 5 | Lock screen controls need a library decision first | `audio_service` is well-documented, lower risk |
| 6-7 | Test execution assumes everything works. **No buffer for debugging.** | Same concern |

**Recommendation:** Add 2 buffer days OR cut lock screen controls (Test 6) from the initial pass. Lock screen can be a stretch goal.

---

## 7. Strengths (What's Working Well)

- **PoC scope is correctly narrow** — single question, go/no-go, explicit out-of-scope list
- **Test protocol is thorough** — 10 tests with clear pass criteria and a weighted rubric
- **Crossfader math is continuous** — both halves of the asymmetric curve meet at (0.5, 0.85, 1.0) with no discontinuity
- **Token generation script exists** and is zero-dependency
- **Existing AudioContext.tsx** proves the dual-source architecture works with HTTP streams — the PoC is truly just swapping the transport
- **GAP_ANALYSIS.md** properly frames the PoC as a gate before 12-17 weeks of investment

---

## 8. Pre-Start Checklist

Before beginning the PoC implementation:

- [x] Token TTL aligned across all docs (7 days)
- [x] Mic permission description updated to reflect WebRTC usage
- [x] Lock screen controls added to RN Definition of Done
- [x] Flutter BeaconService updated to livekit_client v2.x API
- [x] Audio session conflict mitigations added to both plans
- [x] Decision framework added to POC_SPEC.md
- [x] Reconnection strategy added
- [x] Local dev server fallback documented
- [x] Audio focus edge cases listed
- [x] Build configuration note added
- [x] AudioContext.tsx audio mode options fixed (6 options, shouldDuckAndroid=false)
- [ ] **Spike RN volume control (2 hours)** — install `@livekit/react-native`, connect to beacon room, attempt volume control. Result determines which path to prioritize.
- [ ] **Verify token script** works against `wss://live.altermundi.net`
- [ ] **Decide on lock screen library** (expo-av vs react-native-track-player) before Day 1

---

## Files Modified by This Audit

| File | Changes |
|---|---|
| `docs/POC_SPEC.md` | Token TTL fix, decision framework, reconnection strategy, local dev server, edge cases, build note |
| `docs/POC_REACT_NATIVE.md` | Audio session conflict mitigations, lock screen in DoD |
| `docs/POC_FLUTTER.md` | BeaconService v2.x API fix, reconnection handlers, audio session conflict mitigations |
| `app.json` | Mic permission description updated |
| `context/AudioContext.tsx` | Added missing audio mode options, fixed shouldDuckAndroid |
| `docs/POC_AUDIT.md` | This file (new) |
