import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/beacon_service.dart';
import '../services/meditation_player.dart';
import '../services/mix_engine.dart';
import '../widgets/crossfader.dart';
import '../widgets/meditation_card.dart';

class _MeditationInfo {
  final String title;
  final String subtitle;
  final String assetPath;
  final String duration;
  final List<Color> gradientColors;

  const _MeditationInfo({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.duration,
    required this.gradientColors,
  });
}

const _meditations = [
  _MeditationInfo(
    title: 'La Mosca',
    subtitle: 'Guided meditation',
    assetPath: 'assets/audio/la_mosca.m4a',
    duration: '0:52',
    gradientColors: [Color(0xFF6346FF), Color(0xFF3A1FCC)],
  ),
  _MeditationInfo(
    title: 'Humanosfera',
    subtitle: 'Sound journey',
    assetPath: 'assets/audio/humanosfera.m4a',
    duration: '2:03',
    gradientColors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
  ),
  _MeditationInfo(
    title: 'El Amor',
    subtitle: 'Heart meditation',
    assetPath: 'assets/audio/amor.m4a',
    duration: '4:35',
    gradientColors: [Color(0xFFE91E63), Color(0xFF880E4F)],
  ),
];

class MeditateScreen extends StatelessWidget {
  const MeditateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Meditate',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Text(
              'Choose a meditation to begin',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _meditations.length,
              itemBuilder: (context, index) {
                final med = _meditations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: MeditationCard(
                    title: med.title,
                    subtitle: med.subtitle,
                    duration: med.duration,
                    gradientColors: med.gradientColors,
                    onTap: () => _startMeditation(context, med),
                  ),
                );
              },
            ),
          ),
          // Bottom sheet player
          Consumer<MeditationPlayer>(
            builder: (context, player, child) {
              if (player.currentAsset == null) {
                return _EmptyPlayerHint();
              }
              return _PlayerBottomSheet(player: player);
            },
          ),
        ],
      ),
    );
  }

  void _startMeditation(BuildContext context, _MeditationInfo med) async {
    final player = context.read<MeditationPlayer>();
    final beacon = context.read<BeaconService>();

    // Auto-connect beacon when starting a meditation
    if (!beacon.isConnected && livekitToken.isNotEmpty) {
      beacon.connect(livekitUrl, livekitToken);
    }

    await player.load(med.assetPath, title: med.title);
  }
}

class _EmptyPlayerHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.headphones_rounded, color: Colors.white24, size: 20),
          SizedBox(width: 8),
          Text(
            'Tap a meditation above to start listening',
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PlayerBottomSheet extends StatelessWidget {
  final MeditationPlayer player;

  const _PlayerBottomSheet({required this.player});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final beacon = context.watch<BeaconService>();
    final mixEngine = context.watch<MixEngine>();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title and play button row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.currentTitle ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Beacon connection indicator
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: beacon.isConnected
                                ? (beacon.isReconnecting
                                    ? const Color(0xFFFBBF24)
                                    : Colors.green)
                                : Colors.white24,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          beacon.isConnected
                              ? (beacon.hasTrack
                                  ? 'Beacon connected'
                                  : 'Waiting for beacon...')
                              : 'Beacon offline',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Play/pause button
              GestureDetector(
                onTap: () => player.togglePlay(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF6346FF),
                  ),
                  child: StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data?.playing ?? false;
                      return Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Stop/close button
              GestureDetector(
                onTap: () => player.stop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Seek slider with time display
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, posSnapshot) {
              final position = posSnapshot.data ?? Duration.zero;
              return StreamBuilder<Duration?>(
                stream: player.durationStream,
                builder: (context, durSnapshot) {
                  final duration = durSnapshot.data ?? Duration.zero;
                  final maxVal =
                      duration.inMilliseconds.toDouble().clamp(1.0, double.infinity);
                  final curVal =
                      position.inMilliseconds.toDouble().clamp(0.0, maxVal);

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          value: curVal,
                          max: maxVal,
                          onChanged: (v) {
                            player.seek(
                                Duration(milliseconds: v.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          // Crossfader
          Crossfader(
            value: mixEngine.mixValue,
            onChanged: (v) => mixEngine.setMix(v),
          ),
        ],
      ),
    );
  }
}
