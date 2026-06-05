import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/routers/auth/auth_routes.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/di/injection.dart';
import '../../../core/di/local_storage_service.dart';
import '../../provider/auth/auth_provider.dart';

/// Decides whether to restore a remembered session or show the login screen.
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
    final storage = getIt<LocalStorageService>();

    if (storage.isRememberMeSessionValid()) {
      final restored = await ref.read(authProvider.notifier).restoreSession();
      if (!mounted) return;

      if (restored) {
        Navigator.pushReplacementNamed(context, MainRoutes.home);
        return;
      }

      await storage.clearRememberMeSession();
    } else if ((storage.token ?? '').isNotEmpty) {
      await storage.clearToken();
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, LoginRoutes.login);
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
