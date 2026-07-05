import 'package:flutter/foundation.dart';

import '../models/scheduled_session.dart';
import 'api_client.dart';

class ScheduledSessionService extends ChangeNotifier {
  final ApiClient _api;

  List<ScheduledSession> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  ScheduledSessionService(this._api);

  List<ScheduledSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSessions(
      {List<ScheduledSessionStatus>? statuses}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (statuses != null && statuses.isNotEmpty) {
        params['status'] = statuses.map((s) => s.name).join(',');
      }

      final body =
          await _api.get('/api/scheduled-sessions', queryParams: params);
      final items = body['sessions'] as List<dynamic>? ?? [];
      _sessions = items
          .map((j) => ScheduledSession.fromJson(j as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load scheduled sessions';
      debugPrint('ScheduledSessionService.fetchSessions: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String> getToken(String sessionId, {String? invite}) async {
    final params = <String, String>{};
    if (invite != null) params['invite'] = invite;

    final body = await _api.get('/api/scheduled-sessions/$sessionId/token',
        queryParams: params);
    return body['token'] as String;
  }

  Future<ScheduledSession> resolveInvite(String code) async {
    final body = await _api.get('/api/invites/$code');
    return ScheduledSession.fromJson(body);
  }
}
