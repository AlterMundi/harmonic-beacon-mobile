import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harmonic_beacon/services/api_client.dart';
import 'package:harmonic_beacon/services/auth_service.dart';
import 'package:harmonic_beacon/services/catalog_service.dart';

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
  group('CatalogService', () {
    test('fetchMeditations populates list', () async {
      final mock = MockClient((request) async {
        if (request.url.path == '/api/meditations') {
          return http.Response(
            jsonEncode({
              'meditations': [
                {
                  'id': 'm1',
                  'title': 'Test',
                  'durationSeconds': 120,
                  'streamName': 'test',
                  'fileName': 'test.m4a',
                  'tags': [],
                },
              ]
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = CatalogService(_buildClient(mock));
      await service.fetchMeditations();

      expect(service.meditations.length, 1);
      expect(service.meditations.first.title, 'Test');
      expect(service.errorMessage, isNull);
    });

    test('fetchMeditations sets error on failure', () async {
      final mock = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Server error'}), 500);
      });

      final service = CatalogService(_buildClient(mock));
      await service.fetchMeditations();

      expect(service.meditations, isEmpty);
      expect(service.errorMessage, isNotNull);
    });

    test('fetchTags populates tagsByCategory', () async {
      final mock = MockClient((request) async {
        if (request.url.path == '/api/tags') {
          return http.Response(
            jsonEncode({
              'tags': [
                {'id': 't1', 'name': 'Calm', 'slug': 'calm', 'category': 'MOOD'},
                {'id': 't2', 'name': 'Focus', 'slug': 'focus', 'category': 'TECHNIQUE'},
              ]
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = CatalogService(_buildClient(mock));
      await service.fetchTags();

      expect(service.allTags.length, 2);
      expect(service.tagsByCategory.length, 2);
    });

    test('fetchFavorites populates favoriteIds', () async {
      final mock = MockClient((request) async {
        if (request.url.path == '/api/favorites') {
          return http.Response(
            jsonEncode({
              'favorites': [
                {'meditationId': 'm1'},
                {'meditationId': 'm2'},
              ]
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = CatalogService(_buildClient(mock));
      await service.fetchFavorites();

      expect(service.favoriteIds, {'m1', 'm2'});
      expect(service.isFavorite('m1'), true);
      expect(service.isFavorite('m3'), false);
    });

    test('toggleFavorite adds optimistically', () async {
      final mock = MockClient((request) async {
        return http.Response(jsonEncode({}), 200);
      });

      final service = CatalogService(_buildClient(mock));
      await service.toggleFavorite('m1');

      expect(service.isFavorite('m1'), true);
    });

    test('setTagFilter calls fetchMeditations with slug', () async {
      int callCount = 0;
      final mock = MockClient((request) async {
        callCount++;
        if (request.url.path == '/api/meditations') {
          if (callCount == 1) {
            expect(request.url.queryParameters['tag'], 'calm');
          }
          return http.Response(jsonEncode({'meditations': []}), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = CatalogService(_buildClient(mock));
      service.setTagFilter('calm');
      // Wait for the async fetch
      await Future.delayed(const Duration(milliseconds: 100));

      expect(service.activeTagSlug, 'calm');
    });
  });
}
