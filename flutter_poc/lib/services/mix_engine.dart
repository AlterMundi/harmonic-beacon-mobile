import 'package:flutter/foundation.dart';
import 'dart:async';
import 'beacon_service.dart';
import 'meditation_player.dart';

class MixEngine extends ChangeNotifier {
  final BeaconService beacon;
  final MeditationPlayer meditation;
  double _mixValue = 0.5;

  Timer? _volumeThrottleTimer;

  MixEngine({required this.beacon, required this.meditation});

  double get mixValue => _mixValue;

  void setMix(double value) {
    _mixValue = value.clamp(0.0, 1.0);
    // Notify listeners immediately for smooth UI updates
    notifyListeners();

    // Throttle actual volume updates to prevent overwhelming the native bridge
    if (_volumeThrottleTimer?.isActive ?? false) return;
    _volumeThrottleTimer = Timer(const Duration(milliseconds: 32), _updateVolumes);
  }

  void _updateVolumes() {
    double beaconVol;
    double medVol;

    if (_mixValue <= 0.5) {
      beaconVol = 1.0 - (_mixValue * 0.3);
      medVol = _mixValue * 2;
    } else {
      beaconVol = (1.0 - _mixValue) * 1.7;
      medVol = 1.0;
    }

    beacon.setVolume(beaconVol);
    meditation.setVolume(medVol);
  }

  @override
  void dispose() {
    _volumeThrottleTimer?.cancel();
    super.dispose();
  }
}
