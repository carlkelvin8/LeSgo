import 'core/theme/app_theme.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/google_maps_platform_config.dart';
import 'core/config/mobile_config_service.dart';
import 'core/constants/routers/app_router.dart';
import 'core/constants/routers/auth/auth_routes.dart';
import 'core/di/injection.dart';
import 'core/di/local_storage_service.dart';
import 'core/services/biometric_unlock_service.dart';
import 'presentation/provider/auth/auth_provider.dart';
import 'presentation/widgets/auth/biometric_unlock_gate.dart';
import 'core/services/analytics_service.dart';
import 'core/services/crash_reporter_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/promo_notification_service.dart';
import 'core/services/websocket_service.dart';
import 'core/utils/app_localization.dart';
import 'presentation/provider/theme_provider.dart';
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
  // Notification initialization creates the Firebase app required by Crashlytics.
  await CrashReporterService.initialize();
  await getIt<PromoNotificationService>().initialize();

  runApp(const ProviderScope(child: LesgoApp()));
}

class LesgoApp extends ConsumerWidget {
  const LesgoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(appLanguageProvider);
    final locale = Locale(language == AppLanguage.filipino ? 'fil' : 'en');

    return MaterialApp(
      navigatorKey: AppRouter.navigatorKey,
      navigatorObservers: [
        if (_analyticsRouteObserver != null) _analyticsRouteObserver!,
      ],
      title: 'LeSgo',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('fil')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialRoute: LoginRoutes.startup,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) {
        return BiometricUnlockGate(
          service: ref.watch(biometricUnlockServiceProvider),
          storage: getIt<LocalStorageService>(),
          onSignInAgain: () async {
            // Explicit recovery: full logout including biometric unlock.
            await ref.read(authProvider.notifier).clearLocalSession();
            AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
              LoginRoutes.login,
              (_) => false,
            );
          },
          child: Stack(
            children: [
              if (child != null) child,
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: OfflineBanner(),
              ),
            ],
          ),
        );
      },
    );
  }

}
