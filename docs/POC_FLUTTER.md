# PoC: Flutter — LiveKit Dual-Audio Mix

Branch: `poc/flutter`
Project directory: `flutter_poc/` (alongside existing Expo code for reference)

## Why Flutter for the Mix

The Flutter PoC exists specifically to test whether its audio stack is better suited for the dual-source crossfader:

1. **`livekit_client` has `track.setVolume(double)`** — first-class per-track volume
2. **`just_audio` supports concurrent instances** — designed for multi-player scenarios
3. **`audio_session` gives explicit AVAudioSession control** — no hoping libraries cooperate
4. **`audio_service` handles background + lock screen** — battle-tested for music/podcast apps
5. **No JS bridge** — Dart compiles to native ARM, volume changes are in-frame

---

## Architecture

```
flutter_poc/
├── lib/
│   ├── main.dart                 # App entry, providers
│   ├── services/
│   │   ├── beacon_service.dart   # LiveKit room connection + track volume
│   │   ├── meditation_player.dart # just_audio player + background control
│   │   └── mix_engine.dart       # Crossfader math, coordinates both services
│   ├── screens/
│   │   ├── home_screen.dart      # Tab container
│   │   ├── live_screen.dart      # Beacon status + play/pause
│   │   └── meditate_screen.dart  # Meditation list + player + fader
│   └── widgets/
│       ├── crossfader.dart       # The slider widget
│       ├── audio_visualizer.dart # Animated bars
│       └── meditation_card.dart  # List item
├── assets/
│   └── audio/
│       ├── la_mosca.m4a
│       ├── humanosfera.m4a
│       └── amor.m4a
├── pubspec.yaml
└── RESULTS.md
```

---

## Implementation Plan

### Step 1: Create Flutter Project

```bash
cd /home/fede/REPOS/harmonic-beacon-mobile
flutter create flutter_poc --org com.altermundi --platforms android,ios
cd flutter_poc
```

### Step 2: Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # LiveKit
  livekit_client: ^2.3.0

  # Audio playback (meditation files)
  just_audio: ^0.9.40

  # Background audio + lock screen controls
  audio_service: ^0.18.15

  # iOS/Android audio session management
  audio_session: ^0.1.21

  # State management (lightweight for PoC)
  provider: ^6.1.2

  # UI
  google_fonts: ^6.2.1
```

### Step 3: BeaconService — LiveKit Connection

```dart
// lib/services/beacon_service.dart

import 'package:livekit_client/livekit_client.dart';

class BeaconService extends ChangeNotifier {
  Room? _room;
  RemoteAudioTrack? _beaconTrack;
  bool _isConnected = false;
  double _volume = 1.0;

  bool get isConnected => _isConnected;
  double get volume => _volume;
  bool get hasTrack => _beaconTrack != null;

  static const _livekitUrl = 'wss://live.altermundi.net';
  static const _beaconIdentity = 'beacon01';

  Future<void> connect(String token) async {
    _room = Room();

    // livekit_client v2.x: use event-specific callbacks
    _room!.on<TrackSubscribedEvent>((event) {
      final track = event.track;
      final participant = event.participant;
      if (track is RemoteAudioTrack && participant.identity == _beaconIdentity) {
        _beaconTrack = track;
        track.setVolume(_volume); // <-- THE KEY API
        notifyListeners();
      }
    });

    _room!.on<TrackUnsubscribedEvent>((event) {
      if (event.participant.identity == _beaconIdentity) {
        _beaconTrack = null;
        notifyListeners();
      }
    });

    _room!.on<RoomDisconnectedEvent>((_) {
      _isConnected = false;
      _beaconTrack = null;
      notifyListeners();
    });

    _room!.on<RoomReconnectingEvent>((_) {
      // UI can show reconnection indicator
      notifyListeners();
    });

    _room!.on<RoomReconnectedEvent>((_) {
      _isConnected = true;
      notifyListeners();
    });

    await _room!.connect(_livekitUrl, token);
    _isConnected = true;
    notifyListeners();

    // Check for existing participants (already in room before we joined)
    for (final participant in _room!.remoteParticipants.values) {
      if (participant.identity == _beaconIdentity) {
        for (final trackPublication in participant.audioTrackPublications) {
          final track = trackPublication.track;
          if (track is RemoteAudioTrack) {
            _beaconTrack = track;
            track.setVolume(_volume);
            notifyListeners();
          }
        }
      }
    }
  }

