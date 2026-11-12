import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/routers/app_router.dart';
import '../constants/routers/main/main_routes.dart';
import '../di/injection.dart';
import '../network/dio_client.dart';
import '../services/apple_auth_service.dart';
import '../utils/google_auth_helper.dart' show GoogleAuthMode;
import '../utils/snackbar_utils.dart';
import '../../presentation/provider/auth/auth_provider.dart';
import '../../presentation/screens/main/documents/identity_onboarding_screen.dart';
import '../../presentation/widgets/auth/two_factor_code_dialog.dart';

/// Shared Sign in with Apple handler for login and registration flows.
/// Follows the same post-login behavior as [GoogleAuthHelper].
class AppleAuthHelper {
  AppleAuthHelper._();

  /// Asks which provider to re-verify with for destructive account actions.
  /// Returns true for Apple, false for Google, null if dismissed.
  static Future<bool?> promptProvider(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Verify your identity'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue with Apple'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue with Google'),
          ),
        ],
      ),
    );
  }

  static Future<void> signIn(
    BuildContext context,
    WidgetRef ref, {
    required GoogleAuthMode mode,
  }) async {
    try {
      final isSignup = mode == GoogleAuthMode.signup;

      var result = await AppleAuthService.signIn(
        getIt<DioClient>(),
        authMode: mode.name,
      );

      if (!context.mounted) return;

      if (result.twoFactorRequired && result.idToken != null) {
        final code = await showTwoFactorCodeDialog(context);
        if (code == null || !context.mounted) return;

        result = await AppleAuthService.completeTwoFactor(
          getIt<DioClient>(),
          idToken: result.idToken!,
          code: code,
          authMode: mode.name,
        );

        if (!context.mounted) return;
      }

      if (result.success && result.token != null) {
        final ok = await ref
            .read(authProvider.notifier)
            .completeGoogleSignIn(
              token: result.token!,
              refreshToken: result.refreshToken,
            );

        if (!context.mounted) return;

        if (ok) {
          SnackBarUtils.showSuccess(
            context,
            isSignup && result.requiresIdentityVerification
                ? 'Apple account connected. Complete identity verification.'
                : (result.isNewUser
                      ? 'Welcome! Account created.'
                      : 'Welcome back!'),
          );
          if (isSignup && result.requiresIdentityVerification) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) => const IdentityOnboardingScreen(),
              ),
              (_) => false,
            );
          } else {
            AppRouter.pushReplacement(context, MainRoutes.home);
          }
        } else {
          SnackBarUtils.showError(
            context,
            'Signed in with Apple but could not load your profile. Please try again.',
          );
        }
      } else {
        final error = result.error ?? 'Sign in with Apple failed';
        if (error != 'Sign-in cancelled') {
          SnackBarUtils.showError(context, error);
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, 'Sign in with Apple error: $e');
      }
    }
  }
}
