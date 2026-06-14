import 'package:flutter/foundation.dart';

/// Debug-only logging. Never emits in release builds.
class AppLogger {
  AppLogger._();

  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void info(String message) => debug(message);

  static void warn(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ $message');
    }
  }

  static void error(String message, [Object? err, StackTrace? stack]) {
    if (!kDebugMode) return;
    if (err != null) {
      debugPrint('❌ $message: $err');
      if (stack != null) {
        debugPrint(stack.toString());
      }
    } else {
      debugPrint('❌ $message');
    }
  }

  static void auth(String message) {
    if (kDebugMode) {
      debugPrint('🔐 $message');
    }
  }

  static void network(
    String method,
    String path, {
    int? statusCode,
  }) {
    if (!kDebugMode) return;
    if (statusCode != null) {
      debug('🌐 $method $path → $statusCode');
    } else {
      debug('🌐 $method $path');
    }
  }

  static String maskEmail(String email) {
    final trimmed = email.trim();
    final at = trimmed.indexOf('@');
    if (at <= 1) return '***';
    return '${trimmed[0]}***${trimmed.substring(at)}';
  }

  static Object? sanitize(Object? value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((key, val) {
        final normalizedKey = key.toString().toLowerCase();
        if (_sensitiveKeys.any(normalizedKey.contains)) {
          return MapEntry(key, _redacted);
        }
        return MapEntry(key, sanitize(val));
      });
    }
    if (value is Iterable) {
      return value.map(sanitize).toList();
    }
    return value;
  }

  static const String _redacted = '***';

  static const List<String> _sensitiveKeys = [
    'password',
    'token',
    'refresh_token',
    'authorization',
    'secret',
    'fcm_token',
    'device_token',
    'api_key',
    'credential',
    'access_token',
  ];
}
