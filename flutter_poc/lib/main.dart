import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/beacon_service.dart';
import 'services/meditation_player.dart';
import 'services/mix_engine.dart';

const livekitUrl = String.fromEnvironment(
  'LIVEKIT_URL',
  defaultValue: 'wss://live.altermundi.net',
);
const livekitToken = String.fromEnvironment(
  'LIVEKIT_TOKEN',
  defaultValue: '',
);

Future<void> _configureAudioSession() async {
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.playback,
    avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
    avAudioSessionMode: AVAudioSessionMode.defaultMode,
    avAudioSessionRouteSharingPolicy:
        AVAudioSessionRouteSharingPolicy.defaultPolicy,
    avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
    androidAudioAttributes: AndroidAudioAttributes(
      contentType: AndroidAudioContentType.music,
      usage: AndroidAudioUsage.media,
    ),
    androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    androidWillPauseWhenDucked: false,
  ));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAudioSession();
  runApp(const HarmonicBeaconApp());
}

class HarmonicBeaconApp extends StatelessWidget {
  const HarmonicBeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    final beaconService = BeaconService();
    final meditationPlayer = MeditationPlayer();
    final mixEngine = MixEngine(
      beacon: beaconService,
      meditation: meditationPlayer,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: beaconService),
        ChangeNotifierProvider.value(value: meditationPlayer),
        ChangeNotifierProvider.value(value: mixEngine),
      ],
      child: MaterialApp(
        title: 'Harmonic Beacon',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0A1A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6346FF),
            secondary: Color(0xFFFBBF24),
            surface: Color(0xFF12122A),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0A0A1A),
            elevation: 0,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF0A0A1A),
            selectedItemColor: Color(0xFF6346FF),
            unselectedItemColor: Colors.white38,
          ),
          sliderTheme: const SliderThemeData(
            activeTrackColor: Color(0xFF6346FF),
            inactiveTrackColor: Colors.white12,
            thumbColor: Color(0xFF6346FF),
            overlayColor: Color(0x336346FF),
          ),
          cardTheme: CardTheme(
            color: Colors.white.withOpacity(0.05),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            headlineMedium: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            bodyLarge: TextStyle(color: Colors.white70),
            bodyMedium: TextStyle(color: Colors.white70),
            bodySmall: TextStyle(color: Colors.white38),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
