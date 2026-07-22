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

  GoogleAuthResult({
    required this.success,
    this.token,
    this.refreshToken,
    this.user,
    this.error,
    this.isNewUser = false,
  });
}

class GoogleAuthService {
  // Use SecretsConfig directly (baked in at build time via --dart-define-from-file)
  // as the primary source, falling back to MobileConfigService (remote config)
  static String get _webClientId {
    final fromSecrets = SecretsConfig.googleWebClientId;
    if (fromSecrets.isNotEmpty && fromSecrets.contains('.apps.googleusercontent.com')) {
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
        if (errorStr.contains('apiexception: 10') || errorStr.contains('developer_error')) {
          userMessage = 'Google Sign-In configuration error. Please contact support (SHA-1 mismatch).';
        } else if (errorStr.contains('apiexception: 12500')) {
          userMessage = 'Google Sign-In failed. Please update Google Play Services.';
        } else if (errorStr.contains('network')) {
          userMessage = 'Network error during Google Sign-In. Please check your connection.';
        } else {
          userMessage = 'Google Sign-In unavailable on this device. Please use email/password login.';
        }
        
        return GoogleAuthResult(
          success: false,
          error: userMessage,
        );
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

      // Send the ID token to your backend
      final response = await dioClient.dio.post(
        ApiConstants.googleSignIn,
        data: {
          'id_token': idToken,
          'device_name': 'mobile-app',
        },
      );

      final data = response.data;
      
      // Safely extract payload - handle both {data: {...}} and direct {...} responses
      Map<String, dynamic> payload;
      if (data is Map) {
        final dataMap = Map<String, dynamic>.from(data);
        if (dataMap['data'] is Map) {
          payload = Map<String, dynamic>.from(dataMap['data'] as Map);
        } else {
          payload = dataMap;
        }
      } else {
        return GoogleAuthResult(
          success: false,
          error: 'Unexpected response format from server',
        );
      }

      final success = data['success'] == true || payload['token'] != null;
      if (success) {
        return GoogleAuthResult(
          success: true,
          token: (payload['token'] ?? data['token'])?.toString(),
          refreshToken: (payload['refresh_token'] ?? data['refresh_token'])?.toString(),
          user: payload['user'] is Map ? Map<String, dynamic>.from(payload['user'] as Map) : null,
          isNewUser: data['is_new_user'] == true || payload['is_new_user'] == true,
        );
      }

      return GoogleAuthResult(
        success: false,
        error: data['message'] ?? 'Google sign-in failed',
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Network error';
      return GoogleAuthResult(success: false, error: message);
    } catch (e) {
      return GoogleAuthResult(success: false, error: 'Google sign-in error: ${e.runtimeType}: $e');
    }
  }

  /// Sign out from Google (clears the Google session).
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
