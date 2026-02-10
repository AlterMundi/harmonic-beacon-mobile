import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../main.dart' show configureAudioSession;

class BeaconService extends ChangeNotifier {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  RemoteAudioTrack? _beaconTrack;
  bool _isConnected = false;
  bool _isReconnecting = false;
  bool _isLiveSource = false;
  double _volume = 1.0;
  String? _errorMessage;
  String? _sourceIdentity;
  Timer? _volumeTimer;

  bool get isConnected => _isConnected;
  bool get isReconnecting => _isReconnecting;
  double get volume => _volume;
  bool get hasTrack => _beaconTrack != null;
  String? get errorMessage => _errorMessage;

  /// True if audio is from the real beacon hardware (beacon01),
  /// false if it's from the playlist-bot fallback.
  bool get isLiveSource => _isLiveSource;

  /// Identity of the participant currently providing audio.
  String? get sourceIdentity => _sourceIdentity;

  // The real beacon hardware identity
  static const _liveIdentity = 'beacon01';

  /// Re-apply audio session config after LiveKit connects.
  /// LiveKit's WebRTC layer may override the session to .playAndRecord,
  /// so we re-apply to keep .playback + mixWithOthers.
  Future<void> _reapplyAudioSession() async {
    try {
      await configureAudioSession();
      debugPrint('BeaconService: audio session re-applied');
    } catch (e) {
      debugPrint('BeaconService: failed to re-apply audio session: $e');
    }
  }

  /// Apply volume to the current beacon track using flutter_webrtc's Helper.
  Future<void> _applyVolume() async {
    if (_beaconTrack == null) return;

    final track = _beaconTrack!;
    try {
      await rtc.Helper.setVolume(_volume, track.mediaStreamTrack);
    } catch (e) {
      debugPrint('BeaconService: setVolume failed: $e');
    }
  }

  Future<void> connect(String url, String token) async {
    _errorMessage = null;
    notifyListeners();

    try {
      // Configure Hardware to prevent overriding audio session if possible
      Hardware.instance.setAutomaticConfigurationEnabled(enable: false);

      _room = Room(
        roomOptions: const RoomOptions(
          defaultAudioOutputOptions: AudioOutputOptions(speakerOn: true),
        ),
      );
      _listener = _room!.createListener();

      // Accept audio from ANY participant — both beacon01 (live hardware)
      // and playlist-bot (recorded fallback) publish to the same room.
      _listener!.on<TrackSubscribedEvent>((event) {
        final track = event.track;
        final participant = event.participant;
        if (track is RemoteAudioTrack) {
          final identity = participant.identity;
          _isLiveSource = identity == _liveIdentity;
          _sourceIdentity = identity;
          _beaconTrack = track;
          _applyVolume();
          debugPrint(
              'BeaconService: subscribed to ${_isLiveSource ? "LIVE" : "playlist"} '
              'audio track ($identity)');
          notifyListeners();
        }
      });

      _listener!.on<TrackUnsubscribedEvent>((event) {
        if (event.track is RemoteAudioTrack &&
            event.participant.identity == _sourceIdentity) {
          debugPrint(
              'BeaconService: unsubscribed from audio track (${event.participant.identity})');
          _beaconTrack = null;
          _sourceIdentity = null;
          _isLiveSource = false;
          notifyListeners();
        }
      });

      _listener!.on<RoomDisconnectedEvent>((_) {
        _isConnected = false;
        _isReconnecting = false;
        _beaconTrack = null;
        _sourceIdentity = null;
        _isLiveSource = false;
        notifyListeners();
      });

      _listener!.on<RoomReconnectingEvent>((_) {
        _isReconnecting = true;
        notifyListeners();
      });

      _listener!.on<RoomReconnectedEvent>((_) async {
        _isReconnecting = false;
        _isConnected = true;
        notifyListeners();
        await _reapplyAudioSession();
      });

      await _room!.connect(url, token);
      _isConnected = true;
      notifyListeners();

      // Re-apply audio session after initial connect
      await _reapplyAudioSession();

      // Check for existing participants (already in room before we joined)
      for (final participant in _room!.remoteParticipants.values) {
        for (final pub in participant.audioTrackPublications) {
          final track = pub.track;
          if (track is RemoteAudioTrack) {
            final identity = participant.identity;
            _isLiveSource = identity == _liveIdentity;
            _sourceIdentity = identity;
            _beaconTrack = track;
            _applyVolume();
            debugPrint(
                'BeaconService: found existing ${_isLiveSource ? "LIVE" : "playlist"} '
                'audio track ($identity)');
            notifyListeners();
            break; // Take the first audio track we find
          }
        }
        if (_beaconTrack != null) break;
      }
    } catch (e) {
      _errorMessage = 'Connection failed: $e';
      _isConnected = false;
      _isReconnecting = false;
      notifyListeners();
    }
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    // No notifyListeners here — MixEngine already notifies its own listeners.
    // No throttle here — MixEngine already throttles at 32ms.
    _applyVolume();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _room?.disconnect();
    _listener?.dispose();
    _listener = null;
    _room?.dispose();
    _room = null;
    _beaconTrack = null;
    _isConnected = false;
    _isReconnecting = false;
    _isLiveSource = false;
    _sourceIdentity = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _volumeTimer?.cancel();
    // disconnect() is async but dispose() is synchronous (ChangeNotifier).
    // Fire-and-forget is acceptable — WebSocket close may not complete cleanly.
    disconnect();
    super.dispose();
  }
}
