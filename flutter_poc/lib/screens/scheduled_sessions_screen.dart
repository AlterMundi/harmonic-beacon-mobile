import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/scheduled_session.dart';
import '../services/beacon_service.dart';
import '../services/scheduled_session_service.dart';
import '../theme.dart';

class ScheduledSessionsScreen extends StatefulWidget {
  const ScheduledSessionsScreen({super.key});

  @override
  State<ScheduledSessionsScreen> createState() =>
      _ScheduledSessionsScreenState();
}

class _ScheduledSessionsScreenState extends State<ScheduledSessionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduledSessionService>().fetchSessions(
            statuses: [
              ScheduledSessionStatus.SCHEDULED,
              ScheduledSessionStatus.LIVE,
            ],
          );
    });
  }

  Future<void> _refresh() {
    return context.read<ScheduledSessionService>().fetchSessions(
          statuses: [
            ScheduledSessionStatus.SCHEDULED,
            ScheduledSessionStatus.LIVE,
          ],
        );
  }

  void _joinSession(ScheduledSession session) async {
    final service = context.read<ScheduledSessionService>();
    final beacon = context.read<BeaconService>();

    try {
      final token = await service.getToken(session.id);
      await beacon.connect(livekitUrl, directToken: token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined "${session.title}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'Events',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Upcoming & live sessions',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
            // Invite code entry
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: _InviteCodeBar(
                onJoin: (code) async {
                  final service = context.read<ScheduledSessionService>();
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final session = await service.resolveInvite(code);
                    if (mounted) _joinSession(session);
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Invalid invite code: $e')),
                      );
                    }
                  }
                },
              ),
            ),
            Expanded(
              child: Consumer<ScheduledSessionService>(
                builder: (context, service, _) {
                  if (service.isLoading && service.sessions.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary500,
                      ),
                    );
                  }
                  if (service.sessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_outlined,
                              color: Colors.white24, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            service.errorMessage ?? 'No upcoming events',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: service.sessions.length,
                      itemBuilder: (context, index) {
                        final session = service.sessions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ScheduledSessionCard(
                            session: session,
                            onJoin: session.status == ScheduledSessionStatus.LIVE
                                ? () => _joinSession(session)
                                : null,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCodeBar extends StatefulWidget {
  final Future<void> Function(String code) onJoin;

  const _InviteCodeBar({required this.onJoin});

  @override
  State<_InviteCodeBar> createState() => _InviteCodeBarState();
}

class _InviteCodeBarState extends State<_InviteCodeBar> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Enter invite code',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      final code = _controller.text.trim();
                      if (code.isEmpty) return;
                      setState(() => _isLoading = true);
                      await widget.onJoin(code);
                      if (mounted) {
                        setState(() => _isLoading = false);
                        _controller.clear();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Join',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
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

class _ScheduledSessionCard extends StatelessWidget {
  final ScheduledSession session;
  final VoidCallback? onJoin;

  const _ScheduledSessionCard({required this.session, this.onJoin});

  Color get _statusColor {
    switch (session.status) {
      case ScheduledSessionStatus.LIVE:
        return AppColors.live;
      case ScheduledSessionStatus.SCHEDULED:
        return AppColors.primary400;
      case ScheduledSessionStatus.ENDED:
        return AppColors.textMuted;
      case ScheduledSessionStatus.CANCELLED:
        return AppColors.textMuted;
    }
  }

  String get _statusLabel {
    switch (session.status) {
      case ScheduledSessionStatus.LIVE:
        return 'LIVE';
      case ScheduledSessionStatus.SCHEDULED:
        return 'Upcoming';
      case ScheduledSessionStatus.ENDED:
        return 'Ended';
      case ScheduledSessionStatus.CANCELLED:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: session.status == ScheduledSessionStatus.LIVE
              ? AppColors.live.withValues(alpha: 0.3)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (session.providerName != null)
            Text(
              session.providerName!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          Row(
            children: [
              if (session.scheduledAt != null) ...[
                const Icon(Icons.access_time, color: AppColors.textMuted, size: 14),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, h:mm a').format(session.scheduledAt!),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              const Icon(Icons.people_outline, color: AppColors.textMuted, size: 14),
              const SizedBox(width: 4),
              Text(
                '${session.participantCount}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (onJoin != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Join Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