  /// Set beacon volume (0.0 - 1.0)
  /// This is the critical API — maps directly to WebRTC track volume
  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    _beaconTrack?.setVolume(_volume);
    // No async, no bridge — Dart → native in same frame
  }

  Future<void> disconnect() async {
    await _room?.disconnect();
    _room?.dispose();
    _room = null;
    _beaconTrack = null;
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
```

### Step 4: MeditationPlayer — just_audio + audio_service

```dart
// lib/services/meditation_player.dart

import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

class MeditationPlayer extends ChangeNotifier {
  late AudioPlayer _player;
  String? _currentAsset;
  double _volume = 1.0;

  MeditationPlayer() {
    _player = AudioPlayer();
    _player.positionStream.listen((_) => notifyListeners());
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.durationStream.listen((_) => notifyListeners());
  }

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  double get volume => _volume;
  String? get currentAsset => _currentAsset;

  Future<void> load(String assetPath) async {
    _currentAsset = assetPath;
    await _player.setAsset(assetPath);
    await _player.setVolume(_volume);
    await _player.play();
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Set meditation volume (0.0 - 1.0)
  /// just_audio: synchronous volume update, no bridge latency
  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    _player.setVolume(_volume);
  }

  Future<void> stop() async {
    await _player.stop();
    _currentAsset = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
```

### Step 5: MixEngine — The Crossfader Brain

```dart
// lib/services/mix_engine.dart

class MixEngine extends ChangeNotifier {
  final BeaconService beacon;
  final MeditationPlayer meditation;
  double _mixValue = 0.5;

  MixEngine({required this.beacon, required this.meditation});

  double get mixValue => _mixValue;

  /// Apply the asymmetric crossfade curve
  /// Matches web app AudioContext.tsx setMixValue()
  void setMix(double value) {
    _mixValue = value.clamp(0.0, 1.0);

    double beaconVol;
    double medVol;

    if (_mixValue <= 0.5) {
      // Left half: beacon stays loud, meditation fades in
      beaconVol = 1.0 - (_mixValue * 0.3);  // 1.0 → 0.85
      medVol = _mixValue * 2;                // 0.0 → 1.0
    } else {
      // Right half: meditation full, beacon fades out
      beaconVol = (1.0 - _mixValue) * 1.7;  // 0.85 → 0.0
      medVol = 1.0;
    }

    beacon.setVolume(beaconVol);
    meditation.setVolume(medVol);
    notifyListeners();
  }
}
```

### Step 6: Audio Session Configuration

```dart
// lib/main.dart — before any audio playback

import 'package:audio_session/audio_session.dart';

Future<void> configureAudioSession() async {
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.playback,
    avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
    avAudioSessionMode: AVAudioSessionMode.defaultMode,
    androidAudioAttributes: AndroidAudioAttributes(
      contentType: AndroidAudioContentType.music,
      usage: AndroidAudioUsage.media,
    ),
    androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
  ));

  // Listen for interruptions (phone calls, etc.)
  session.interruptionEventStream.listen((event) {
    if (event.begin) {
      // Audio interrupted — pause meditation, beacon stays via LiveKit
    } else {
      // Interruption ended — resume if was playing
    }
  });
}
```

**Audio Session Conflict Mitigation (CRITICAL):**

LiveKit's Flutter SDK may reconfigure the `AVAudioSession` to `.playAndRecord` when connecting, overriding our `.playback` + `mixWithOthers` config. Additionally, `.playAndRecord` defaults to earpiece output on iOS.

**Required steps:**
1. **Log the actual session state** after LiveKit connects:
```dart
final session = await AudioSession.instance;
_room!.on<RoomConnectedEvent>((_) async {
  final category = await session.configuration;
  debugPrint('[AudioSession] Post-connect config: $category');
});
```

2. **Re-apply audio config** after LiveKit connects:
```dart
_room!.on<RoomConnectedEvent>((_) async {
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.playback,
    avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
    avAudioSessionMode: AVAudioSessionMode.defaultMode,
    androidAudioAttributes: AndroidAudioAttributes(
      contentType: AndroidAudioContentType.music,
      usage: AndroidAudioUsage.media,
    ),
    androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
  ));
  debugPrint('[AudioSession] Re-applied mixWithOthers after LiveKit connected');
});
```

3. **Test earpiece vs speaker**: If audio is barely audible after LiveKit connects, `.playAndRecord` may have defaulted to earpiece. Verify audio routes to speaker.

### Step 7: Background Audio with audio_service

```dart
// Wrap MeditationPlayer in AudioService handler for lock screen controls

