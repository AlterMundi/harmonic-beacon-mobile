import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final AuthService _auth;
  final String baseUrl;
  final http.Client _http;

  ApiClient({
    required AuthService authService,
    required this.baseUrl,
    http.Client? httpClient,
  })  : _auth = authService,
        _http = httpClient ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<String> _getToken() async {
    final token = _auth.accessToken;
    if (token == null) throw const ApiException(401, 'Not authenticated');
    return token;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      // Try refreshing the token once
      final freshToken = await _auth.getFreshAccessToken();
      if (freshToken == null) {
        await _auth.signOut();
        throw const ApiException(401, 'Session expired');
      }
      // Return null to signal retry
      throw _RetryException(freshToken);
    }

    String message;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['message'] as String? ??
          body['error'] as String? ??
          'Request failed';
    } catch (_) {
      message = 'Request failed (${response.statusCode})';
    }
    throw ApiException(response.statusCode, message);
  }

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? queryParams}) async {
    final token = await _getToken();
    var uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final response = await _http.get(uri, headers: _headers(token));
      return await _handleResponse(response);
    } on _RetryException catch (e) {
      final response = await _http.get(uri, headers: _headers(e.newToken));
      final result = await _retryHandleResponse(response);
      return result;
    }
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await _http.post(
        uri,
        headers: _headers(token),
        body: body != null ? jsonEncode(body) : null,
      );
      return await _handleResponse(response);
    } on _RetryException catch (e) {
      final response = await _http.post(
        uri,
        headers: _headers(e.newToken),
        body: body != null ? jsonEncode(body) : null,
      );
      return await _retryHandleResponse(response);
    }
  }

  Future<Map<String, dynamic>> patch(String path,
      {Map<String, dynamic>? body}) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await _http.patch(
        uri,
        headers: _headers(token),
        body: body != null ? jsonEncode(body) : null,
      );
      return await _handleResponse(response);
    } on _RetryException catch (e) {
      final response = await _http.patch(
        uri,
        headers: _headers(e.newToken),
        body: body != null ? jsonEncode(body) : null,
      );
      return await _retryHandleResponse(response);
    }
  }

  Future<Map<String, dynamic>> _retryHandleResponse(
      http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      await _auth.signOut();
      throw const ApiException(401, 'Session expired');
    }
    String message;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['message'] as String? ?? 'Request failed';
    } catch (_) {
      message = 'Request failed (${response.statusCode})';
    }
    throw ApiException(response.statusCode, message);
  }

  /// Build a full URL with auth header for streaming (used by just_audio).
  String getStreamUrl(String path) => '$baseUrl$path';

  /// Get auth headers for streaming clients (just_audio).
  Map<String, String>? get authHeaders {
    final token = _auth.accessToken;
    if (token == null) return null;
    return {'Authorization': 'Bearer $token'};
  }

  void dispose() {
    _http.close();
  }
}

class _RetryException implements Exception {
  final String newToken;
  _RetryException(this.newToken);
}
