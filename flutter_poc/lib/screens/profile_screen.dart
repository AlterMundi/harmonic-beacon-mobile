import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/beacon_service.dart';
import '../services/user_service.dart';
import '../theme.dart';

/// Profile screen — user info, real stats, role badge, and sign-out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserService>().fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Profile',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'My Harmonic Journey',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),

              // Profile card with avatar
              Consumer<UserService>(
                builder: (context, userService, _) {
                  final profile = userService.profile;
                  return _ProfileCard(
                    displayName: profile?.name ??
                        auth.displayName ??
                        'Beacon Listener',
                    avatarUrl: profile?.avatarUrl,
                    role: profile?.role,
                  );
                },
              ),
              const SizedBox(height: 24),

              // Stats row from API
              Consumer<UserService>(
                builder: (context, userService, _) {
                  if (userService.isLoading && userService.profile == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: AppColors.primary500,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  final stats = userService.profile?.stats ?? const UserStats();
                  return _StatsRow(stats: stats);
                },
              ),
              const SizedBox(height: 32),

              // Menu items
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.settings_rounded,
                      label: 'App Settings',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Sign out
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _handleSignOut(context),
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Version
              const Center(
                child: Text(
                  'Harmonic Beacon v1.0.0',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSignOut(BuildContext context) async {
    final beacon = context.read<BeaconService>();
    final auth = context.read<AuthService>();

    await beacon.disconnect();
    await auth.signOut();
  }
}

class _ProfileCard extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final UserRole? role;

  const _ProfileCard({
    required this.displayName,
    this.avatarUrl,
    this.role,
  });

  String get _roleLabel {
    switch (role) {
      case UserRole.ADMIN:
        return 'Admin';
      case UserRole.PROVIDER:
        return 'Provider';
      case UserRole.LISTENER:
      case null:
        return 'Listener';
    }
  }

  Color get _roleColor {
    switch (role) {
      case UserRole.ADMIN:
        return AppColors.error;
      case UserRole.PROVIDER:
        return AppColors.accent400;
      case UserRole.LISTENER:
      case null:
        return AppColors.primary400;
    }
  }

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
          // Avatar
          if (avatarUrl != null)
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(avatarUrl!),
              backgroundColor: AppColors.primary600,
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary600,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary500.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome,',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Role badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _roleLabel,
                    style: TextStyle(
                      color: _roleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final UserStats stats;

  const _StatsRow({required this.stats});

  String get _formattedTime {
    final h = stats.totalMinutes ~/ 60;
    final m = stats.totalMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          value: '${stats.totalSessions}',
          label: 'Sessions',
          icon: Icons.headphones_rounded,
        ),
        const SizedBox(width: 12),
        _StatItem(
          value: _formattedTime,
          label: 'Listening',
          icon: Icons.timer_outlined,
        ),
        const SizedBox(width: 12),
        _StatItem(
          value: '${stats.favoritesCount}',
          label: 'Favorites',
          icon: Icons.favorite_rounded,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary400, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.textPrimary, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