class MeditationAudioHandler extends BaseAudioHandler with SeekHandler {
  final MeditationPlayer _player;

  MeditationAudioHandler(this._player) {
    // Forward player state to MediaSession
    _player.addListener(() {
      playbackState.add(PlaybackState(
        controls: [
          _player.isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
        ],
        playing: _player.isPlaying,
        processingState: AudioProcessingState.ready,
        updatePosition: _player.position,
      ));

      mediaItem.add(MediaItem(
        id: _player.currentAsset ?? '',
        title: 'Meditation', // Update with actual title
        artist: 'Harmonic Beacon',
        duration: _player.duration,
      ));
    });
  }

  @override
  Future<void> play() => _player.togglePlay();

  @override
  Future<void> pause() => _player.togglePlay();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();
}
```

### Step 8: Platform Configuration

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

**Android (`android/app/src/main/AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
```

### Step 9: Crossfader Widget

```dart
// lib/widgets/crossfader.dart

class Crossfader extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const Crossfader({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Audio Mix', style: TextStyle(color: Colors.white54, fontSize: 12)),
        SizedBox(height: 8),
        Row(
          children: [
            Text('Beacon', style: TextStyle(color: Colors.white60, fontSize: 12)),
            Expanded(
              child: Slider(
                value: value,
                onChanged: onChanged,
                activeColor: Color(0xFF6346ff),
                inactiveColor: Color(0xFFfbbf24),
              ),
            ),
            Text('Voice', style: TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
```

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| LiveKit `setVolume()` not working as expected | LOW | BLOCKING | Test immediately on Day 1; it's documented in SDK |
| audio_session + LiveKit session conflict | MEDIUM | HIGH | Configure audio_session BEFORE LiveKit connects |
| just_audio background audio stopping | LOW | HIGH | audio_service wraps it properly; well-documented |
| Flutter toolchain issues on Linux (no iOS) | CERTAIN | MEDIUM | Test Android only on Linux; iOS needs macOS |
| Dart learning curve slowing development | MEDIUM | MEDIUM | PoC is small scope; Dart is similar to TS |
| Hot reload not working with LiveKit | LOW | LOW | Use hot restart instead |

---

## iOS Limitation

**Important:** Flutter iOS builds require macOS + Xcode. If developing on Linux:
- Test Android PoC fully on Linux
- iOS testing requires a macOS machine or CI (EAS Build, Codemagic)
- The critical audio session tests are iOS-specific

**Recommendation:** Build and validate the Android PoC first. If the mix works well on Android (which is more permissive), then test iOS separately.

---

## File Structure (final)

```
flutter_poc/
├── lib/
│   ├── main.dart
│   ├── services/
│   │   ├── beacon_service.dart
│   │   ├── meditation_player.dart
│   │   └── mix_engine.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── live_screen.dart
│   │   └── meditate_screen.dart
│   └── widgets/
│       ├── crossfader.dart
│       ├── audio_visualizer.dart
│       └── meditation_card.dart
├── assets/audio/
│   ├── la_mosca.m4a
│   ├── humanosfera.m4a
│   └── amor.m4a
├── pubspec.yaml
├── ios/Runner/Info.plist          (background audio mode)
├── android/app/src/main/AndroidManifest.xml (foreground service)
└── RESULTS.md
```

---

## Definition of Done

- [ ] App connects to LiveKit `beacon` room via `livekit_client`
- [ ] `track.setVolume()` controls beacon audio level
- [ ] `just_audio` plays local meditation file simultaneously
- [ ] `MixEngine.setMix()` crossfades both sources smoothly
- [ ] Background audio works with both sources (Android tested)
- [ ] Lock screen shows meditation controls via `audio_service`
- [ ] All 10 tests from POC_SPEC.md executed and documented
