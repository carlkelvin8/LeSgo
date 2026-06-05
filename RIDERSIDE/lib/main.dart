import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/google_maps_platform_config.dart';
import 'core/constants/routers/app_router.dart';
import 'core/constants/routers/auth/auth_routes.dart';
import 'core/di/injection.dart';
import 'core/network/dio_client.dart';
import 'core/services/fcm_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/remember_me_service.dart';
import 'core/services/secure_storage_service.dart';
import 'presentation/widgets/common/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureGoogleMapsForPlatform();
  await RememberMeService.init();

  final existingToken = await SecureStorageService.getToken();
  debugPrint(
    'Existing token: ${existingToken != null ? "found" : "none"}',
  );

  await configureDependencies();
  DioClient().initialize();
  await PushNotificationService.initialize();
  await FcmService.instance.initialize();

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
      initialRoute: AuthRoutes.startup,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: OfflineBanner(),
            ),
          ],
        );
      },
    );
  }
}
