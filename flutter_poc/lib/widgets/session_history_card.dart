import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/session.dart';
import '../theme.dart';

class SessionHistoryCard extends StatelessWidget {
  final ListeningSession session;

  const SessionHistoryCard({super.key, required this.session});

  IconData get _typeIcon {
    switch (session.type) {
      case SessionType.LIVE:
        return Icons.radio;
      case SessionType.MEDITATION:
        return Icons.self_improvement;
      case SessionType.SCHEDULED_SESSION:
        return Icons.event;
    }
  }

  String get _typeLabel {
    switch (session.type) {
      case SessionType.LIVE:
        return 'Live';
      case SessionType.MEDITATION:
        return session.meditationTitle ?? 'Meditation';
      case SessionType.SCHEDULED_SESSION:
        return 'Scheduled Session';
    }
  }

  String get _formattedDate {
    final now = DateTime.now();
    final date = session.startedAt;
    final diff = now.difference(date);

    if (diff.inDays == 0 && date.day == now.day) return 'Today';
    if (diff.inDays <= 1 && date.day == now.subtract(const Duration(days: 1)).day) {
      return 'Yesterday';
    }
    return DateFormat('MMM d').format(date);
  }

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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon, color: AppColors.primary400, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$_formattedDate  •  ${session.formattedDuration}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (session.completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}
