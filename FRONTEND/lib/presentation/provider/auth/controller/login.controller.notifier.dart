import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/domain/entities/auth/login/login_request.dart';
import 'package:lesgo/core/utils/snackbar_utils.dart';
import 'package:lesgo/core/services/google_auth_service.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/network/dio_client.dart';
import 'package:lesgo/core/di/local_storage_service.dart';
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

  Future<void> loadCredentials(WidgetRef ref) async {
    final localStorage = getIt<LocalStorageService>();
    if (!localStorage.isRememberMeEnabled()) return;

    final credentials = localStorage.getSavedCredentials();
    if (credentials != null) {
      emailController.text = credentials['email']!;
      passwordController.text = credentials['password']!;
      Future.microtask(() {
        ref.read(authProvider.notifier).toggleRememberMe(true);
      });
    }
  }

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
      await getIt<LocalStorageService>().saveRememberMePreference(
        enabled: authState.rememberMe,
        email: loginRequest.email,
        password: loginRequest.password,
      );

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
        final localStorage = getIt<LocalStorageService>();
        await localStorage.saveToken(result.token!);
        if (result.refreshToken != null && result.refreshToken!.isNotEmpty) {
          await localStorage.saveRefreshToken(result.refreshToken!);
        }

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
