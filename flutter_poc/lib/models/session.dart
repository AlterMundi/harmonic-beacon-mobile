enum SessionType { LIVE, MEDITATION, SCHEDULED_SESSION }

SessionType _parseSessionType(String value) {
  switch (value.toUpperCase()) {
    case 'LIVE':
      return SessionType.LIVE;
    case 'MEDITATION':
      return SessionType.MEDITATION;
    case 'SCHEDULED_SESSION':
      return SessionType.SCHEDULED_SESSION;
    default:
      return SessionType.LIVE;
  }
}

class ListeningSession {
  final String id;
  final SessionType type;
  final int durationSeconds;
  final bool completed;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? meditationTitle;

  const ListeningSession({
    required this.id,
    required this.type,
    required this.durationSeconds,
    required this.completed,
    required this.startedAt,
    this.endedAt,
    this.meditationTitle,
  });

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  factory ListeningSession.fromJson(Map<String, dynamic> json) {
    return ListeningSession(
      id: json['id'] as String,
      type: _parseSessionType(json['type'] as String? ?? 'LIVE'),
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      meditationTitle: json['meditationTitle'] as String?,
    );
  }
}
