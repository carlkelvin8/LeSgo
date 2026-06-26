import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/domain/entities/auth/login/login_request.dart';
import 'package:lesgo/core/utils/snackbar_utils.dart';
import 'package:lesgo/core/utils/google_auth_helper.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/di/local_storage_service.dart';
import '../auth_provider.dart';

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
    await GoogleAuthHelper.signIn(context, ref);
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
