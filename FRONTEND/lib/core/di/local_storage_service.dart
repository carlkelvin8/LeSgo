import '../services/secure_storage_service.dart';
import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class LocalStorageService {
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String savedEmailKey = 'saved_email';
  static const String savedPasswordKey = 'saved_password';
  static const String rememberMeKey = 'remember_me_enabled';
  static const String rememberMeExpiresKey = 'remember_me_expires_at';
  static const Duration rememberMeDuration = Duration(days: 30);

  final SharedPreferences prefs;
  final StreamController<String?> _tokenController =
      StreamController<String?>.broadcast();

  LocalStorageService(this.prefs);
  SecureStorageService get secure => SecureStorageService(prefs);

  Future<void> saveCredentials(String email, String password) async {
    await secure.setString(savedEmailKey, email);
    await secure.remove(savedPasswordKey);
  }

  Map<String, String>? getSavedCredentials() {
    final email = secure.getString(savedEmailKey);
    if (email != null) {
      return {'email': email, 'password': ''};
    }
    return null;
  }

  Future<void> clearCredentials() async {
    await secure.remove(savedEmailKey);
    await secure.remove(savedPasswordKey);
  }

  bool isRememberMeEnabled() => secure.getBool(rememberMeKey) ?? false;

  /// A saved auth token is enough to attempt session restoration.
  /// Remember-me controls credential convenience/session preference, while
  /// biometric unlock is enforced independently by the app's lock overlay.
  bool canRestoreSession() {
    return (token ?? '').isNotEmpty;
  }

  bool isRememberMeSessionValid() {
    if (!isRememberMeEnabled()) return false;

    final token = secure.getString(authTokenKey);
    if (token == null || token.isEmpty) return false;

    final expiresAt = secure.getInt(rememberMeExpiresKey);
    if (expiresAt == null) return false;

    return DateTime.now().millisecondsSinceEpoch < expiresAt;
  }

  Future<void> saveRememberMePreference({
    required bool enabled,
    required String email,
    required String password,
  }) async {
    if (!enabled) {
      await clearRememberMePreference();
      return;
    }

    await secure.setBool(rememberMeKey, true);
    await saveCredentials(email, password);
    await secure.setInt(
      rememberMeExpiresKey,
      DateTime.now().add(rememberMeDuration).millisecondsSinceEpoch,
    );
  }

  Future<void> refreshRememberMeExpiry() async {
    if (!isRememberMeEnabled()) return;

    await secure.setInt(
      rememberMeExpiresKey,
      DateTime.now().add(rememberMeDuration).millisecondsSinceEpoch,
    );
  }

  Future<void> clearRememberMePreference() async {
    await secure.remove(rememberMeKey);
    await secure.remove(rememberMeExpiresKey);
    await clearCredentials();
  }

  Future<void> clearRememberMeSession() async {
    await clearRememberMePreference();
    // Logout / sign-in-again: full reset including biometric unlock.
    await secure.clearAuthDataAndBiometric();
    _tokenController.add(null);
  }

  /// Drops the session but keeps biometric unlock for the next sign-in.
  Future<void> clearSessionKeepBiometric() async {
    await clearRememberMePreference();
    await secure.clearAuthData();
    _tokenController.add(null);
  }

  /// Logout / “Sign in again”: session plus biometric unlock.
  Future<void> clearSessionAndBiometric() async {
    await clearRememberMePreference();
    await secure.clearAuthDataAndBiometric();
    _tokenController.add(null);
  }

  Future<void> saveToken(String token) async {
    await secure.setString(authTokenKey, token);
    _tokenController.add(token);
  }

  Future<void> saveRefreshToken(String token) async {
    await secure.setString(refreshTokenKey, token);
  }

  String? get refreshToken => secure.getString(refreshTokenKey);

  String? get token {
    final token = secure.getString(authTokenKey);
    return token;
  }

  Stream<String?> get tokenStream async* {
    yield token;
    yield* _tokenController.stream;
  }

  Future<void> clearToken() async {
    await secure.clearAuthData();

    _tokenController.add(null);
  }

  Future<void> clearTokenAndBiometric() async {
    await secure.clearAuthDataAndBiometric();
    _tokenController.add(null);
  }

  void dispose() {
    _tokenController.close();
  }
}
