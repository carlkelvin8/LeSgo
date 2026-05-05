import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Secure storage service using Flutter Secure Storage
/// Provides encrypted storage for sensitive data like tokens
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );

  // Keys
  static const String _tokenKey = 'auth_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _deviceIdKey = 'device_id';
  static const String _integrityKey = 'integrity_hash';

  /// Save authentication token with expiration
  static Future<void> saveToken({
    required String token,
    required DateTime expiresAt,
    String? refreshToken,
    int? userId,
  }) async {
    try {
      // Save token
      await _storage.write(key: _tokenKey, value: token);
      
      // Save expiry timestamp
      await _storage.write(
        key: _tokenExpiryKey,
        value: expiresAt.millisecondsSinceEpoch.toString(),
      );
      
      // Save refresh token if provided
      if (refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }
      
      // Save user ID if provided
      if (userId != null) {
        await _storage.write(key: _userIdKey, value: userId.toString());
      }
      
      // Generate and save integrity hash
      final hash = _generateIntegrityHash(token, expiresAt);
      await _storage.write(key: _integrityKey, value: hash);
      
      print('🔐 SecureStorage: Token saved securely with expiry');
    } catch (e) {
      print('❌ SecureStorage: Error saving token: $e');
      rethrow;
    }
  }

  /// Get authentication token if valid
  static Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        print('🔐 SecureStorage: No token found');
        return null;
      }

      // Check if token is expired
      if (await isTokenExpired()) {
        print('⏰ SecureStorage: Token expired');
        await clearAll();
        return null;
      }

      // Verify integrity
      if (!await _verifyIntegrity(token)) {
        print('⚠️ SecureStorage: Token integrity check failed');
        await clearAll();
        return null;
      }

      return token;
    } catch (e) {
      print('❌ SecureStorage: Error getting token: $e');
      return null;
    }
  }

  /// Check if token is expired
  static Future<bool> isTokenExpired() async {
    try {
      final expiryStr = await _storage.read(key: _tokenExpiryKey);
      if (expiryStr == null) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        int.parse(expiryStr),
      );

      // Add 5 minute buffer before actual expiry
      final bufferExpiry = expiry.subtract(const Duration(minutes: 5));
      final isExpired = DateTime.now().isAfter(bufferExpiry);

      if (isExpired) {
        print('⏰ SecureStorage: Token expired at $expiry');
      }

      return isExpired;
    } catch (e) {
      print('❌ SecureStorage: Error checking expiry: $e');
      return true;
    }
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      print('❌ SecureStorage: Error getting refresh token: $e');
      return null;
    }
  }

  /// Get user ID
  static Future<int?> getUserId() async {
    try {
      final userIdStr = await _storage.read(key: _userIdKey);
      return userIdStr != null ? int.tryParse(userIdStr) : null;
    } catch (e) {
      print('❌ SecureStorage: Error getting user ID: $e');
      return null;
    }
  }

  /// Get or generate device ID
  static Future<String> getDeviceId() async {
    try {
      var deviceId = await _storage.read(key: _deviceIdKey);
      
      if (deviceId == null) {
        // Generate new device ID
        deviceId = _generateDeviceId();
        await _storage.write(key: _deviceIdKey, value: deviceId);
        print('🔐 SecureStorage: Generated new device ID');
      }
      
      return deviceId;
    } catch (e) {
      print('❌ SecureStorage: Error with device ID: $e');
      return _generateDeviceId();
    }
  }

  /// Clear all stored data
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      print('🔐 SecureStorage: All data cleared');
    } catch (e) {
      print('❌ SecureStorage: Error clearing data: $e');
    }
  }

  /// Clear only auth data (keep device ID)
  static Future<void> clearAuth() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _tokenExpiryKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _integrityKey);
      print('🔐 SecureStorage: Auth data cleared');
    } catch (e) {
      print('❌ SecureStorage: Error clearing auth: $e');
    }
  }

  /// Generate integrity hash for token
  static String _generateIntegrityHash(String token, DateTime expiry) {
    final data = '$token:${expiry.millisecondsSinceEpoch}';
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verify token integrity
  static Future<bool> _verifyIntegrity(String token) async {
    try {
      final storedHash = await _storage.read(key: _integrityKey);
      if (storedHash == null) return false;

      final expiryStr = await _storage.read(key: _tokenExpiryKey);
      if (expiryStr == null) return false;

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        int.parse(expiryStr),
      );

      final expectedHash = _generateIntegrityHash(token, expiry);
      return storedHash == expectedHash;
    } catch (e) {
      print('❌ SecureStorage: Error verifying integrity: $e');
      return false;
    }
  }

  /// Generate unique device ID
  static String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    final data = '$timestamp:$random';
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Check if storage is available
  static Future<bool> isAvailable() async {
    try {
      await _storage.write(key: 'test', value: 'test');
      await _storage.delete(key: 'test');
      return true;
    } catch (e) {
      print('❌ SecureStorage: Not available: $e');
      return false;
    }
  }
}

