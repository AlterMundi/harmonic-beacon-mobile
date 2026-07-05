import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import 'api_client.dart';

class UserService extends ChangeNotifier {
  final ApiClient _api;

  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserService(this._api);

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = await _api.get('/api/users/me');
      _profile = UserProfile.fromJson(body);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load profile';
      debugPrint('UserService.fetchProfile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
