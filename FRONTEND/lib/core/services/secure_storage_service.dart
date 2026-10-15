import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Platform-backed persistence with an in-memory cache for synchronous routing.
/// Initialization completes before the app exposes authenticated routes.
@lazySingleton
class SecureStorageService {
  static final _instances = Expando<SecureStorageService>();
  factory SecureStorageService(SharedPreferences prefs) =>
      _instances[prefs] ??= SecureStorageService._(prefs);
  SecureStorageService._(this._legacy);

  final SharedPreferences _legacy;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  final Map<String, String> _cache = {};
  bool _ready = false;
  static const _prefix = 'lesgo_secure_';
  static const _authKeys = [
    'auth_token', 'refresh_token', 'saved_email', 'remember_me_enabled',
    'remember_me_expires_at', 'pref_biometric_unlock', 'biometric_enabled',
    'user_id', 'user_email', 'last_activity',
  ];
  // Device biometric unlock is a setting, not a session credential.
  // Clearing a token (401, failed restore, timeout) must not turn it off.
  static const _sessionKeys = [
    'auth_token', 'refresh_token', 'saved_email', 'remember_me_enabled',
    'remember_me_expires_at', 'user_id', 'user_email', 'last_activity',
  ];

  Future<void>? _initializing;
  Future<void> initialize() {
    if (_ready) return Future.value();
    return _initializing ??= _initialize().whenComplete(() => _initializing = null);
  }

  Future<void> _initialize() async {
    try {
      final values = await _storage.readAll();
      // An interrupted migration must never restore a token without its lock preference.
      if (values['${_prefix}migration'] == 'pending') {
        for (final key in _authKeys) {
          await _storage.delete(key: '$_prefix$key');
          await _legacy.remove(key);
        }
        values.removeWhere((key, _) => _authKeys.any((auth) => key == '$_prefix$auth'));
      }
      await _storage.write(key: '${_prefix}migration', value: 'pending');
      for (final entry in values.entries) {
        if (entry.key.startsWith(_prefix)) {
          _cache[entry.key.substring(_prefix.length)] = entry.value;
        }
      }
      for (final key in _authKeys) {
        final value = _legacy.get(key);
        if (!_cache.containsKey(key) && value != null) {
          await _storage.write(key: '$_prefix$key', value: value.toString());
          _cache[key] = value.toString();
        }
      }
      await _storage.write(key: '${_prefix}migration', value: 'complete');
      _ready = true;
    } catch (_) {
      // Keystore/Keychain unavailable: no plaintext fallback or restored session.
      _cache.clear();
    } finally {
      // Passwords are deliberately discarded, never migrated or remembered.
      for (final key in [..._authKeys, 'saved_password']) {
        await _legacy.remove(key);
      }
    }
  }

  String? getString(String key) => _ready ? _cache[key] : null;
  bool? getBool(String key) => getString(key) == null ? null : getString(key) == 'true';
  int? getInt(String key) => int.tryParse(getString(key) ?? '');

  Future<bool> setString(String key, String value) async {
    if (!_ready) await initialize();
    if (!_ready) throw StateError('Secure storage unavailable. Unlock your device and try again.');
    await _storage.write(key: '$_prefix$key', value: value);
    _cache[key] = value;
    return true;
  }
  Future<bool> setBool(String key, bool value) => setString(key, value.toString());
  Future<bool> setInt(String key, int value) => setString(key, value.toString());
  Future<bool> remove(String key) async {
    _cache.remove(key);
    await _legacy.remove(key);
    await _storage.delete(key: '$_prefix$key');
    return true;
  }

  Future<bool> saveAuthToken(String token) => setString('auth_token', token);
  String? getAuthToken() => getString('auth_token');
  Future<bool> saveRefreshToken(String token) => setString('refresh_token', token);
  String? getRefreshToken() => getString('refresh_token');
  Future<bool> saveUserId(int id) => setInt('user_id', id);
  int? getUserId() => getInt('user_id');
  Future<bool> saveUserEmail(String email) => setString('user_email', email);
  String? getUserEmail() => getString('user_email');
  DateTime? getLastActivity() {
    final value = getInt('last_activity');
    return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);
  }
  bool isSessionExpired({int timeoutMinutes = 30}) => getLastActivity() == null ||
      DateTime.now().difference(getLastActivity()!).inMinutes > timeoutMinutes;
  Future<void> updateSessionActivity() async {
    await setInt('last_activity', DateTime.now().millisecondsSinceEpoch);
  }
  void updateSessionActivitySync() {
    updateSessionActivity().catchError((Object _) {});
  }
  Future<bool> enableBiometric() => setBool('pref_biometric_unlock', true);
  Future<bool> disableBiometric() => setBool('pref_biometric_unlock', false);
  bool isBiometricEnabled() => getBool('pref_biometric_unlock') ?? false;
  bool isLoggedIn() => (getAuthToken() ?? '').isNotEmpty;

  /// Clears the session only; keeps biometric unlock enabled.
  Future<bool> clearAuthData() async {
    for (final key in _sessionKeys) {
      await remove(key);
    }
    return true;
  }

  /// Explicit logout / “Sign in again”: session plus biometric unlock.
  Future<bool> clearAuthDataAndBiometric() async {
    for (final key in [..._authKeys, 'saved_password']) {
      await remove(key);
    }
    return true;
  }
  Future<bool> saveSecureData(String key, String value) => setString('secure_$key', value);
  String? getSecureData(String key) => getString('secure_$key');
  Future<bool> removeSecureData(String key) => remove('secure_$key');
  Future<bool> saveObject(String key, Map<String, dynamic> value) => setString(key, jsonEncode(value));
  Map<String, dynamic>? getObject(String key) {
    final value = getString(key);
    if (value == null) return null;
    try { return jsonDecode(value) as Map<String, dynamic>; } catch (_) { return null; }
  }
  Future<bool> clearAll() async {
    final keys = _cache.keys.toList();
    for (final key in keys) { await remove(key); }
    return clearAuthData();
  }
}
