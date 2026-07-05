import 'package:flutter_test/flutter_test.dart';
import 'package:harmonic_beacon/models/session.dart';

void main() {
  group('ListeningSession.fromJson', () {
    test('parses full session', () {
      final s = ListeningSession.fromJson({
        'id': 's1',
        'type': 'MEDITATION',
        'durationSeconds': 600,
        'completed': true,
        'startedAt': '2026-03-12T10:00:00Z',
        'endedAt': '2026-03-12T10:10:00Z',
        'meditationTitle': 'Morning Calm',
      });

      expect(s.id, 's1');
      expect(s.type, SessionType.MEDITATION);
      expect(s.durationSeconds, 600);
      expect(s.completed, true);
      expect(s.startedAt, DateTime.parse('2026-03-12T10:00:00Z'));
      expect(s.endedAt, DateTime.parse('2026-03-12T10:10:00Z'));
      expect(s.meditationTitle, 'Morning Calm');
    });

    test('handles LIVE type', () {
      final s = ListeningSession.fromJson({
        'id': 's2',
        'type': 'LIVE',
        'durationSeconds': 300,
        'completed': false,
        'startedAt': '2026-03-12T10:00:00Z',
      });
      expect(s.type, SessionType.LIVE);
      expect(s.endedAt, isNull);
      expect(s.meditationTitle, isNull);
    });

    test('handles SCHEDULED_SESSION type', () {
      final s = ListeningSession.fromJson({
        'id': 's3',
        'type': 'SCHEDULED_SESSION',
        'startedAt': '2026-03-12T10:00:00Z',
      });
      expect(s.type, SessionType.SCHEDULED_SESSION);
    });

    test('defaults type to LIVE on unknown', () {
      final s = ListeningSession.fromJson({
        'id': 's4',
        'type': 'UNKNOWN',
        'startedAt': '2026-03-12T10:00:00Z',
      });
      expect(s.type, SessionType.LIVE);
    });

    test('formattedDuration works', () {
      final s = ListeningSession.fromJson({
        'id': 'x',
        'durationSeconds': 125,
        'startedAt': '2026-03-12T10:00:00Z',
      });
      expect(s.formattedDuration, '02:05');
    });
  });
}
