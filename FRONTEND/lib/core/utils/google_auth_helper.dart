import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/routers/app_router.dart';
import '../constants/routers/main/main_routes.dart';
import '../di/injection.dart';
import '../network/dio_client.dart';
import '../services/google_auth_service.dart';
import '../utils/snackbar_utils.dart';
import '../../presentation/provider/auth/auth_provider.dart';
import '../../presentation/screens/main/documents/identity_onboarding_screen.dart';
import '../../presentation/widgets/auth/two_factor_code_dialog.dart';

enum GoogleAuthMode { login, signup }

/// Shared Google sign-in / sign-up handler for login and registration flows.
class GoogleAuthHelper {
  GoogleAuthHelper._();

  static Future<void> signIn(
    BuildContext context,
    WidgetRef ref, {
    required GoogleAuthMode mode,
  }) async {
    try {
      final isSignup = mode == GoogleAuthMode.signup;
      SnackBarUtils.showInfo(
        context,
        isSignup ? 'Signing up with Google...' : 'Signing in with Google...',
      );

      var result = await GoogleAuthService.signIn(
        getIt<DioClient>(),
        authMode: mode.name,
      );

      if (!context.mounted) return;

      if (result.twoFactorRequired && result.idToken != null) {
        final code = await showTwoFactorCodeDialog(context);
        if (code == null || !context.mounted) return;

        result = await GoogleAuthService.completeTwoFactor(
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
                ? 'Google account connected. Complete identity verification.'
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
            'Signed in with Google but could not load your profile. Please try again.',
          );
        }
      } else {
        final error = result.error ?? 'Google sign-in failed';
        if (error != 'Sign-in cancelled') {
          SnackBarUtils.showError(context, error);
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, 'Google sign-in error: $e');
      }
    }
  }
}
