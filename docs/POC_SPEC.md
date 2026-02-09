# Harmonic Beacon Mobile — Dual-Audio Mix PoC Specification

## Goal

Prove that the **dual-audio crossfader mix** (live beacon + meditation overlay) works on mobile with:
1. LiveKit WebRTC as the beacon audio source (not an HTTP stream)
2. Local file playback as the meditation audio source
3. Independent per-source volume control (the crossfader)
4. Background audio survival (phone locked, app backgrounded)
5. Lock screen media controls

This is a **go/no-go test** for the mobile app architecture. Both React Native and Flutter implementations will be evaluated against identical criteria.

---

## Architecture: What We're Testing

```
┌──────────────────────────────────────────────┐
│              LiveKit Server                   │
│        wss://live.altermundi.net              │
│  Room: "beacon" → participant: "beacon01"    │
└──────────────┬───────────────────────────────┘
               │ WebRTC audio track
               ▼
┌──────────────────────────────────────────────┐
│            Mobile App                         │
│                                               │
│  ┌─────────────┐    ┌──────────────────┐     │
│  │  Source A    │    │    Source B       │     │
│  │  LiveKit SDK │    │  Native Player   │     │
│  │  (beacon)    │    │  (meditation.m4a)│     │
│  │  vol: 0-1    │    │  vol: 0-1        │     │
│  └──────┬──────┘    └────────┬─────────┘     │
│         │                    │                │
│         ▼                    ▼                │
│  ┌──────────────────────────────────────┐    │
│  │         Crossfader Mix               │    │
│  │  slider 0.0 ◄──────────► 1.0        │    │
│  │  (beacon)        (voice)             │    │
│  │                                       │    │
│  │  Asymmetric curve:                    │    │
│  │  mix ≤ 0.5: beaconVol = 1-(mix*0.3)  │    │
│  │             medVol = mix * 2          │    │
│  │  mix > 0.5: beaconVol = (1-mix)*1.7  │    │
│  │             medVol = 1.0              │    │
│  └──────────────────────────────────────┘    │
│                    │                          │
│                    ▼                          │
│             Speaker / Headphones              │
│           + Lock Screen Controls              │
└──────────────────────────────────────────────┘
```

---

## Server Infrastructure (shared by both PoCs)

Both PoCs connect to the **existing production LiveKit server**.

### Token Endpoint

The webapp already serves tokens at `GET /api/livekit/token`. For the PoC, we need a lightweight token generator that doesn't require the full webapp auth flow.

**Option A (recommended for PoC):** Standalone token script
```bash
# Generate a 24h listener token using livekit-cli or a small Node script
# The token grants: room "beacon", canSubscribe=true, canPublish=false
```

**Option B:** Hit the webapp API (requires auth session — more complex)

**Token parameters:**
- Room: `beacon`
- Identity: `mobile-poc-{platform}-{random}`
- Permissions: `canSubscribe: true, canPublish: false`
- TTL: 24 hours (for testing convenience)

### Environment Variables (both PoCs)
```
LIVEKIT_URL=wss://live.altermundi.net
LIVEKIT_API_KEY=<from webapp .env>
LIVEKIT_API_SECRET=<from webapp .env>
```

---

## Test Protocol

Each PoC must pass ALL of these tests. Record results in a `RESULTS.md` file.

### Test 1: Dual Source Playback
- [ ] Connect to LiveKit beacon room, receive audio track
- [ ] Load local meditation file (use `la_mosca.m4a` — 52 seconds)
- [ ] Both sources audible simultaneously
- [ ] **Pass criteria:** Two distinct audio sources playing together

### Test 2: Crossfader Volume Control
- [ ] Move slider to 0.0 → only beacon audible
- [ ] Move slider to 0.5 → both audible, beacon slightly lower
- [ ] Move slider to 1.0 → only meditation audible
- [ ] Move slider smoothly left-right → no clicks, pops, or glitches
- [ ] **Pass criteria:** Smooth, glitch-free crossfade between sources

