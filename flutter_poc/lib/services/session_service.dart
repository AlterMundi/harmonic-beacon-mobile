import 'package:flutter/foundation.dart';

import '../models/session.dart';
import 'api_client.dart';

class SessionService extends ChangeNotifier {
  final ApiClient _api;

  String? _activeSessionId;
  List<ListeningSession> _history = [];
  int _totalCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  SessionService(this._api);

  String? get activeSessionId => _activeSessionId;
  List<ListeningSession> get history => _history;
  int get totalCount => _totalCount;
  bool get isLoading => _isLoading;
  bool get hasActiveSession => _activeSessionId != null;
  String? get errorMessage => _errorMessage;

  Future<void> startSession(SessionType type, {String? meditationId}) async {
    if (_activeSessionId != null) return; // already active

    try {
      final body = await _api.post('/api/sessions', body: {
        'type': type.name,
        if (meditationId != null) 'meditationId': meditationId,
      });
      _activeSessionId = body['id'] as String? ?? body['sessionId'] as String?;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      debugPrint('SessionService.startSession: $e');
    } catch (e) {
      debugPrint('SessionService.startSession: $e');
    }
  }

  Future<void> endSession({bool completed = true}) async {
    if (_activeSessionId == null) return;

    try {
      await _api.patch('/api/sessions/$_activeSessionId', body: {
        'completed': completed,
      });
    } catch (e) {
      debugPrint('SessionService.endSession: $e');
    }

    _activeSessionId = null;
    notifyListeners();
  }

  Future<void> fetchHistory({int limit = 20, int offset = 0}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = await _api.get('/api/sessions', queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      });
      final items = body['sessions'] as List<dynamic>? ?? [];
      final sessions = items
          .map((j) => ListeningSession.fromJson(j as Map<String, dynamic>))
          .toList();

      if (offset == 0) {
        _history = sessions;
      } else {
        _history = [..._history, ...sessions];
      }
      _totalCount = body['total'] as int? ?? _history.length;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load sessions';
      debugPrint('SessionService.fetchHistory: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
