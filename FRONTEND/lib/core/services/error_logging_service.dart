import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Service for logging errors
/// In production, this should integrate with Crashlytics or Sentry
@lazySingleton
class ErrorLoggingService {
  /// Log an error
  void logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    // In development, print to console
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('❌ ERROR LOGGED');
      if (context != null) {
        debugPrint('Context: $context');
      }
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack Trace:\n$stackTrace');
      }
      if (additionalData != null) {
        debugPrint('Additional Data: $additionalData');
      }
      debugPrint('═══════════════════════════════════════');
    }

    // In production, send to error tracking service
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace);
    // Example: Sentry.captureException(error, stackTrace: stackTrace);
  }

  /// Log a warning
  void logWarning(
    String message, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: $message');
      if (context != null) {
        debugPrint('Context: $context');
      }
      if (additionalData != null) {
        debugPrint('Additional Data: $additionalData');
      }
    }
  }

  /// Log an info message
  void logInfo(
    String message, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      debugPrint('ℹ️ INFO: $message');
      if (context != null) {
        debugPrint('Context: $context');
      }
      if (additionalData != null) {
        debugPrint('Additional Data: $additionalData');
      }
    }
  }

  /// Log a network error
  void logNetworkError(
    dynamic error, {
    String? endpoint,
    int? statusCode,
    dynamic requestData,
    dynamic responseData,
  }) {
    logError(
      error,
      context: 'Network Error',
      additionalData: {
        'endpoint': endpoint,
        'statusCode': statusCode,
        'requestData': requestData,
        'responseData': responseData,
      },
    );
  }

  /// Log a user action
  void logUserAction(
    String action, {
    Map<String, dynamic>? data,
  }) {
    if (kDebugMode) {
      debugPrint('👤 User Action: $action');
      if (data != null) {
        debugPrint('Data: $data');
      }
    }

    // In production, send to analytics
    // Example: FirebaseAnalytics.instance.logEvent(name: action, parameters: data);
  }
}
