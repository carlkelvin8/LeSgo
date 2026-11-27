import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../constants/api_constants.dart';
import '../network/dio_client.dart';
import 'google_auth_service.dart' show GoogleAuthResult;

/// Apple credential used to re-verify a destructive account action.
class AppleSensitiveCredential {
  final String idToken;
  final String nonce;
  final String? authorizationCode;

  const AppleSensitiveCredential({
    required this.idToken,
    required this.nonce,
    this.authorizationCode,
  });
}

/// Sign in with Apple. Mirrors [GoogleAuthService] and reuses its result type
/// so both providers share the same post-login flow.
class AppleAuthService {
  AppleAuthService._();

  // Kept so a two-factor retry can re-submit the same verified credential.
  static String? _pendingNonce;
  static String? _pendingFullName;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static String _newNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  static Future<AuthorizationCredentialAppleID> _requestCredential(
    String rawNonce,
  ) {
    return SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: _sha256(rawNonce),
    );
  }

  static Future<GoogleAuthResult> signIn(
    DioClient dioClient, {
    required String authMode,
  }) async {
    if (!isSupported) {
      return GoogleAuthResult(
        success: false,
        error: 'Sign in with Apple is not available on this device.',
      );
    }

    final rawNonce = _newNonce();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await _requestCredential(rawNonce);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return GoogleAuthResult(success: false, error: 'Sign-in cancelled');
      }
      return GoogleAuthResult(
        success: false,
        error: 'Sign in with Apple failed. Please try again.',
      );
    } catch (e) {
      debugPrint('Sign in with Apple error: $e');
      return GoogleAuthResult(
        success: false,
        error: 'Sign in with Apple is unavailable on this device.',
      );
    }

    final identityToken = credential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      return GoogleAuthResult(
        success: false,
        error: 'Failed to get Apple identity token',
      );
    }

    final fullName = [credential.givenName, credential.familyName]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' ');

    _pendingNonce = rawNonce;
    _pendingFullName = fullName.isEmpty ? null : fullName;

    return _authenticateWithBackend(
      dioClient,
      identityToken,
      nonce: rawNonce,
      fullName: _pendingFullName,
      authMode: authMode,
    );
  }

  static Future<GoogleAuthResult> completeTwoFactor(
    DioClient dioClient, {
    required String idToken,
    required String code,
    required String authMode,
  }) {
    return _authenticateWithBackend(
      dioClient,
      idToken,
      nonce: _pendingNonce,
      fullName: _pendingFullName,
      twoFactorCode: code,
      authMode: authMode,
    );
  }

  /// Fresh Apple credential for a destructive action such as account deletion.
  static Future<AppleSensitiveCredential?> getCredentialForSensitiveAction() async {
    if (!isSupported) {
      throw StateError('Sign in with Apple is not available on this device.');
    }

    final rawNonce = _newNonce();
    try {
      final credential = await _requestCredential(rawNonce);
      final token = credential.identityToken;
      if (token == null || token.isEmpty) return null;
      return AppleSensitiveCredential(
        idToken: token,
        nonce: rawNonce,
        authorizationCode: credential.authorizationCode,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }

  static Future<GoogleAuthResult> _authenticateWithBackend(
    DioClient dioClient,
    String idToken, {
    required String authMode,
    String? nonce,
    String? fullName,
    String? twoFactorCode,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.appleSignIn,
        data: {
          'id_token': idToken,
          'device_name': 'mobile-app',
          'auth_mode': authMode,
          if (nonce != null) 'nonce': nonce,
          if (fullName != null) 'full_name': fullName,
          if (twoFactorCode != null) 'two_factor_code': twoFactorCode,
        },
      );
      return _resultFromResponse(response.data, idToken: idToken);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        return _resultFromResponse(data, idToken: idToken);
      }
      return GoogleAuthResult(
        success: false,
        error: e.message ?? 'Network error',
      );
    }
  }

  static GoogleAuthResult _resultFromResponse(
    dynamic data, {
    required String idToken,
  }) {
    if (data is! Map) {
      return GoogleAuthResult(
        success: false,
        error: 'Unexpected response format from server',
      );
    }

    final map = Map<String, dynamic>.from(data);

    if (map['two_factor_required'] == true) {
      return GoogleAuthResult(
        success: false,
        error: map['message']?.toString(),
        twoFactorRequired: true,
        idToken: idToken,
      );
    }

    if (map['success'] == true || map['token'] != null) {
      return GoogleAuthResult(
        success: true,
        token: map['token']?.toString(),
        refreshToken: map['refresh_token']?.toString(),
        user: map['user'] is Map
            ? Map<String, dynamic>.from(map['user'] as Map)
            : null,
        isNewUser: map['is_new_user'] == true,
        requiresIdentityVerification:
            map['requires_identity_verification'] == true,
      );
    }

    return GoogleAuthResult(
      success: false,
      error: (map['message'] ?? 'Sign in with Apple failed').toString(),
    );
  }
}
