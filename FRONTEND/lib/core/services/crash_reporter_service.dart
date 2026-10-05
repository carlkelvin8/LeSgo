import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Initializes Firebase Crashlytics and captures uncaught Flutter/Dart errors.
class CrashReporterService {
  CrashReporterService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    try {
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        if (!kDebugMode) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        if (!kDebugMode) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        }
        return true;
      };

      _initialized = true;
      debugPrint('✅ Crashlytics initialized');
    } catch (e) {
      debugPrint('⚠️ Crashlytics init failed: $e');
    }
  }

  /// Record a non-fatal error.
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

  /// Log a message for breadcrumb context in crash reports.
  static Future<void> log(String message) async {
    if (!_initialized) return;
    await FirebaseCrashlytics.instance.log(message);
  }

  /// Set a user identifier for crash reports.
  static Future<void> setUserId(String userId) async {
    if (!_initialized) return;
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }
}
