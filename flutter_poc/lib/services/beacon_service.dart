import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import '../main.dart' show configureAudioSession;

class BeaconService extends ChangeNotifier {
  Room? _room;
  RemoteAudioTrack? _beaconTrack;
  bool _isConnected = false;
  bool _isReconnecting = false;
  double _volume = 1.0;
  String? _errorMessage;

  bool get isConnected => _isConnected;
  bool get isReconnecting => _isReconnecting;
  double get volume => _volume;
  bool get hasTrack => _beaconTrack != null;
  String? get errorMessage => _errorMessage;

  static const _beaconIdentity = 'beacon01';

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

  Future<void> connect(String url, String token) async {
    _errorMessage = null;
    notifyListeners();

    try {
      _room = Room();

      _room!.on<TrackSubscribedEvent>((event) {
        final track = event.track;
        final participant = event.participant;
        if (track is RemoteAudioTrack &&
            participant.identity == _beaconIdentity) {
          _beaconTrack = track;
          track.setVolume(_volume);
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
        _isReconnecting = false;
        _beaconTrack = null;
        notifyListeners();
      });

      _room!.on<RoomReconnectingEvent>((_) {
        _isReconnecting = true;
        notifyListeners();
      });

      _room!.on<RoomReconnectedEvent>((_) async {
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

      // Check for existing participants
      for (final participant in _room!.remoteParticipants.values) {
        if (participant.identity == _beaconIdentity) {
          for (final pub in participant.audioTrackPublications) {
            final track = pub.track;
            if (track is RemoteAudioTrack) {
              _beaconTrack = track;
              track.setVolume(_volume);
              notifyListeners();
            }
          }
        }
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
    _beaconTrack?.setVolume(_volume);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _room?.disconnect();
    _room?.dispose();
    _room = null;
    _beaconTrack = null;
    _isConnected = false;
    _isReconnecting = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
