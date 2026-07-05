import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harmonic_beacon/models/user_profile.dart';
import 'package:harmonic_beacon/services/api_client.dart';
import 'package:harmonic_beacon/services/auth_service.dart';
import 'package:harmonic_beacon/services/user_service.dart';

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
  group('UserService', () {
    test('fetchProfile populates profile', () async {
      final mock = MockClient((request) async {
        if (request.url.path == '/api/users/me') {
          return http.Response(
            jsonEncode({
              'name': 'Alice',
              'email': 'alice@example.com',
              'avatarUrl': 'https://example.com/alice.jpg',
              'role': 'LISTENER',
              'stats': {
                'totalSessions': 24,
                'totalMinutes': 512,
                'favoritesCount': 12,
              },
            }),
            200,
          );
        }
        return http.Response('', 404);
      });

      final service = UserService(_buildClient(mock));
      await service.fetchProfile();

      expect(service.profile, isNotNull);
      expect(service.profile!.name, 'Alice');
      expect(service.profile!.email, 'alice@example.com');
      expect(service.profile!.role, UserRole.LISTENER);
      expect(service.profile!.stats.totalSessions, 24);
      expect(service.profile!.stats.totalMinutes, 512);
      expect(service.profile!.stats.favoritesCount, 12);
    });

    test('fetchProfile sets error on failure', () async {
      final mock = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Server error'}), 500);
      });

      final service = UserService(_buildClient(mock));
      await service.fetchProfile();

      expect(service.profile, isNull);
      expect(service.errorMessage, isNotNull);
    });

    test('profile role parsing', () async {
      for (final role in ['LISTENER', 'PROVIDER', 'ADMIN']) {
        final mock = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'name': 'Test',
              'email': 'test@test.com',
              'role': role,
            }),
            200,
          );
        });

        final service = UserService(_buildClient(mock));
        await service.fetchProfile();

        expect(service.profile!.role.name, role);
      }
    });
  });
}
