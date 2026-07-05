enum ScheduledSessionStatus { SCHEDULED, LIVE, ENDED, CANCELLED }

ScheduledSessionStatus _parseStatus(String value) {
  switch (value.toUpperCase()) {
    case 'SCHEDULED':
      return ScheduledSessionStatus.SCHEDULED;
    case 'LIVE':
      return ScheduledSessionStatus.LIVE;
    case 'ENDED':
      return ScheduledSessionStatus.ENDED;
    case 'CANCELLED':
      return ScheduledSessionStatus.CANCELLED;
    default:
      return ScheduledSessionStatus.SCHEDULED;
  }
}

class ScheduledSession {
  final String id;
  final String title;
  final String? description;
  final ScheduledSessionStatus status;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final String? providerName;
  final int participantCount;

  const ScheduledSession({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.scheduledAt,
    this.startedAt,
    this.providerName,
    this.participantCount = 0,
  });

  factory ScheduledSession.fromJson(Map<String, dynamic> json) {
    return ScheduledSession(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: _parseStatus(json['status'] as String? ?? 'SCHEDULED'),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'] as String)
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      providerName: json['providerName'] as String?,
      participantCount: json['participantCount'] as int? ?? 0,
    );
  }
}
