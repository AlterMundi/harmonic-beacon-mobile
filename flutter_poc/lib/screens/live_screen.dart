import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/beacon_service.dart';
import '../widgets/audio_visualizer.dart';

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BeaconService>(
      builder: (context, beacon, child) {
        // Show error snackbar if there's an error.
        // Copy the message and clear immediately to prevent rebuild loops.
        if (beacon.errorMessage != null) {
          final msg = beacon.errorMessage!;
          beacon.clearError();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          });
        }

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF12122A),
                Color(0xFF0A0A1A),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                // LIVE badge
                Center(
                  child: _LiveBadge(
                    isConnected: beacon.isConnected,
                    isReconnecting: beacon.isReconnecting,
                  ),
                ),
                const SizedBox(height: 32),
                // Status text
                Text(
                  beacon.isConnected
                      ? (beacon.isReconnecting
                          ? 'Reconnecting...'
                          : (beacon.hasTrack
                              ? 'Receiving ${beacon.isLiveSource ? "live" : "playlist"} signal'
                              : 'Connected - waiting for beacon...'))
                      : 'Tap to connect',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: beacon.isConnected ? Colors.white70 : Colors.white38,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                // Audio visualizer
                if (beacon.isConnected && beacon.hasTrack)
                  const SizedBox(
                    height: 120,
                    child: AudioVisualizer(),
                  ),
                if (beacon.isConnected && beacon.hasTrack)
                  const SizedBox(height: 48),
                // Play/Pause button
                Center(
                  child: _PlayButton(
                    isConnected: beacon.isConnected,
                    onPressed: () async {
                      if (beacon.isConnected) {
                        await beacon.disconnect();
                      } else {
                        if (livekitToken.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No LiveKit token configured. '
                                  'Pass --dart-define=LIVEKIT_TOKEN=<token> when building.',
                                ),
                                duration: Duration(seconds: 5),
                              ),
                            );
                          }
                          return;
                        }
                        await beacon.connect(livekitUrl, livekitToken);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Volume slider
                if (beacon.isConnected)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.volume_down,
                                color: Colors.white38, size: 20),
                            Expanded(
                              child: Slider(
                                value: beacon.volume,
                                onChanged: (v) => beacon.setVolume(v),
                              ),
                            ),
                            const Icon(Icons.volume_up,
                                color: Colors.white38, size: 20),
                          ],
                        ),
                        Text(
                          '${(beacon.volume * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiveBadge extends StatefulWidget {
  final bool isConnected;
  final bool isReconnecting;

  const _LiveBadge({
    required this.isConnected,
    required this.isReconnecting,
  });

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.isReconnecting
        ? const Color(0xFFFBBF24)
        : (widget.isConnected ? Colors.red : Colors.white38);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isConnected
                    ? dotColor.withValues(alpha:_pulseAnimation.value)
                    : dotColor,
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        const Text(
          'LIVE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool isConnected;
  final VoidCallback onPressed;

  const _PlayButton({
    required this.isConnected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isConnected
              ? const LinearGradient(
                  colors: [Color(0xFF6346FF), Color(0xFF8B6DFF)],
                )
              : null,
          color: isConnected ? null : Colors.white.withValues(alpha:0.1),
          boxShadow: isConnected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6346FF).withValues(alpha:0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Icon(
          isConnected ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}

