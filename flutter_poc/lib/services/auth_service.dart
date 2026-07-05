import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles Zitadel OIDC authentication.
///
/// Uses flutter_appauth for the OIDC authorization code flow and
/// flutter_secure_storage for persisting tokens between sessions.
class AuthService extends ChangeNotifier {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _issuer      = 'https://auth.altermundi.net';
  static const _clientId    = '363708423491092739';
  static const _redirectUri = 'com.altermundi.harmonicbeacon://callback';
  static const _scopes      = [
    'openid',
    'profile',
    'email',
    'offline_access',
    // Request project-specific roles. Note: scope uses :id:, claim key does not.
    'urn:zitadel:iam:org:project:id:363708423491027203:roles',
  ];

  // Claim key in the token (no :id: — Zitadel quirk)
  static const _rolesClaim =
      'urn:zitadel:iam:org:project:363708423491027203:roles';

  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  String? _errorMessage;
  Future<void>? _refreshInFlight;

  // --- Public getters ---

  String? get accessToken => _accessToken;
  Map<String, dynamic>? get userInfo => _userInfo;
  bool get isAuthenticated => _accessToken != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get displayName =>
      _userInfo?['name'] as String? ??
      _userInfo?['preferred_username'] as String? ??
      _userInfo?['email'] as String?;

  String? get email => _userInfo?['email'] as String?;

  /// Roles assigned in Zitadel: BEAC_ADMIN, BEAC_PROVIDER, BEAC_LISTENER.
  /// Extracted from the project-specific roles claim in the ID token.
  List<String> get roles {
    final claim = _userInfo?[_rolesClaim];
    if (claim is Map) return claim.keys.cast<String>().toList();
    return [];
  }

  bool get isAdmin    => roles.contains('BEAC_ADMIN');
  bool get isProvider => roles.contains('BEAC_PROVIDER');
  bool get isListener => roles.contains('BEAC_LISTENER');

  // --- Initialization ---

  /// Call once at app startup to restore persisted session.
  Future<void> initialize() async {
    try {
      _accessToken  = await _storage.read(key: 'access_token');
      _refreshToken = await _storage.read(key: 'refresh_token');

      final infoJson = await _storage.read(key: 'user_info');
      if (infoJson != null) {
        _userInfo = jsonDecode(infoJson) as Map<String, dynamic>;
      }

      // Attempt token refresh if we only have a refresh token
      if (_accessToken == null && _refreshToken != null) {
        await _refreshTokens();
      }
    } catch (e) {
      debugPrint('AuthService: initialization error: $e');
      // Non-fatal — user will just see the login screen
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Login ---

  /// Launch the Zitadel OIDC login flow in the system browser.
  /// Returns true on success, false on cancellation or error.
  Future<bool> login() async {
    if (_isLoading) return false; // prevent concurrent calls
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUri,
          issuer: _issuer,
          scopes: _scopes,
        ),
      );

      if (result == null) {
        _errorMessage = 'Login was cancelled';
        notifyListeners();
        return false;
      }

      _accessToken  = result.accessToken;
      _refreshToken = result.refreshToken;

      // Extract user info from ID token JWT payload
      if (result.idToken != null) {
        _userInfo = _decodeJwtPayload(result.idToken!);
      }

      await _persist();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthService: login failed: $e');
      _errorMessage = 'Login failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Token Refresh ---

  Future<void> _refreshTokens() async {
    if (_refreshToken == null) return;

    try {
      final result = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUri,
          issuer: _issuer,
          refreshToken: _refreshToken,
          scopes: _scopes,
        ),
      );

      if (result != null) {
        _accessToken  = result.accessToken ?? _accessToken;
        _refreshToken = result.refreshToken ?? _refreshToken;
        await _persist();
      }
    } catch (e) {
      debugPrint('AuthService: token refresh failed: $e');
      // Refresh token is expired — clear everything so user goes to login
      await signOut();
    }
  }

  /// Attempt to refresh the access token. Callers can use this before making
  /// API requests to ensure the token is fresh.
  /// Serialized: concurrent callers share the same in-flight refresh.
  Future<String?> getFreshAccessToken() async {
    if (_refreshToken == null) return _accessToken;

    // If a refresh is already running, wait for it instead of starting another.
    if (_refreshInFlight != null) {
      await _refreshInFlight;
      return _accessToken;
    }

    _refreshInFlight = _refreshTokens();
    try {
      await _refreshInFlight;
    } finally {
      _refreshInFlight = null;
    }
    return _accessToken;
  }

  // --- Sign Out ---

  Future<void> signOut() async {
    _accessToken  = null;
    _refreshToken = null;
    _userInfo     = null;
    _errorMessage = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  // --- Helpers ---

  Future<void> _persist() async {
    if (_accessToken != null) {
      await _storage.write(key: 'access_token', value: _accessToken);
    }
    if (_refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: _refreshToken);
    }
    if (_userInfo != null) {
      await _storage.write(key: 'user_info', value: jsonEncode(_userInfo));
    }
  }

  Map<String, dynamic> _decodeJwtPayload(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return {};

    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  @override
  void dispose() {
    // Nothing to clean up — storage handles its own lifecycle
    super.dispose();
  }
}
