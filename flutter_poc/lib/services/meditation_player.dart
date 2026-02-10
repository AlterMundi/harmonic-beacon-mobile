import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class MeditationPlayer extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  String? _currentAsset;
  String? _currentTitle;
  double _volume = 1.0;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  double get volume => _volume;
  String? get currentAsset => _currentAsset;
  String? get currentTitle => _currentTitle;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  Future<void> load(String assetPath, {String? title}) async {
    _currentAsset = assetPath;
    _currentTitle = title;
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
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    _player.setVolume(_volume);
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentAsset = null;
    _currentTitle = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
