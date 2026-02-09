# Harmonic Beacon Mobile -- React Native PoC Results

**Platform:** React Native (Expo SDK 54, React 19, RN 0.81)
**Branch:** `poc/react-native`
**Date:** ____-__-__
**Tester:** _______________
**Device(s):** _______________

---

## Test Results

### Test 1: Dual Source Playback
- [ ] Connect to LiveKit beacon room, receive audio track
- [ ] Load local meditation file (use `la_mosca.m4a` -- 52 seconds)
- [ ] Both sources audible simultaneously
- **Pass criteria:** Two distinct audio sources playing together

**Result:** PASS / FAIL / PARTIAL
**Notes:**

---

### Test 2: Crossfader Volume Control
- [ ] Move slider to 0.0 -- only beacon audible
- [ ] Move slider to 0.5 -- both audible, beacon slightly lower
- [ ] Move slider to 1.0 -- only meditation audible
- [ ] Move slider smoothly left-right -- no clicks, pops, or glitches
- **Pass criteria:** Smooth, glitch-free crossfade between sources

**Result:** PASS / FAIL / PARTIAL
**Notes:**

---

### Test 3: Fader Latency
- [ ] Move fader rapidly back and forth 10 times
- [ ] Observe if volume changes feel instant or laggy
- **Pass criteria:** Volume changes perceptible within <50ms of fader movement
- **Bonus:** Record a screen capture with audio for comparison

**Result:** PASS / FAIL / PARTIAL
**Estimated latency:** ___ms
**Notes:**

---

### Test 4: Background Audio (Screen Lock)
- [ ] Start both sources playing with fader at 0.5
- [ ] Lock the phone screen
- [ ] Wait 30 seconds
- **Pass criteria:** Both sources continue playing, mix preserved

**Result:** PASS / FAIL / PARTIAL
**Notes:**

---

### Test 5: Background Audio (App Switch)
- [ ] Start both sources playing
- [ ] Switch to another app (browser, settings)
- [ ] Wait 30 seconds, switch back
- **Pass criteria:** Both sources still playing, can adjust fader

**Result:** PASS / FAIL / PARTIAL
**Notes:**

---

### Test 6: Lock Screen Controls
- [ ] Start meditation + beacon playing
- [ ] Lock screen
- [ ] Use lock screen media controls (play/pause)
- **Pass criteria:** Play/pause affects meditation, beacon continues
- **Bonus:** Lock screen shows meditation title/progress

**Result:** PASS / FAIL / PARTIAL
**Notes:**

---

### Test 7: Audio Interruption Recovery
- [ ] Start both sources playing
- [ ] Trigger a phone notification with sound
- **Pass criteria:** Both sources resume after notification
- [ ] Trigger an incoming phone call (or simulate)
- **Pass criteria:** Both sources resume after call ends

**Result:** PASS / FAIL / PARTIAL
**Notes:**

---

### Test 8: Network Transition (Stretch Goal)
- [ ] Start both sources playing on WiFi
- [ ] Disable WiFi (force cellular)
- **Observe:** Does LiveKit reconnect? How long is the gap?
- **Pass criteria:** Meditation continues uninterrupted, beacon reconnects

**Result:** PASS / FAIL / PARTIAL
**Reconnection time:** ___s
**Notes:**

---

### Test 9: Seek During Mix
- [ ] Both sources playing
- [ ] Seek meditation to a different position
- **Pass criteria:** Beacon unaffected, meditation jumps correctly

**Result:** PASS / FAIL / PARTIAL
**Notes:**

---

### Test 10: Battery Baseline
- [ ] Note battery level: ___%
- [ ] Play both sources for 15 minutes with screen off
- [ ] Note battery level: ___%
- **Record:** Battery drain % over 15 minutes

**Result:** ___% drain over 15 minutes
**Notes:**

---

## Scoring

| Criteria | Weight | Score (0-3) | Weighted |
|---|---|---|---|
| Dual playback works | 20% | | |
| Crossfader smoothness | 20% | | |
| Background audio | 25% | | |
| Lock screen controls | 10% | | |
| Interruption recovery | 10% | | |
| Setup complexity | 15% | | |
| **Weighted Average** | | | **___** |

**Score key:** 0=broken, 1=barely works, 2=works with issues, 3=flawless

---

## Key Findings

### Beacon Volume Control (CRITICAL)
- **Method used:** `setVolume()` / `mediaStreamTrack.enabled` / other: ___
- **Granular volume control available:** YES / NO
- **Workaround needed:** ___
- **Details:**

### Audio Session Conflicts
- **LiveKit overrides expo-av audio session:** YES / NO
- **Re-apply needed after connect:** YES / NO
- **Details:**

### Other Observations
-
-
-

---

## Edge Cases (Optional)

- **Bluetooth connect/disconnect:** ___
- **Another music app starts:** ___
- **Voice assistant activation:** ___
- **Notification with sound:** ___

---

## Recommendation

PASS / FAIL for production use

**Summary:**
