# Flutter LiveKit Dual-Audio Mix PoC - Test Results

## Test Environment
- **Device**: _[fill in]_
- **OS Version**: _[fill in]_
- **Flutter Version**: _[fill in]_
- **Date**: _[fill in]_

---

## Test 1: LiveKit Connection
**Description**: Connect to the LiveKit server and verify the beacon audio track is received.
- Connect to `wss://live.altermundi.net` with a valid token
- Verify connection status updates to "connected"
- Verify beacon track is detected from participant `beacon01`

**Result**: _[PASS / FAIL]_
**Notes**: _[fill in]_

---

## Test 2: Per-Track Volume Control (KEY TEST)
**Description**: Verify that `RemoteAudioTrack.setVolume()` adjusts the beacon audio level independently.
- Connect to beacon
- Use the volume slider on the Live screen
- Verify beacon volume changes without affecting system volume
- Test volume range from 0.0 (silent) to 1.0 (full)

**Result**: _[PASS / FAIL]_
**Notes**: _[fill in]_

---

## Test 3: Local Meditation Playback
**Description**: Play a local meditation audio file using just_audio.
- Navigate to the Meditate screen
- Tap on "La Mosca" meditation card
- Verify audio plays from the bundled asset
- Verify play/pause toggle works
- Verify seek slider updates position in real-time

**Result**: _[PASS / FAIL]_
**Notes**: _[fill in]_

---

## Test 4: Dual-Audio Simultaneous Playback
**Description**: Play both beacon (LiveKit) and meditation (just_audio) simultaneously.
- Start a meditation while beacon is connected
- Verify both audio streams play at the same time
- Verify no glitches, dropouts, or interference between streams

**Result**: _[PASS / FAIL]_
**Notes**: _[fill in]_

---

## Test 5: Crossfader Mix Control
**Description**: Verify the crossfader adjusts relative volumes between beacon and meditation.
- With both streams playing, use the crossfader slider
- Slide fully left: beacon loud, meditation silent
- Slide to center: both audible
- Slide fully right: meditation loud, beacon quiet
- Verify smooth transitions without pops or clicks

**Result**: _[PASS / FAIL]_
**Notes**: _[fill in]_

---

## Test 6: Background Audio
**Description**: Verify audio continues when the app is backgrounded.
- Start both beacon and meditation playback
- Press home button to background the app
- Verify audio continues playing
- Return to app and verify UI state is consistent

**Result**: _[PASS / FAIL]_
**Notes**: _[fill in]_

---

## Test 7: Reconnection Handling
**Description**: Verify the app handles network interruptions gracefully.
- Connect to beacon with meditation playing
- Toggle airplane mode or disable WiFi briefly
- Verify reconnecting state is shown (amber dot)
- Re-enable network
- Verify reconnection occurs and audio resumes

**Result**: _[PASS / FAIL]_
**Notes**: _[fill in]_

---

## Test 8: Audio Session Configuration
**Description**: Verify audio session is properly configured for mixing.
- Play meditation audio
- Open another app that plays audio (e.g., music player)
- Verify behavior matches AudioSession configuration (mix with others)
- Return to Harmonic Beacon and verify audio state

**Result**: _[PASS / FAIL]_
**Notes**: _[fill in]_

---

## Test 9: Memory and Performance
**Description**: Monitor resource usage during extended playback.
- Run both streams for 10+ minutes
- Monitor memory usage (Android Studio profiler or Xcode Instruments)
- Check for memory leaks or increasing resource consumption
- Note CPU usage during idle playback vs. active UI interaction

**Result**: _[PASS / FAIL]_
**Notes**: _[fill in]_

---

## Test 10: Edge Cases
**Description**: Test error handling and edge case scenarios.
- Start meditation without beacon connection (should play solo)
- Connect with invalid/expired token (should show error)
- Rapidly toggle play/pause on meditation
- Switch between meditations while one is playing
- Disconnect beacon while crossfader is not centered

**Result**: _[PASS / FAIL]_
**Notes**: _[fill in]_

---

## Summary

| Test | Description | Result |
|------|-------------|--------|
| 1 | LiveKit Connection | _[PASS/FAIL]_ |
| 2 | Per-Track Volume Control | _[PASS/FAIL]_ |
| 3 | Local Meditation Playback | _[PASS/FAIL]_ |
| 4 | Dual-Audio Simultaneous Playback | _[PASS/FAIL]_ |
| 5 | Crossfader Mix Control | _[PASS/FAIL]_ |
| 6 | Background Audio | _[PASS/FAIL]_ |
| 7 | Reconnection Handling | _[PASS/FAIL]_ |
| 8 | Audio Session Configuration | _[PASS/FAIL]_ |
| 9 | Memory and Performance | _[PASS/FAIL]_ |
| 10 | Edge Cases | _[PASS/FAIL]_ |

## Conclusion
_[Overall assessment of Flutter + LiveKit for the dual-audio mix use case]_
