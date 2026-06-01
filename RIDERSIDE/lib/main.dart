import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/routers/app_router.dart';
import 'core/constants/routers/auth/auth_routes.dart';
import 'core/di/injection.dart';
import 'core/network/dio_client.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final existingToken = await SecureStorageService.getToken();
  print('🔍 Existing token check: ${existingToken != null ? "Token found" : "No token"}');

  await configureDependencies();
  DioClient().initialize();
  await PushNotificationService.initialize();

  runApp(const ProviderScope(child: LesgoApp()));
}

class LesgoApp extends StatelessWidget {
  const LesgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lezgo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5F2D82)),
        useMaterial3: true,
        fontFamily: 'TT Fors',
      ),
      initialRoute: AuthRoutes.auth,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
