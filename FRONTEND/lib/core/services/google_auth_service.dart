import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../constants/api_constants.dart';

class GoogleAuthResult {
  final bool success;
  final String? token;
  final Map<String, dynamic>? user;
  final String? error;
  final bool isNewUser;

  GoogleAuthResult({
    required this.success,
    this.token,
    this.user,
    this.error,
    this.isNewUser = false,
  });
}

class GoogleAuthService {
  // Use your actual Google Client ID from Google Cloud Console
  // For Android: the Web Client ID (not Android client ID)
  static const _webClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // On Android/iOS, use the Web Client ID for server-side verification
    serverClientId: kIsWeb ? null : _webClientId,
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google and authenticate with your backend.
  static Future<GoogleAuthResult> signIn(DioClient dioClient) async {
    try {
      // Trigger the Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

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

      if (data['success'] == true) {
        return GoogleAuthResult(
          success: true,
          token: data['token'],
          user: data['user'],
          isNewUser: data['is_new_user'] ?? false,
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
      return GoogleAuthResult(success: false, error: e.toString());
    }
  }

  /// Sign out from Google (clears the Google session).
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
