import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../config/mobile_config_service.dart';
import '../config/secrets_config.dart';
import '../network/dio_client.dart';
import '../constants/api_constants.dart';

class GoogleAuthResult {
  final bool success;
  final String? token;
  final String? refreshToken;
  final Map<String, dynamic>? user;
  final String? error;
  final bool isNewUser;
  final bool twoFactorRequired;
  final String? idToken;

  GoogleAuthResult({
    required this.success,
    this.token,
    this.refreshToken,
    this.user,
    this.error,
    this.isNewUser = false,
    this.twoFactorRequired = false,
    this.idToken,
  });
}

class GoogleAuthService {
  // Use SecretsConfig directly (baked in at build time via --dart-define-from-file)
  // as the primary source, falling back to MobileConfigService (remote config)
  static String get _webClientId {
    const fromSecrets = SecretsConfig.googleWebClientId;
    if (fromSecrets.isNotEmpty &&
        fromSecrets.contains('.apps.googleusercontent.com')) {
      return fromSecrets;
    }
    return MobileConfigService.instance.googleWebClientId;
  }

  static bool get _isConfigured {
    final id = _webClientId;
    return id.isNotEmpty &&
        !id.startsWith('YOUR_') &&
        !id.startsWith('your-') &&
        id.contains('.apps.googleusercontent.com');
  }

  static GoogleSignIn get _googleSignIn => GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    serverClientId: kIsWeb ? null : _webClientId,
    scopes: const ['email', 'profile'],
  );

  /// Sign in with Google and authenticate with your backend.
  static Future<GoogleAuthResult> signIn(DioClient dioClient) async {
    if (!_isConfigured) {
      return GoogleAuthResult(
        success: false,
        error:
            'Google Sign-In is not configured. Set GOOGLE_WEB_CLIENT_ID in secrets.json.',
      );
    }

    try {
      // Trigger the Google sign-in flow
      final GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } catch (e) {
        // Google Sign-In plugin can throw errors when:
        // - SHA-1 fingerprint mismatch (most common)
        // - Google Play Services outdated
        // - Network issue during auth
        debugPrint('GoogleSignIn.signIn() error: $e');

        final errorStr = e.toString().toLowerCase();
        String userMessage;
        if (errorStr.contains('apiexception: 10') ||
            errorStr.contains('developer_error')) {
          userMessage =
              'Google Sign-In configuration error. Please contact support (SHA-1 mismatch).';
        } else if (errorStr.contains('apiexception: 12500')) {
          userMessage =
              'Google Sign-In failed. Please update Google Play Services.';
        } else if (errorStr.contains('network')) {
          userMessage =
              'Network error during Google Sign-In. Please check your connection.';
        } else {
          userMessage =
              'Google Sign-In unavailable on this device. Please use email/password login.';
        }

        return GoogleAuthResult(success: false, error: userMessage);
      }

      if (googleUser == null) {
        // User cancelled the sign-in
        return GoogleAuthResult(success: false, error: 'Sign-in cancelled');
      }

      // Get the auth details (includes idToken)
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final idToken = googleAuth.idToken;

      if (idToken == null) {
        return GoogleAuthResult(
          success: false,
          error: 'Failed to get Google ID token',
        );
      }

      return _authenticateWithBackend(dioClient, idToken);
    } catch (e) {
      return GoogleAuthResult(
        success: false,
        error: 'Google sign-in error: ${e.runtimeType}: $e',
      );
    }
  }

  /// Complete a Google sign-in after the account requests a TOTP challenge.
  static Future<GoogleAuthResult> completeTwoFactor(
    DioClient dioClient, {
    required String idToken,
    required String code,
  }) {
    return _authenticateWithBackend(dioClient, idToken, twoFactorCode: code);
  }

  /// Gets a fresh Google credential for a destructive account action.
  /// The explicit sign-out prevents a stale in-memory account from silently
  /// authorizing the action without user interaction.
  static Future<String?> getIdTokenForSensitiveAction() async {
    if (!_isConfigured) {
      throw StateError('Google Sign-In is not configured.');
    }

    await _googleSignIn.signOut();
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final authentication = await account.authentication;
    return authentication.idToken;
  }

  static Future<GoogleAuthResult> _authenticateWithBackend(
    DioClient dioClient,
    String idToken, {
    String? twoFactorCode,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.googleSignIn,
        data: {
          'id_token': idToken,
          'device_name': 'mobile-app',
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

    final dataMap = Map<String, dynamic>.from(data);
    final payload = dataMap['data'] is Map
        ? Map<String, dynamic>.from(dataMap['data'] as Map)
        : dataMap;
    final twoFactorRequired =
        dataMap['two_factor_required'] == true ||
        payload['two_factor_required'] == true;

    if (twoFactorRequired) {
      return GoogleAuthResult(
        success: false,
        error: (dataMap['message'] ?? payload['message'])?.toString(),
        twoFactorRequired: true,
        idToken: idToken,
      );
    }

    final success = dataMap['success'] == true || payload['token'] != null;
    if (success) {
      return GoogleAuthResult(
        success: true,
        token: (payload['token'] ?? dataMap['token'])?.toString(),
        refreshToken: (payload['refresh_token'] ?? dataMap['refresh_token'])
            ?.toString(),
        user: payload['user'] is Map
            ? Map<String, dynamic>.from(payload['user'] as Map)
            : null,
        isNewUser:
            dataMap['is_new_user'] == true || payload['is_new_user'] == true,
      );
    }

    return GoogleAuthResult(
      success: false,
      error:
          (dataMap['message'] ?? payload['message'] ?? 'Google sign-in failed')
              .toString(),
    );
  }

  /// Sign out from Google (clears the Google session).
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
