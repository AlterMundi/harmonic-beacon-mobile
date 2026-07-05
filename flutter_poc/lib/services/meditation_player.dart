import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

enum MeditationSource { asset, url }

class MeditationPlayer extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  String? _currentAsset;
  String? _currentTitle;
  String? _currentMeditationId;
  MeditationSource? _currentSource;
  double _volume = 1.0;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  double get volume => _volume;
  String? get currentAsset => _currentAsset;
  String? get currentTitle => _currentTitle;
  String? get currentMeditationId => _currentMeditationId;
  MeditationSource? get currentSource => _currentSource;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Load and play a bundled asset.
  Future<void> load(String assetPath, {String? title}) async {
    _currentAsset = assetPath;
    _currentTitle = title;
    _currentMeditationId = null;
    _currentSource = MeditationSource.asset;
    notifyListeners();

    try {
      await _player.setAsset(assetPath);
      await _player.setVolume(_volume);
      await _player.play();
      notifyListeners();
    } catch (e) {
      _currentAsset = null;
      _currentTitle = null;
      _currentSource = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Load and play from a remote URL (streaming meditation from API).
  Future<void> loadUrl(String url,
      {Map<String, String>? headers, String? title, String? meditationId}) async {
    _currentAsset = url;
    _currentTitle = title;
    _currentMeditationId = meditationId;
    _currentSource = MeditationSource.url;
    notifyListeners();

    try {
      await _player.setUrl(url, headers: headers);
      await _player.setVolume(_volume);
      await _player.play();
      notifyListeners();
    } catch (e) {
      _currentAsset = null;
      _currentTitle = null;
      _currentMeditationId = null;
      _currentSource = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    _player.setVolume(_volume);
    // Don't call notifyListeners here — called per-frame during crossfader drag.
    // MixEngine already notifies its own listeners.
  }

  Future<void> stop() async {
    await _player.stop();
    _currentAsset = null;
    _currentTitle = null;
    _currentMeditationId = null;
    _currentSource = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
