# Mobile vs Webapp: Feature Gap Analysis

**Date**: 2026-02-09
**Source of Truth**: `/home/fede/REPOS/harmonic-beacon-webapp` (Next.js 16)
**Target**: `/home/fede/REPOS/harmonic-beacon-mobile` (Expo SDK 54)

## Current State: Mobile is ~12% of Webapp

The mobile app is a UI shell with placeholder functionality. It has 14 files vs. the webapp's 113. Auth is broken (Supabase references deleted), all data is hardcoded, and zero API calls are made.

## Gap Summary

| Category | Webapp | Mobile | Gap |
|---|---|---|---|
| Auth | Zitadel OIDC + JWT + 3 roles | Broken Supabase | MISSING |
| API Integration | 33 REST endpoints | 0 calls | MISSING |
| Live Beacon | LiveKit WebRTC (beacon01) | Hardcoded Lofi HTTP stream | MISSING |
| Meditations | Dynamic catalog, tags, favorites, streaming | 3 hardcoded local files | 95% gap |
| Sessions | Tracking + scheduled + recordings + cuts | Empty placeholder | MISSING |
| Provider Studio | Upload, manage, session studio, cuts | None | MISSING |
| Admin Panel | Moderation, users, tags, stats | None | MISSING |
| Design System | CSS vars + glass-card classes | Colors.ts matches | OK |
| Navigation | 4 tabs + provider + admin routes | 4 tabs (empty) | Structure OK |
| Testing | 290 tests / 41 files | 0 tests | MISSING |
| Infrastructure | Docker + CI/CD + EAS | Dev-only Expo Go | MISSING |

## Phase Roadmap (Post-PoC)

### Phase 1: Foundation (2-3 weeks) — BLOCKING
1. Replace Supabase with Zitadel OIDC (`expo-web-browser` + `expo-secure-store`)
2. Create API client (`lib/api.ts`) with JWT injection
3. Replace HTTP stream with LiveKit (`@livekit/react-native`)
4. Fetch LiveKit token from `/api/livekit/token`

### Phase 2: Core Listener (3-4 weeks)
4. Meditation catalog from `/api/meditations` with tag filtering
5. Favorites toggle
6. Session tracking (start/end/history)
7. User profile with stats

### Phase 3: Provider (3-4 weeks)
8. Meditation upload with file picker
9. Provider dashboard + edit meditation
10. Scheduled session creation
11. Session studio (mic, recording, invites)

### Phase 4: Advanced (2-3 weeks)
12. Scheduled session browsing/joining
13. Recording playback (composite player)
14. Admin panel (stats, moderation, users, tags)

### Phase 5: Launch (2-3 weeks)
15. EAS Build + CI/CD
16. Offline support (download meditations, cache)
17. Testing suite
18. Sentry crash reporting

**Total: 12-17 weeks** for full feature parity.

## Environment Variables Needed

```bash
EXPO_PUBLIC_API_URL=https://beacon.altermundi.net
EXPO_PUBLIC_LIVEKIT_URL=wss://live.altermundi.net
EXPO_PUBLIC_ZITADEL_ISSUER=https://auth.altermundi.net
EXPO_PUBLIC_ZITADEL_CLIENT_ID=<from Zitadel admin>
```

## What the PoC Tests (Before Committing to Full Build)

The PoC answers one question: **Does the dual-audio crossfader mix work with LiveKit WebRTC on mobile?**

If YES → proceed with the full roadmap above.
If NO → evaluate alternative audio architectures before investing months of work.

See `POC_SPEC.md` for test protocol.
