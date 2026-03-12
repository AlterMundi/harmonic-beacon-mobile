import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/beacon_service.dart';
import 'services/meditation_player.dart';
import 'services/mix_engine.dart';
import 'theme.dart';

// --- Configuration ---
const livekitUrl = String.fromEnvironment(
  'LIVEKIT_URL',
  defaultValue: 'wss://live.altermundi.net',
);

const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://beacon.altermundi.net',
);

/// Configure audio session for background playback with mixing.
/// Called at startup and re-applied after LiveKit connects (since
/// WebRTC may override the session to .playAndRecord).
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
  await configureAudioSession();

  // Initialize auth before building the widget tree
  final authService = AuthService();
  await authService.initialize();

  runApp(HarmonicBeaconApp(authService: authService));
}

class HarmonicBeaconApp extends StatelessWidget {
  final AuthService authService;

  const HarmonicBeaconApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
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
        theme: buildAppTheme(),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Shows [LoginScreen] or [HomeScreen] based on authentication state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary500,
              ),
            ),
          );
        }

        if (auth.isAuthenticated) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
