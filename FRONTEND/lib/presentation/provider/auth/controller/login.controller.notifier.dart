import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/domain/entities/auth/login/login_request.dart';
import 'package:lesgo/core/utils/snackbar_utils.dart';
import 'package:lesgo/core/services/google_auth_service.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth_provider.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/constants/routers/app_router.dart';

class LoginControllers {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  bool obscurePassword = true;

  LoginControllers()
    : formKey = GlobalKey<FormState>(),
      emailController = TextEditingController(),
      passwordController = TextEditingController();

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
  }

  Future<bool> handleLogin(BuildContext context, WidgetRef ref) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    final loginRequest = LoginRequest(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    await ref.read(authProvider.notifier).login(loginRequest);

    final authState = ref.read(authProvider);

    if (!context.mounted) return false;

    if (authState.isAuthenticated) {
      SnackBarUtils.showSuccess(
        context,
        authState.successMessage ?? 'Login successful!',
      );
      return true;
    } else if (authState.error != null) {
      SnackBarUtils.showError(context, authState.error!);
      ref.read(authProvider.notifier).clearMessages();
      return false;
    }

    return false;
  }

  Future<void> handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading
      SnackBarUtils.showInfo(context, 'Signing in with Google...');

      final dioClient = getIt<DioClient>();
      final result = await GoogleAuthService.signIn(dioClient);

      if (!context.mounted) return;

      if (result.success && result.token != null) {
        // Save the token to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', result.token!);

        if (!context.mounted) return;

        SnackBarUtils.showSuccess(
          context,
          result.isNewUser ? 'Welcome! Account created.' : 'Welcome back!',
        );

        // Navigate to home
        AppRouter.pushReplacement(context, MainRoutes.home);
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

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
