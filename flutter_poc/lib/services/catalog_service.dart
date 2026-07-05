import 'package:flutter/foundation.dart';

import '../models/meditation.dart';
import 'api_client.dart';

class CatalogService extends ChangeNotifier {
  final ApiClient _api;

  List<Meditation> _meditations = [];
  Map<TagCategory, List<Tag>> _tagsByCategory = {};
  Set<String> _favoriteIds = {};
  String? _activeTagSlug;
  bool _isLoading = false;
  bool _isLoadingTags = false;
  String? _errorMessage;

  CatalogService(this._api);

  List<Meditation> get meditations => _meditations;
  Map<TagCategory, List<Tag>> get tagsByCategory => _tagsByCategory;
  List<Tag> get allTags =>
      _tagsByCategory.values.expand((tags) => tags).toList();
  Set<String> get favoriteIds => _favoriteIds;
  String? get activeTagSlug => _activeTagSlug;
  bool get isLoading => _isLoading;
  bool get isLoadingTags => _isLoadingTags;
  String? get errorMessage => _errorMessage;

  bool isFavorite(String meditationId) => _favoriteIds.contains(meditationId);

  Future<void> fetchMeditations({String? tagSlug}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (tagSlug != null) params['tag'] = tagSlug;

      final body = await _api.get('/api/meditations', queryParams: params);
      final items = body['meditations'] as List<dynamic>? ?? [];
      _meditations =
          items.map((j) => Meditation.fromJson(j as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load meditations';
      debugPrint('CatalogService.fetchMeditations: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTags() async {
    _isLoadingTags = true;
    notifyListeners();

    try {
      final body = await _api.get('/api/tags');
      final items = body['tags'] as List<dynamic>? ?? [];
      final tags =
          items.map((j) => Tag.fromJson(j as Map<String, dynamic>)).toList();

      _tagsByCategory = {};
      for (final tag in tags) {
        _tagsByCategory.putIfAbsent(tag.category, () => []).add(tag);
      }
    } catch (e) {
      debugPrint('CatalogService.fetchTags: $e');
    }

    _isLoadingTags = false;
    notifyListeners();
  }

  Future<void> fetchFavorites() async {
    try {
      final body = await _api.get('/api/favorites');
      final items = body['favorites'] as List<dynamic>? ?? [];
      _favoriteIds = items.map((j) {
        final map = j as Map<String, dynamic>;
        return map['meditationId'] as String? ?? map['id'] as String? ?? '';
      }).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('CatalogService.fetchFavorites: $e');
    }
  }

  Future<void> toggleFavorite(String meditationId) async {
    // Optimistic update
    final wasFavorite = _favoriteIds.contains(meditationId);
    if (wasFavorite) {
      _favoriteIds.remove(meditationId);
    } else {
      _favoriteIds.add(meditationId);
    }
    notifyListeners();

    try {
      await _api.post('/api/favorites', body: {'meditationId': meditationId});
    } catch (e) {
      // Revert on failure
      if (wasFavorite) {
        _favoriteIds.add(meditationId);
      } else {
        _favoriteIds.remove(meditationId);
      }
      notifyListeners();
      debugPrint('CatalogService.toggleFavorite: $e');
    }
  }

  void setTagFilter(String? slug) {
    _activeTagSlug = slug;
    fetchMeditations(tagSlug: slug);
  }
}
