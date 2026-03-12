import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../services/beacon_service.dart';
import '../theme.dart';

/// Sessions screen — health tracking, timer ring, and biometrics simulation.
class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  bool _isActive = false;
  bool _healthConnected = false;
  int _durationSeconds = 0;
  double _heartRate = 72.0;
  double _hrv = 45.0;
  Timer? _timer;
  final _random = Random();

  // Static past sessions for MVP
  static const _pastSessions = [
    {'date': 'Today', 'duration': '15:42', 'avgHr': '68', 'hrv': '+12%'},
    {'date': 'Yesterday', 'duration': '22:18', 'avgHr': '71', 'hrv': '+8%'},
    {'date': 'Mar 8', 'duration': '10:05', 'avgHr': '74', 'hrv': '+5%'},
  ];

  void _startSession() {
    final beacon = context.read<BeaconService>();
    final auth = context.read<AuthService>();

    setState(() {
      _isActive = true;
      _durationSeconds = 0;
      _heartRate = 68 + _random.nextDouble() * 8;
      _hrv = 40 + _random.nextDouble() * 15;
    });

    WakelockPlus.enable();

    // Auto-connect beacon
    if (!beacon.isConnected && auth.accessToken != null) {
      beacon.connect(livekitUrl, auth.accessToken!);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _durationSeconds++;
        // Simulate biometric fluctuation
        _heartRate = (_heartRate + (_random.nextDouble() - 0.5) * 3).clamp(55, 85);
        _hrv = (_hrv + (_random.nextDouble() - 0.5) * 4).clamp(25, 75);
      });
    });
  }

  void _endSession() {
    _timer?.cancel();
    _timer = null;
    WakelockPlus.disable();
    setState(() => _isActive = false);
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

              // Health connect card
              _HealthConnectCard(
                isConnected: _healthConnected,
                onToggle: () => setState(() => _healthConnected = !_healthConnected),
              ),
              const SizedBox(height: 24),

              // Active session or start prompt
              if (_isActive) ...[
                _TimerSection(
                  durationSeconds: _durationSeconds,
                  formattedDuration: _formattedDuration,
                ),
                const SizedBox(height: 24),
                _BiometricsRow(heartRate: _heartRate, hrv: _hrv),
                const SizedBox(height: 32),
                _EndSessionButton(onPressed: _endSession),
              ] else ...[
                _StartSessionPrompt(onPressed: _startSession),
              ],

              const SizedBox(height: 32),

              // Past sessions
              const Text(
                'Recent Sessions',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ..._pastSessions.map((s) => _PastSessionCard(session: s)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Sub-widgets ---

class _HealthConnectCard extends StatelessWidget {
  final bool isConnected;
  final VoidCallback onToggle;

  const _HealthConnectCard({required this.isConnected, required this.onToggle});

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
            child: const Text('❤️', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connect Health',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isConnected ? 'Connected' : 'Link Apple Health / Google Fit',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isConnected
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.primary500.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isConnected
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.primary500.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                isConnected ? 'Connected' : 'Connect',
                style: TextStyle(
                  color: isConnected ? AppColors.success : AppColors.primary300,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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

class _BiometricsRow extends StatelessWidget {
  final double heartRate;
  final double hrv;

  const _BiometricsRow({required this.heartRate, required this.hrv});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.favorite_rounded,
            iconColor: AppColors.live,
            value: '${heartRate.round()}',
            label: 'BPM',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.primary400,
            value: '${hrv.round()}',
            label: 'HRV (ms)',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
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
          'Listen to the beacon and track your\nheart rate variability in real-time.',
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

class _PastSessionCard extends StatelessWidget {
  final Map<String, String> session;

  const _PastSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session['date'] ?? '',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${session['duration']} • Avg HR ${session['avgHr']}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'HRV ${session['hrv']}',
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
