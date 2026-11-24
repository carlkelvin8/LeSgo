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
import 'core/utils/map_pins.dart';
import 'presentation/provider/theme_provider.dart';
import 'presentation/widgets/common/offline_banner.dart';

AnalyticsRouteObserver? _analyticsRouteObserver;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MapPins.preload());
  runApp(const ProviderScope(child: _AppBootstrap()));
}

/// Render a real Flutter frame immediately instead of leaving iOS on its blank
/// native launch screen while config, secure storage, and local services start.
class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  late Future<void> _initialization;
  Future<void>? _dependenciesInitialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    // These calls are deliberately after the first loading frame. Maps are
    // configured before the customer routes can construct a GoogleMap.
    await WidgetsBinding.instance.endOfFrame;
    await MobileConfigService.instance.loadFromApi();
    await configureGoogleMapsForPlatform();
    try {
      await (_dependenciesInitialization ??= configureDependencies());
    } catch (_) {
      // A failed registration can leave GetIt partially populated. Retry from
      // a clean container while no customer screens have been constructed.
      await getIt.reset();
      _dependenciesInitialization = null;
      rethrow;
    }
    await CrashReporterService.initialize();

    _analyticsRouteObserver = AnalyticsRouteObserver(getIt<AnalyticsService>());
    await getIt<WebSocketService>().initialize();
    // Push setup can wait on APNs/Firebase in simulators. It must not block the
    // first customer frame.
    unawaited(_initializePushServices());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _loaderTheme(),
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('LeSgo could not start. Please try again.'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => setState(() {
                          _initialization = _initialize();
                        }),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _loaderTheme(),
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF5F2D82)),
                    const SizedBox(height: 16),
                    Text(
                      'Starting LeSgo…',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const LesgoApp();
      },
    );
  }
}

Future<void> _initializePushServices() async {
  try {
    await getIt<NotificationService>().initialize();
    await getIt<PromoNotificationService>().initialize();
  } catch (error, stackTrace) {
    debugPrint('Push services initialization failed: $error\n$stackTrace');
  }
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
        // Keep the app's own scale up to 130%. Past that, the fixed-height
        // cards (hero banner, order cards, headers) start to overflow.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.3,
            ),
          ),
          child: BiometricUnlockGate(
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
          ),
        );
      },
    );
  }
}

/// Theme for the pre-app loader, which runs before the app theme is ready.
/// Follows the system brightness so dark mode doesn't flash white.
ThemeData _loaderTheme() {
  final dark =
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;
  return ThemeData(brightness: dark ? Brightness.dark : Brightness.light);
}
