enum UserRole { LISTENER, PROVIDER, ADMIN }

UserRole _parseRole(String value) {
  switch (value.toUpperCase()) {
    case 'PROVIDER':
      return UserRole.PROVIDER;
    case 'ADMIN':
      return UserRole.ADMIN;
    default:
      return UserRole.LISTENER;
  }
}

class UserStats {
  final int totalSessions;
  final int totalMinutes;
  final int favoritesCount;

  const UserStats({
    this.totalSessions = 0,
    this.totalMinutes = 0,
    this.favoritesCount = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalSessions: json['totalSessions'] as int? ?? 0,
      totalMinutes: json['totalMinutes'] as int? ?? 0,
      favoritesCount: json['favoritesCount'] as int? ?? 0,
    );
  }
}

class UserProfile {
  final String name;
  final String email;
  final String? avatarUrl;
  final UserRole role;
  final UserStats stats;

  const UserProfile({
    required this.name,
    required this.email,
    this.avatarUrl,
    this.role = UserRole.LISTENER,
    this.stats = const UserStats(),
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      role: _parseRole(json['role'] as String? ?? 'LISTENER'),
      stats: json['stats'] != null
          ? UserStats.fromJson(json['stats'] as Map<String, dynamic>)
          : const UserStats(),
    );
  }
}
