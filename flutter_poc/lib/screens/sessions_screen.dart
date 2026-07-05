import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../main.dart';
import '../models/session.dart';
import '../services/beacon_service.dart';
import '../services/session_service.dart';
import '../theme.dart';
import '../widgets/session_history_card.dart';

/// Sessions screen — timer ring, session tracking, and history.
class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  bool _isActive = false;
  int _durationSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionService>().fetchHistory();
    });
  }

  void _startSession() async {
    final beacon = context.read<BeaconService>();
    final sessionService = context.read<SessionService>();

    setState(() {
      _isActive = true;
      _durationSeconds = 0;
    });

    WakelockPlus.enable();

    // Auto-connect beacon
    if (!beacon.isConnected) {
      beacon.connect(livekitUrl);
    }

    // Start server-side session
    await sessionService.startSession(SessionType.LIVE);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _durationSeconds++);
    });
  }

  void _endSession() async {
    _timer?.cancel();
    _timer = null;
    WakelockPlus.disable();
    setState(() => _isActive = false);

    final sessionService = context.read<SessionService>();
    await sessionService.endSession(completed: true);
    // Refresh history after ending
    await sessionService.fetchHistory();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  String get _formattedDuration {
    final m = (_durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Sessions',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Track your Journey',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              // Health Connect — Coming Soon badge
              _HealthConnectBadge(),
              const SizedBox(height: 24),

              // Active session or start prompt
              if (_isActive) ...[
                _TimerSection(
                  durationSeconds: _durationSeconds,
                  formattedDuration: _formattedDuration,
                ),
                const SizedBox(height: 32),
                _EndSessionButton(onPressed: _endSession),
              ] else ...[
                _StartSessionPrompt(onPressed: _startSession),
              ],

              const SizedBox(height: 32),

              // Session history from API
              const Text(
                'Recent Sessions',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Consumer<SessionService>(
                builder: (context, service, _) {
                  if (service.isLoading && service.history.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: AppColors.primary500,
                        ),
                      ),
                    );
                  }
                  if (service.history.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No sessions yet.\nStart your first session above!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      ...service.history.map(
                        (session) => SessionHistoryCard(session: session),
                      ),
                      if (service.history.length < service.totalCount)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: () => service.fetchHistory(
                              offset: service.history.length,
                            ),
                            child: const Text(
                              'Load more',
                              style: TextStyle(color: AppColors.primary400),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Sub-widgets ---

class _HealthConnectBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.monitor_heart_outlined,
                color: AppColors.primary400, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Connect',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Biometrics tracking — Coming Soon',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent400.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Soon',
              style: TextStyle(
                color: AppColors.accent400,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerSection extends StatelessWidget {
  final int durationSeconds;
  final String formattedDuration;

  const _TimerSection({
    required this.durationSeconds,
    required this.formattedDuration,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (durationSeconds % 60) / 60.0;

    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: CustomPaint(
          painter: _TimerRingPainter(progress: progress),
          child: Center(
            child: Text(
              formattedDuration,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 40,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;

  _TimerRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 6.0;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.borderSubtle
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2, // Start from top
      2 * pi * progress,
      false,
      Paint()
        ..shader = const SweepGradient(
          startAngle: -pi / 2,
          endAngle: 3 * pi / 2,
          colors: [AppColors.primary500, AppColors.accent400],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TimerRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _EndSessionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _EndSessionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.live.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'End Session',
          style: TextStyle(
            color: AppColors.live,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StartSessionPrompt extends StatelessWidget {
  final VoidCallback onPressed;

  const _StartSessionPrompt({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        // Orb
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary600,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary500.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Start a Session',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Listen to the beacon and track\nyour listening journey.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Begin Session',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
