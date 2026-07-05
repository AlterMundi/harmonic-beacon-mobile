import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:harmonic_beacon/services/api_client.dart';
import 'package:harmonic_beacon/services/auth_service.dart';

/// Minimal fake AuthService for testing ApiClient.
class _FakeAuthService extends AuthService {
  String? fakeAccessToken;
  String? fakeRefreshResult;
  bool signOutCalled = false;

  @override
  String? get accessToken => fakeAccessToken;

  @override
  Future<String?> getFreshAccessToken() async {
    if (fakeRefreshResult != null) {
      fakeAccessToken = fakeRefreshResult;
      return fakeRefreshResult;
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    fakeAccessToken = null;
  }
}

void main() {
  late _FakeAuthService auth;

  setUp(() {
    auth = _FakeAuthService();
    auth.fakeAccessToken = 'test-token';
  });

  test('GET injects Authorization header', () async {
    final mockHttp = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(request.headers['Content-Type'], 'application/json');
      return http.Response(jsonEncode({'ok': true}), 200);
    });

    final client = ApiClient(
      authService: auth,
      baseUrl: 'https://api.test',
      httpClient: mockHttp,
    );

    final result = await client.get('/test');
    expect(result['ok'], true);
    client.dispose();
  });

  test('POST sends JSON body', () async {
    final mockHttp = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['key'], 'value');
      return http.Response(jsonEncode({'created': true}), 201);
    });

    final client = ApiClient(
      authService: auth,
      baseUrl: 'https://api.test',
      httpClient: mockHttp,
    );

    final result = await client.post('/items', body: {'key': 'value'});
    expect(result['created'], true);
    client.dispose();
  });

  test('GET passes query parameters', () async {
    final mockHttp = MockClient((request) async {
      expect(request.url.queryParameters['tag'], 'calm');
      return http.Response(jsonEncode({'items': []}), 200);
    });

    final client = ApiClient(
      authService: auth,
      baseUrl: 'https://api.test',
      httpClient: mockHttp,
    );

    await client.get('/items', queryParams: {'tag': 'calm'});
    client.dispose();
  });

  test('throws ApiException on non-2xx', () async {
    final mockHttp = MockClient((request) async {
      return http.Response(
        jsonEncode({'message': 'Not found'}),
        404,
      );
    });

    final client = ApiClient(
      authService: auth,
      baseUrl: 'https://api.test',
      httpClient: mockHttp,
    );

    expect(
      () => client.get('/missing'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'code', 404)),
    );
    client.dispose();
  });

  test('retries once on 401 with refreshed token', () async {
    int callCount = 0;
    auth.fakeRefreshResult = 'new-token';

    final mockHttp = MockClient((request) async {
      callCount++;
      if (callCount == 1) {
        return http.Response('Unauthorized', 401);
      }
      // Second call should use new token
      expect(request.headers['Authorization'], 'Bearer new-token');
      return http.Response(jsonEncode({'ok': true}), 200);
    });

    final client = ApiClient(
      authService: auth,
      baseUrl: 'https://api.test',
      httpClient: mockHttp,
    );

    final result = await client.get('/protected');
    expect(result['ok'], true);
    expect(callCount, 2);
    client.dispose();
  });

  test('signs out on persistent 401', () async {
    auth.fakeRefreshResult = null; // refresh fails

    final mockHttp = MockClient((request) async {
      return http.Response('Unauthorized', 401);
    });

    final client = ApiClient(
      authService: auth,
      baseUrl: 'https://api.test',
      httpClient: mockHttp,
    );

    expect(
      () => client.get('/protected'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'code', 401)),
    );
    client.dispose();
  });

  test('throws ApiException when not authenticated', () async {
    auth.fakeAccessToken = null;
    final mockHttp = MockClient((request) async {
      return http.Response('', 200);
    });

    final client = ApiClient(
      authService: auth,
      baseUrl: 'https://api.test',
      httpClient: mockHttp,
    );

    expect(
      () => client.get('/test'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'code', 401)),
    );
    client.dispose();
  });

  test('authHeaders returns correct header map', () {
    final client = ApiClient(
      authService: auth,
      baseUrl: 'https://api.test',
    );

    expect(client.authHeaders, {'Authorization': 'Bearer test-token'});
    client.dispose();
  });

  test('getStreamUrl builds full URL', () {
    final client = ApiClient(
      authService: auth,
      baseUrl: 'https://api.test',
    );

    expect(
      client.getStreamUrl('/api/meditations/m1/audio'),
      'https://api.test/api/meditations/m1/audio',
    );
    client.dispose();
  });
}
