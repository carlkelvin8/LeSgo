import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/google_maps_platform_config.dart';
import 'core/config/mobile_config_service.dart';
import 'core/constants/routers/app_router.dart';
import 'core/constants/routers/auth/auth_routes.dart';
import 'core/di/injection.dart';
import 'core/services/analytics_service.dart';
import 'core/services/app_preferences_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/promo_notification_service.dart';
import 'core/services/websocket_service.dart';
import 'presentation/widgets/common/offline_banner.dart';

AnalyticsRouteObserver? _analyticsRouteObserver;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileConfigService.instance.loadFromApi();
  await configureGoogleMapsForPlatform();
  await configureDependencies();
  _analyticsRouteObserver = AnalyticsRouteObserver(getIt<AnalyticsService>());
  await getIt<WebSocketService>().initialize();
  await getIt<NotificationService>().initialize();
  await getIt<PromoNotificationService>().initialize();

  runApp(const ProviderScope(child: LesgoApp()));
}

class LesgoApp extends ConsumerWidget {
  const LesgoApp({super.key});

  Locale? _localeFromPrefs() {
    final code = getIt<AppPreferencesService>().appLanguage;
    if (code == 'tl') return const Locale('fil');
    return const Locale('en');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorKey: AppRouter.navigatorKey,
      navigatorObservers: [
        if (_analyticsRouteObserver != null) _analyticsRouteObserver!,
      ],
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
      initialRoute: LoginRoutes.startup,
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
