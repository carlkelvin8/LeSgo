import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for secure storage of sensitive data
/// In production, use flutter_secure_storage for encryption
@lazySingleton
class SecureStorageService {
  final SharedPreferences _prefs;

  SecureStorageService(this._prefs);

  // Keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyLastActivity = 'last_activity';

  static const String _keyBiometricEnabled = 'biometric_enabled';

  /// Save auth token
  Future<bool> saveAuthToken(String token) async {
    debugPrint('🔐 Saving auth token...');
    final result = await _prefs.setString(_keyAuthToken, token);
    if (result) {
      await _updateLastActivity();
    }
    return result;
  }

  /// Get auth token
  String? getAuthToken() {
    return _prefs.getString(_keyAuthToken);
  }

  /// Save refresh token
  Future<bool> saveRefreshToken(String token) async {
    debugPrint('🔐 Saving refresh token...');
    return await _prefs.setString(_keyRefreshToken, token);
  }

  /// Get refresh token
  String? getRefreshToken() {
    return _prefs.getString(_keyRefreshToken);
  }

  /// Save user ID
  Future<bool> saveUserId(int userId) async {
    return await _prefs.setInt(_keyUserId, userId);
  }

  /// Get user ID
  int? getUserId() {
    return _prefs.getInt(_keyUserId);
  }

  /// Save user email
  Future<bool> saveUserEmail(String email) async {
    return await _prefs.setString(_keyUserEmail, email);
  }

  /// Get user email
  String? getUserEmail() {
    return _prefs.getString(_keyUserEmail);
  }

  /// Update last activity timestamp
  Future<bool> _updateLastActivity() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return await _prefs.setInt(_keyLastActivity, timestamp);
  }

  /// Get last activity timestamp
  DateTime? getLastActivity() {
    final timestamp = _prefs.getInt(_keyLastActivity);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Check if session is expired
  bool isSessionExpired({int timeoutMinutes = 30}) {
    final lastActivity = getLastActivity();
    if (lastActivity == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastActivity);
    
    return difference.inMinutes > timeoutMinutes;
  }

  /// Update session activity
  Future<void> updateSessionActivity() async {
    await _updateLastActivity();
  }

  /// Update session activity synchronously (best-effort, for use in initState)
  /// SharedPreferences caches in memory, so setInt is effectively instant.
  void updateSessionActivitySync() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _prefs.setInt(_keyLastActivity, timestamp);
  }

  /// Enable biometric authentication
  Future<bool> enableBiometric() async {
    return await _prefs.setBool(_keyBiometricEnabled, true);
  }

  /// Disable biometric authentication
  Future<bool> disableBiometric() async {
    return await _prefs.setBool(_keyBiometricEnabled, false);
  }

  /// Check if biometric is enabled
  bool isBiometricEnabled() {
    return _prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  /// Clear all auth data (logout)
  Future<bool> clearAuthData() async {
    debugPrint('🗑️ Clearing auth data...');
    
    final results = await Future.wait([
      _prefs.remove(_keyAuthToken),
      _prefs.remove(_keyRefreshToken),
      _prefs.remove(_keyUserId),
      _prefs.remove(_keyUserEmail),
      _prefs.remove(_keyLastActivity),
    ]);
    
    return results.every((result) => result);
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    final token = getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Save custom secure data
  Future<bool> saveSecureData(String key, String value) async {
    // In production, encrypt the value before saving
    return await _prefs.setString('secure_$key', value);
  }

  /// Get custom secure data
  String? getSecureData(String key) {
    // In production, decrypt the value after retrieving
    return _prefs.getString('secure_$key');
  }

  /// Remove custom secure data
  Future<bool> removeSecureData(String key) async {
    return await _prefs.remove('secure_$key');
  }

  /// Save object as JSON
  Future<bool> saveObject(String key, Map<String, dynamic> object) async {
    final jsonString = jsonEncode(object);
    return await _prefs.setString(key, jsonString);
  }

  /// Get object from JSON
  Map<String, dynamic>? getObject(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error decoding JSON: $e');
      return null;
    }
  }

  /// Clear all data
  Future<bool> clearAll() async {
    debugPrint('🗑️ Clearing all storage...');
    return await _prefs.clear();
  }
}
