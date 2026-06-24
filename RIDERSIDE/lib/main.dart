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
  ApiService.trackAnalyticsEvent('app_opened', properties: {
    'app': 'rider',
    'timestamp': DateTime.now().toIso8601String(),
  });

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
          title: 'LezGo Rider',
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
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5F2D82),
        brightness: Brightness.dark,
      ),
      fontFamily: 'TT Fors',
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        iconTheme: IconThemeData(color: Color(0xFFB388FF)),
      ),
    );
  }
}
