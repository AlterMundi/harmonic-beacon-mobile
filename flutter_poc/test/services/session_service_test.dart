import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harmonic_beacon/models/session.dart';
import 'package:harmonic_beacon/services/api_client.dart';
import 'package:harmonic_beacon/services/auth_service.dart';
import 'package:harmonic_beacon/services/session_service.dart';

class _FakeAuthService extends AuthService {
  @override
  String? get accessToken => 'test-token';
  @override
  Future<String?> getFreshAccessToken() async => 'test-token';
  @override
  Future<void> signOut() async {}
}

ApiClient _buildClient(http.Client mock) {
  return ApiClient(
    authService: _FakeAuthService(),
    baseUrl: 'https://api.test',
    httpClient: mock,
  );
}

void main() {
  group('SessionService', () {
    test('startSession sets activeSessionId', () async {
      final mock = MockClient((request) async {
        if (request.url.path == '/api/sessions' && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['type'], 'LIVE');
          return http.Response(jsonEncode({'id': 'sess-1'}), 201);
        }
        return http.Response('', 404);
      });

      final service = SessionService(_buildClient(mock));
      await service.startSession(SessionType.LIVE);

      expect(service.activeSessionId, 'sess-1');
      expect(service.hasActiveSession, true);
    });

    test('endSession clears activeSessionId', () async {
      final mock = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(jsonEncode({'id': 'sess-1'}), 201);
        }
        if (request.method == 'PATCH') {
          expect(request.url.path, '/api/sessions/sess-1');
          return http.Response(jsonEncode({}), 200);
        }
        return http.Response('', 404);
      });

      final service = SessionService(_buildClient(mock));
      await service.startSession(SessionType.LIVE);
      expect(service.hasActiveSession, true);

      await service.endSession(completed: true);
      expect(service.hasActiveSession, false);
    });

    test('ignores startSession when already active', () async {
      int postCount = 0;
      final mock = MockClient((request) async {
        if (request.method == 'POST') {
          postCount++;
          return http.Response(jsonEncode({'id': 'sess-1'}), 201);
        }
        return http.Response('', 404);
      });

      final service = SessionService(_buildClient(mock));
      await service.startSession(SessionType.LIVE);
      await service.startSession(SessionType.LIVE); // should be ignored

      expect(postCount, 1);
    });

    test('fetchHistory populates list', () async {
      final mock = MockClient((request) async {
        if (request.url.path == '/api/sessions' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'sessions': [
                {
                  'id': 's1',
                  'type': 'LIVE',
                  'durationSeconds': 300,
                  'completed': true,
                  'startedAt': '2026-03-12T10:00:00Z',
                },
              ],
              'total': 5,
            }),
            200,
          );
        }
        return http.Response('', 404);
      });

      final service = SessionService(_buildClient(mock));
      await service.fetchHistory();

      expect(service.history.length, 1);
      expect(service.totalCount, 5);
    });

    test('fetchHistory appends on offset > 0', () async {
      int callNum = 0;
      final mock = MockClient((request) async {
        callNum++;
        return http.Response(
          jsonEncode({
            'sessions': [
              {
                'id': 's$callNum',
                'type': 'LIVE',
                'durationSeconds': 100,
                'completed': true,
                'startedAt': '2026-03-12T10:00:00Z',
              },
            ],
            'total': 2,
          }),
          200,
        );
      });

      final service = SessionService(_buildClient(mock));
      await service.fetchHistory();
      expect(service.history.length, 1);

      await service.fetchHistory(offset: 1);
      expect(service.history.length, 2);
    });
  });
}
