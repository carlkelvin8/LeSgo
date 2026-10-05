import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/google_maps_platform_config.dart';
import 'core/constants/routers/app_router.dart';
import 'core/constants/routers/auth/auth_routes.dart';
import 'core/di/injection.dart';
import 'core/utils/app_logger.dart';
import 'core/services/api_service.dart';
import 'core/services/app_crash_reporter.dart';
import 'core/services/app_version_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/mobile_config_service.dart';
import 'core/services/notification_navigation_service.dart';
import 'core/services/remember_me_service.dart';
import 'core/services/secure_storage_service.dart';
import 'presentation/widgets/common/force_update_dialog.dart';
import 'presentation/widgets/common/offline_banner.dart';
import 'presentation/provider/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureGoogleMapsForPlatform();
  await RememberMeService.init();
  await MobileConfigService.instance.load();

  final existingToken = await SecureStorageService.getToken();
  AppLogger.auth(
    'Startup session: ${existingToken != null ? "token present" : "no token"}',
  );

  await configureDependencies();
  await AppCrashReporter.initialize();
  await FcmService.instance.initialize();
  ApiService.trackAnalyticsEvent(
    'app_opened',
    properties: {'app': 'rider', 'timestamp': DateTime.now().toIso8601String()},
  );

  runApp(const ProviderScope(child: LesgoApp()));
}

class LesgoApp extends StatefulWidget {
  const LesgoApp({super.key});

  @override
  State<LesgoApp> createState() => _LesgoAppState();
}

class _LesgoAppState extends State<LesgoApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForceUpdate());
  }

  Future<void> _checkForceUpdate() async {
    final check = await AppVersionService.checkForUpdate();
    if (!mounted || check == null) return;
    await showForceUpdateDialog(context, check);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final themeMode = ref.watch(themeModeProvider);
        return MaterialApp(
          navigatorKey: NotificationNavigationService.navigatorKey,
          title: 'LeSgo Affiliates',
          debugShowCheckedModeBanner: false,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          themeMode: themeMode,
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
      },
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5F2D82)),
      useMaterial3: true,
      fontFamily: 'TT Fors',
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
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
