import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/meditation.dart';
import '../services/api_client.dart';
import '../services/beacon_service.dart';
import '../services/catalog_service.dart';
import '../services/meditation_player.dart';
import '../services/mix_engine.dart';
import '../services/session_service.dart';
import '../models/session.dart';
import '../widgets/crossfader.dart';
import '../widgets/meditation_card.dart';
import '../widgets/tag_filter_bar.dart';

// Hardcoded fallback meditations (used when API is unavailable)
class _FallbackMeditation {
  final String title;
  final String subtitle;
  final String assetPath;
  final String duration;
  final List<Color> gradientColors;

  const _FallbackMeditation({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.duration,
    required this.gradientColors,
  });
}

const _fallbackMeditations = [
  _FallbackMeditation(
    title: 'La Mosca',
    subtitle: 'Guided meditation',
    assetPath: 'assets/audio/la_mosca.m4a',
    duration: '0:52',
    gradientColors: [Color(0xFF6346FF), Color(0xFF3A1FCC)],
  ),
  _FallbackMeditation(
    title: 'Humanosfera',
    subtitle: 'Sound journey',
    assetPath: 'assets/audio/humanosfera.m4a',
    duration: '2:03',
    gradientColors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
  ),
  _FallbackMeditation(
    title: 'El Amor',
    subtitle: 'Heart meditation',
    assetPath: 'assets/audio/amor.m4a',
    duration: '4:35',
    gradientColors: [Color(0xFFE91E63), Color(0xFF880E4F)],
  ),
];

// Gradient colors for API meditations (cycles through these)
const _apiGradients = [
  [Color(0xFF6346FF), Color(0xFF3A1FCC)],
  [Color(0xFF1E88E5), Color(0xFF0D47A1)],
  [Color(0xFFE91E63), Color(0xFF880E4F)],
  [Color(0xFF00897B), Color(0xFF004D40)],
  [Color(0xFFFF6F00), Color(0xFFE65100)],
];

class MeditateScreen extends StatefulWidget {
  const MeditateScreen({super.key});

  @override
  State<MeditateScreen> createState() => _MeditateScreenState();
}

class _MeditateScreenState extends State<MeditateScreen> {
  bool _useFallback = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final catalog = context.read<CatalogService>();
    await Future.wait([
      catalog.fetchMeditations(),
      catalog.fetchTags(),
      catalog.fetchFavorites(),
    ]);
    if (mounted && catalog.errorMessage != null && catalog.meditations.isEmpty) {
      setState(() => _useFallback = true);
    } else if (mounted) {
      setState(() => _useFallback = false);
    }
  }

  void _startApiMeditation(BuildContext context, Meditation med, int index) async {
    final player = context.read<MeditationPlayer>();
    final beacon = context.read<BeaconService>();
    final mixEngine = context.read<MixEngine>();
    final apiClient = context.read<ApiClient>();
    final sessionService = context.read<SessionService>();

    // Auto-connect beacon
    if (!beacon.isConnected) {
      beacon.connect(livekitUrl);
    }

    // Start session tracking
    await sessionService.startSession(SessionType.MEDITATION,
        meditationId: med.id);

    // Apply default mix
    mixEngine.setInitialMix(med.defaultMix);

    try {
      final url = apiClient.getStreamUrl('/api/meditations/${med.id}/audio');
      await player.loadUrl(
        url,
        headers: apiClient.authHeaders,
        title: med.title,
        meditationId: med.id,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load ${med.title}: $e')),
        );
      }
    }
  }

  void _startFallbackMeditation(
      BuildContext context, _FallbackMeditation med) async {
    final player = context.read<MeditationPlayer>();
    final beacon = context.read<BeaconService>();

    if (!beacon.isConnected) {
      beacon.connect(livekitUrl);
    }

    try {
      await player.load(med.assetPath, title: med.title);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load ${med.title}: $e')),
        );
      }
    }
  }

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
            padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(
              'Choose a meditation to begin',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 16,
              ),
            ),
          ),
          // Tag filter bar (only when using API)
          if (!_useFallback)
            Consumer<CatalogService>(
              builder: (context, catalog, _) {
                if (catalog.allTags.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TagFilterBar(
                    tags: catalog.allTags,
                    activeSlug: catalog.activeTagSlug,
                    onTagSelected: (slug) => catalog.setTagFilter(slug),
                  ),
                );
              },
            ),
          // Meditation list
          Expanded(
            child: _useFallback ? _buildFallbackList() : _buildApiList(),
          ),
          // Bottom sheet player
          Consumer<MeditationPlayer>(
            builder: (context, player, child) {
              if (player.currentAsset == null) {
                return const _EmptyPlayerHint();
              }
              return _PlayerBottomSheet(player: player);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApiList() {
    return Consumer<CatalogService>(
      builder: (context, catalog, _) {
        if (catalog.isLoading && catalog.meditations.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6346FF)),
          );
        }
        if (catalog.meditations.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.self_improvement,
                    color: Colors.white24, size: 48),
                const SizedBox(height: 12),
                Text(
                  catalog.errorMessage ?? 'No meditations available',
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: catalog.meditations.length,
            itemBuilder: (context, index) {
              final med = catalog.meditations[index];
              final colors = _apiGradients[index % _apiGradients.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: MeditationCard(
                  title: med.title,
                  subtitle: med.description ?? 'Meditation',
                  duration: med.formattedDuration,
                  gradientColors: colors,
                  providerName: med.provider?.name,
                  isFavorite: catalog.isFavorite(med.id),
                  onFavoriteToggle: () => catalog.toggleFavorite(med.id),
                  tags: med.tags,
                  onTap: () => _startApiMeditation(context, med, index),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFallbackList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _fallbackMeditations.length,
      itemBuilder: (context, index) {
        final med = _fallbackMeditations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: MeditationCard(
            title: med.title,
            subtitle: med.subtitle,
            duration: med.duration,
            gradientColors: med.gradientColors,
            onTap: () => _startFallbackMeditation(context, med),
          ),
        );
      },
    );
  }
}

class _EmptyPlayerHint extends StatelessWidget {
  const _EmptyPlayerHint();

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
    final sessionService = context.read<SessionService>();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
                                  ? 'Beacon ${beacon.isLiveSource ? "live" : "playlist"}'
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
                onTap: () {
                  player.stop();
                  sessionService.endSession();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
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
                            player
                                .seek(Duration(milliseconds: v.toInt()));
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
