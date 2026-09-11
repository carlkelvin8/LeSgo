import 'package:dio/dio.dart';

import '../exceptions/client_rate_limit_exception.dart';

/// Maps API/network errors to short, user-friendly Tagalog/English messages.
class ApiErrorMapper {
  ApiErrorMapper._();

  static bool isRateLimited(Object? error) {
    if (error is ClientRateLimitException) return true;
    if (error is DioException && error.response?.statusCode == 429) {
      return true;
    }
    return false;
  }

  static String message(
    Object? error, {
    String? fallbackEn,
    String? fallbackTl,
  }) {
    if (error == null) {
      return _pick(fallbackEn, fallbackTl, _defaultEn, _defaultTl);
    }

    if (error is ClientRateLimitException) {
      return _rateLimitMessage(error.retryAfterSeconds);
    }

    if (error is DioException) {
      final wrapped = error.error;
      if (wrapped is ClientRateLimitException) {
        return _rateLimitMessage(wrapped.retryAfterSeconds);
      }
      return _fromDio(error, fallbackEn: fallbackEn, fallbackTl: fallbackTl);
    }

    final raw = error.toString();
    if (_isTechnical(raw)) {
      return _pick(fallbackEn, fallbackTl, _defaultEn, _defaultTl);
    }
    return _sanitize(raw);
  }

  static String _rateLimitMessage(int retryAfterSeconds) {
    final wait = retryAfterSeconds.clamp(1, 300);
    if (wait <= 60) {
      return 'Too many requests. Please wait $wait second${wait == 1 ? '' : 's'}.\n'
          'Masyadong maraming request. Maghintay ng $wait segundo.';
    }
    final minutes = (wait / 60).ceil();
    return 'Too many requests. Please wait about $minutes minute${minutes == 1 ? '' : 's'}.\n'
        'Masyadong maraming request. Maghintay ng mga $minutes minuto.';
  }

  static bool _isTechnical(String text) {
    final lower = text.toLowerCase();
    return lower.contains('dioexception') ||
        lower.contains('socketexception') ||
        lower.contains('formatexception') ||
        lower.contains('status code of') ||
        lower.contains('handshake') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientratelimitexception');
  }

  static String _fromDio(
    DioException error, {
    String? fallbackEn,
    String? fallbackTl,
  }) {
    final code = error.response?.statusCode;
    if (code == 401) {
      return _pick(
        null,
        null,
        'Your session has expired. Please log in again.',
        'Nag-expire ang session. Mag-log in muli.',
      );
    }

    final apiMsg = _extractApiMessage(error.response?.data);
    if (apiMsg != null && !_looksLikeRateLimit(apiMsg)) return apiMsg;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return _pick(
          fallbackEn,
          fallbackTl,
          'Connection timed out. Check your internet and try again.',
          'Nag-timeout ang koneksyon. Suriin ang internet at subukan muli.',
        );
      case DioExceptionType.connectionError:
        return _pick(
          fallbackEn,
          fallbackTl,
          'Cannot reach the server. Check your internet connection.',
          'Hindi maabot ang server. Suriin ang iyong internet.',
        );
      case DioExceptionType.cancel:
        final inner = error.error;
        if (inner is ClientRateLimitException) {
          return _rateLimitMessage(inner.retryAfterSeconds);
        }
        return _pick(
          fallbackEn,
          fallbackTl,
          'Request was cancelled.',
          'Kinansela ang request.',
        );
      case DioExceptionType.badCertificate:
        return _pick(
          fallbackEn,
          fallbackTl,
          'Secure connection could not be verified.',
          'Hindi ma-verify ang secure na koneksyon.',
        );
      default:
        break;
    }

    if (code == 403) {
      return _pick(
        fallbackEn,
        fallbackTl,
        'You do not have permission for this action.',
        'Walang pahintulot para sa aksyong ito.',
      );
    }
    if (code == 404) {
      return _pick(
        fallbackEn,
        fallbackTl,
        'The requested item was not found.',
        'Hindi mahanap ang hiniling.',
      );
    }
    if (code == 422) {
      return _pick(
        fallbackEn,
        fallbackTl,
        'Please check your information and try again.',
        'Suriin ang iyong impormasyon at subukan muli.',
      );
    }
    if (code == 429) {
      final retryAfter = _parseRetryAfter(
        error.response?.headers.value('retry-after'),
      );
      if (retryAfter != null) {
        return _rateLimitMessage(retryAfter);
      }
      return _pick(
        fallbackEn,
        fallbackTl,
        'Too many requests. Please wait a moment and try again.',
        'Masyadong maraming request. Maghintay sandali at subukan muli.',
      );
    }
    if (code != null && code >= 500) {
      return _pick(
        fallbackEn,
        fallbackTl,
        'Server is busy. Please try again shortly.',
        'Abala ang server. Subukan muli maya-maya.',
      );
    }

    return _pick(fallbackEn, fallbackTl, _defaultEn, _defaultTl);
  }

  static bool _looksLikeRateLimit(String message) {
    final lower = message.toLowerCase();
    return lower.contains('rate limit') ||
        lower.contains('too many') ||
        lower.contains('throttle');
  }

  static int? _parseRetryAfter(String? header) {
    if (header == null || header.isEmpty) return null;
    final asInt = int.tryParse(header.trim());
    if (asInt != null) return asInt;
    return null;
  }

  static String? _extractApiMessage(dynamic data) {
    if (data is! Map) return null;
    for (final key in ['message', 'error', 'detail']) {
      final v = data[key];
      if (v is String && v.isNotEmpty && !_isTechnical(v) && v.length < 160) {
        if (_looksLikeRateLimit(v)) {
          return _pick(
            null,
            null,
            'Too many requests. Please wait a moment and try again.',
            'Masyadong maraming request. Maghintay sandali at subukan muli.',
          );
        }
        return v;
      }
    }
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        final msg = first.first.toString();
        if (!_isTechnical(msg)) return msg;
      }
    }
    return null;
  }

  static String _sanitize(String raw) {
    var text = raw;
    if (text.startsWith('Exception: ')) {
      text = text.substring('Exception: '.length);
    }
    if (_isTechnical(text)) {
      return _defaultEn;
    }
    if (text.length > 160) {
      return '${text.substring(0, 157)}...';
    }
    return text;
  }

  /// Prefer English; append Tagalog when both provided.
  static String _pick(
    String? en,
    String? tl,
    String defaultEn,
    String defaultTl,
  ) {
    final english = (en != null && en.isNotEmpty) ? en : defaultEn;
    final tagalog = (tl != null && tl.isNotEmpty) ? tl : defaultTl;
    if (english == tagalog) return english;
    return '$english\n$tagalog';
  }

  static const _defaultEn = 'Something went wrong. Please try again.';
  static const _defaultTl = 'May nangyaring mali. Subukan muli.';
}
