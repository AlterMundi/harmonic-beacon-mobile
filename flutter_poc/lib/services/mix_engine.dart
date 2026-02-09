import 'package:flutter/foundation.dart';
import 'beacon_service.dart';
import 'meditation_player.dart';

class MixEngine extends ChangeNotifier {
  final BeaconService beacon;
  final MeditationPlayer meditation;
  double _mixValue = 0.5;

  MixEngine({required this.beacon, required this.meditation});

  double get mixValue => _mixValue;

  void setMix(double value) {
    _mixValue = value.clamp(0.0, 1.0);

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
    notifyListeners();
  }
}
