import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/google_maps_platform_config.dart';
import 'core/config/mobile_config_service.dart';
import 'core/constants/routers/app_router.dart';
import 'core/constants/routers/auth/auth_routes.dart';
import 'core/di/injection.dart';
import 'core/services/analytics_service.dart';
import 'core/services/app_preferences_service.dart';
import 'core/services/crash_reporter_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/promo_notification_service.dart';
import 'core/services/websocket_service.dart';
import 'presentation/provider/theme_provider.dart';
import 'presentation/widgets/common/offline_banner.dart';

AnalyticsRouteObserver? _analyticsRouteObserver;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileConfigService.instance.loadFromApi();
  await configureGoogleMapsForPlatform();
  await configureDependencies();

  // Initialize crash reporting (only in release builds)
  await CrashReporterService.initialize();

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
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      navigatorKey: AppRouter.navigatorKey,
      navigatorObservers: [
        if (_analyticsRouteObserver != null) _analyticsRouteObserver!,
      ],
      title: 'LeSgo',
      debugShowCheckedModeBanner: false,
      locale: _localeFromPrefs(),
      supportedLocales: const [
        Locale('en'),
        Locale('fil'),
      ],
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: themeMode,
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

  ThemeData _lightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5F2D82)),
      useMaterial3: true,
      fontFamily: 'TT Fors',
      scaffoldBackgroundColor: Colors.white,
    );
  }

  ThemeData _darkTheme() {
    const violet = Color(0xFF5F2D82);
    const violetDark = Color(0xFF3D1F57);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'TT Fors',
      scaffoldBackgroundColor: violetDark,
      colorScheme: const ColorScheme.dark(
        primary: violet,
        onPrimary: Colors.white,
        secondary: Color(0xFFB388FF),
        onSecondary: Colors.white,
        surface: violet,
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white70,
        outline: Colors.white24,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: violet,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: 'TT Fors',
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        color: violet,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: Colors.white24),
      iconTheme: const IconThemeData(color: Colors.white),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white,
        textColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: violet,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white70,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFFB388FF)
              : Colors.white24,
        ),
      ),
    );
  }
}