### Test 3: Fader Latency
- [ ] Move fader rapidly back and forth 10 times
- [ ] Observe if volume changes feel instant or laggy
- [ ] **Pass criteria:** Volume changes perceptible within <50ms of fader movement
- [ ] **Bonus:** Record a screen capture with audio for comparison

### Test 4: Background Audio (Screen Lock)
- [ ] Start both sources playing with fader at 0.5
- [ ] Lock the phone screen
- [ ] Wait 30 seconds
- [ ] **Pass criteria:** Both sources continue playing, mix preserved

### Test 5: Background Audio (App Switch)
- [ ] Start both sources playing
- [ ] Switch to another app (browser, settings)
- [ ] Wait 30 seconds, switch back
- [ ] **Pass criteria:** Both sources still playing, can adjust fader

### Test 6: Lock Screen Controls
- [ ] Start meditation + beacon playing
- [ ] Lock screen
- [ ] Use lock screen media controls (play/pause)
- [ ] **Pass criteria:** Play/pause affects meditation, beacon continues
- [ ] **Bonus:** Lock screen shows meditation title/progress

### Test 7: Audio Interruption Recovery
- [ ] Start both sources playing
- [ ] Trigger a phone notification with sound
- [ ] **Pass criteria:** Both sources resume after notification
- [ ] Trigger an incoming phone call (or simulate)
- [ ] **Pass criteria:** Both sources resume after call ends

### Test 8: Network Transition (Stretch Goal)
- [ ] Start both sources playing on WiFi
- [ ] Disable WiFi (force cellular)
- [ ] **Observe:** Does LiveKit reconnect? How long is the gap?
- [ ] **Pass criteria:** Meditation continues uninterrupted, beacon reconnects

### Test 9: Seek During Mix
- [ ] Both sources playing
- [ ] Seek meditation to a different position
- [ ] **Pass criteria:** Beacon unaffected, meditation jumps correctly

### Test 10: Battery Baseline
- [ ] Note battery level
- [ ] Play both sources for 15 minutes with screen off
- [ ] Note battery level
- [ ] **Record:** Battery drain % over 15 minutes

---

## Meditation Test Assets

Both PoCs should include these local files (already in the repo):

| File | Duration | Size | Format |
|---|---|---|---|
| `la_mosca.m4a` | 0:52 | 637KB | AAC |
| `humanosfera.m4a` | 2:03 | 1.5MB | AAC |
| `amor.m4a` | 4:35 | 3.3MB | AAC |

---

## Scoring Rubric

After running all tests, score each PoC:

| Criteria | Weight | Score (0-3) |
|---|---|---|
| Dual playback works | 20% | 0=broken, 1=glitchy, 2=works, 3=flawless |
| Crossfader smoothness | 20% | 0=broken, 1=clicks/pops, 2=minor lag, 3=buttery |
| Background audio | 25% | 0=stops, 1=one source stops, 2=both survive <1min, 3=indefinite |
| Lock screen controls | 10% | 0=none, 1=play/pause, 2=+progress, 3=full metadata |
| Interruption recovery | 10% | 0=broken, 1=one recovers, 2=both recover manually, 3=auto-resume |
| Setup complexity | 15% | 0=>1 week, 1=days of debugging, 2=some issues, 3=straightforward |

**Minimum pass: 2.0 weighted average. Target: 2.5+**

---

## What's OUT of Scope for this PoC

- Authentication (Zitadel/OAuth) — use hardcoded tokens
- Meditation browsing/API — use hardcoded local files
- Session room (group sessions) — beacon room only
- Recording — listener only, no mic
- UI polish — functional is enough
- Offline downloads — local files only
- Push notifications
- App store builds

---

## Timeline

**Day 1-2:** Project setup, LiveKit SDK integration, basic dual playback
**Day 3-4:** Crossfader UI + volume control, background audio config
**Day 5:** Lock screen controls, interruption handling
**Day 6-7:** Test protocol execution, results documentation, comparison

Both PoCs should be runnable by Day 4 for early comparison.
