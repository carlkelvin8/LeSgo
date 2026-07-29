import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/auth/auth_routes.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/remember_me_service.dart';
import '../../provider/auth/auth_provider.dart';
import '../../provider/auth/rider_auth_provider.dart';

/// Restores a remembered rider/merchant session or opens the auth screen.
class AuthStartupScreen extends ConsumerStatefulWidget {
  const AuthStartupScreen({super.key});

  @override
  ConsumerState<AuthStartupScreen> createState() => _AuthStartupScreenState();
}

class _AuthStartupScreenState extends ConsumerState<AuthStartupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (RememberMeService.isSessionValid()) {
      final restored =
          await ref.read(riderAuthProvider.notifier).restoreSession();
      if (!mounted) return;

      if (restored) {
        final user = ref.read(riderAuthProvider).user;
        final route = user != null && user.isMerchant
            ? MainRoutes.merchantMain
            : MainRoutes.riderMain;
        AppRouter.pushReplacement(context, route);
        return;
      }

      // Don't clear refresh token — only clear the expired access token
      // so next launch can still try the refresh token
      _openLoginForRememberedAccount();
    } else {
      await ApiService.clearToken();
    }

    if (!mounted) return;
    AppRouter.pushReplacement(context, AuthRoutes.auth);
  }

  void _openLoginForRememberedAccount() {
    if (!RememberMeService.isEnabled()) return;

    final accountType = RememberMeService.savedAccountType;
    if (accountType == 'merchant') {
      ref.read(authViewProvider.notifier).state = AuthView.merchantLogin;
    } else if (accountType == 'rider') {
      ref.read(authViewProvider.notifier).state = AuthView.riderLogin;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
      ),
    );
  }
}
