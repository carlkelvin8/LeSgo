import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../config/secrets_config.dart';
import '../utils/app_logger.dart';

/// Initializes Firebase Crashlytics and captures uncaught Flutter/Dart errors.
class AppCrashReporter {
  AppCrashReporter._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    // Crashlytics collection is disabled in debug builds. Installing its global
    // error handlers there also replaces Flutter test's error handler, which
    // hides the original widget/test failure and makes integration tests hang.
    if (_initialized || kIsWeb || kDebugMode) return;

    if (!SecretsConfig.isFirebaseConfigured &&
        !DefaultFirebaseOptions.isConfigured) {
      AppLogger.debug('Crashlytics skipped: Firebase not configured');
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    _initialized = true;
    AppLogger.debug('Crashlytics initialized');
  }

  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    if (!_initialized || kDebugMode) return;
    await FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }

  static Future<void> log(String message) async {
    if (!_initialized) return;
    await FirebaseCrashlytics.instance.log(message);
  }
}
