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

  Future<void> saveCredentials(String email, String password) async {
    await prefs.setString(savedEmailKey, email);
    await prefs.setString(savedPasswordKey, password);
  }

  Map<String, String>? getSavedCredentials() {
    final email = prefs.getString(savedEmailKey);
    final password = prefs.getString(savedPasswordKey);
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  Future<void> clearCredentials() async {
    await prefs.remove(savedEmailKey);
    await prefs.remove(savedPasswordKey);
  }

  bool isRememberMeEnabled() => prefs.getBool(rememberMeKey) ?? false;

  bool isRememberMeSessionValid() {
    if (!isRememberMeEnabled()) return false;

    final token = prefs.getString(authTokenKey);
    if (token == null || token.isEmpty) return false;

    final expiresAt = prefs.getInt(rememberMeExpiresKey);
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

    await prefs.setBool(rememberMeKey, true);
    await saveCredentials(email, password);
    await prefs.setInt(
      rememberMeExpiresKey,
      DateTime.now().add(rememberMeDuration).millisecondsSinceEpoch,
    );
  }

  Future<void> refreshRememberMeExpiry() async {
    if (!isRememberMeEnabled()) return;

    await prefs.setInt(
      rememberMeExpiresKey,
      DateTime.now().add(rememberMeDuration).millisecondsSinceEpoch,
    );
  }

  Future<void> clearRememberMePreference() async {
    await prefs.remove(rememberMeKey);
    await prefs.remove(rememberMeExpiresKey);
    await clearCredentials();
  }

  Future<void> clearRememberMeSession() async {
    await clearRememberMePreference();
    await clearToken();
  }

  Future<void> saveToken(String token) async {
    await prefs.setString(authTokenKey, token);
    _tokenController.add(token);
  }

  Future<void> saveRefreshToken(String token) async {
    await prefs.setString(refreshTokenKey, token);
  }

  String? get refreshToken => prefs.getString(refreshTokenKey);

  String? get token {
    final token = prefs.getString(authTokenKey);
    return token;
  }

  Stream<String?> get tokenStream async* {
    yield token;
    yield* _tokenController.stream;
  }

  Future<void> clearToken() async {
    await prefs.remove(authTokenKey);
    await prefs.remove(refreshTokenKey);

    _tokenController.add(null);
  }

  void dispose() {
    _tokenController.close();
  }
}
