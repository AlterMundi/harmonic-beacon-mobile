import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/beacon_service.dart';
import 'services/meditation_player.dart';
import 'services/mix_engine.dart';

// Bypass SSL certificate errors — debug builds only
class _DebugHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

const livekitUrl = String.fromEnvironment(
  'LIVEKIT_URL',
  defaultValue: 'wss://live.altermundi.net',
);
// Pass --dart-define=LIVEKIT_TOKEN=<token> when building.
// Generate with: node scripts/generate-livekit-token.js
const livekitToken = String.fromEnvironment('LIVEKIT_TOKEN');

Future<void> configureAudioSession() async {
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
  if (kDebugMode) {
    HttpOverrides.global = _DebugHttpOverrides();
  }
  await configureAudioSession();
  runApp(const HarmonicBeaconApp());
}

class HarmonicBeaconApp extends StatelessWidget {
  const HarmonicBeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BeaconService()),
        ChangeNotifierProvider(create: (_) => MeditationPlayer()),
        ChangeNotifierProvider<MixEngine>(
          create: (context) => MixEngine(
            beacon: Provider.of<BeaconService>(context, listen: false),
            meditation: Provider.of<MeditationPlayer>(context, listen: false),
          ),
        ),
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
          cardTheme: CardThemeData(
            color: Colors.white.withValues(alpha: 0.05),
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
