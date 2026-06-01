import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/routers/app_router.dart';
import 'core/constants/routers/auth/auth_routes.dart';
import 'core/di/injection.dart';
import 'core/services/app_preferences_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/promo_notification_service.dart';
import 'core/services/websocket_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await getIt<WebSocketService>().initialize();
  await getIt<NotificationService>().initialize();
  await getIt<PromoNotificationService>().initialize();

  runApp(const ProviderScope(child: LesgoApp()));
}

class LesgoApp extends StatelessWidget {
  const LesgoApp({super.key});

  Locale? _localeFromPrefs() {
    final code = getIt<AppPreferencesService>().appLanguage;
    if (code == 'tl') return const Locale('fil');
    return const Locale('en');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppRouter.navigatorKey,
      title: 'Lezgo',
      debugShowCheckedModeBanner: false,
      locale: _localeFromPrefs(),
      supportedLocales: const [
        Locale('en'),
        Locale('fil'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: LoginRoutes.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
