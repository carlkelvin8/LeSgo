import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/routers/auth/auth_routes.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/di/injection.dart';
import '../../../core/di/local_storage_service.dart';
import '../../provider/auth/auth_provider.dart';

/// Restores any saved session token, or shows login when no token exists.
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

    if ((storage.token ?? '').isNotEmpty) {
      final restored = await ref.read(authProvider.notifier).restoreSession();
      if (!mounted) return;

      if (restored) {
        Navigator.pushReplacementNamed(context, MainRoutes.home);
        return;
      }

      // A rejected token is cleared by restoreSession; transient failures keep
      // the token for the next attempt rather than silently signing out.
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
