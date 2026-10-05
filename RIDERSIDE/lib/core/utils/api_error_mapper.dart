import 'package:dio/dio.dart';

/// Maps API/network errors to short, user-friendly messages.
class ApiErrorMapper {
  ApiErrorMapper._();

  static String message(
    Object? error, {
    String? fallbackEn,
    String? fallbackTl,
  }) {
    if (error == null) {
      return _pick(fallbackEn, fallbackTl, _defaultEn, _defaultTl);
    }

    if (error is DioException) {
      return _fromDio(error, fallbackEn: fallbackEn, fallbackTl: fallbackTl);
    }

    final raw = error.toString();
    if (_isTechnical(raw)) {
      return _pick(fallbackEn, fallbackTl, _defaultEn, _defaultTl);
    }
    return _sanitize(raw);
  }

  /// True when the API rejected an operational request because the account is
  /// not yet active (registration fee unpaid and/or application unapproved).
  static bool isRegistrationNotActiveError(Object? error) {
    if (error is! DioException) return false;
    return _isRegistrationNotActive(error.response?.data);
  }

  static bool _isRegistrationNotActive(dynamic data) {
    if (data is! Map) return false;
    return data['error_code']?.toString() == 'REGISTRATION_NOT_ACTIVE';
  }

  static bool _isTechnical(String text) {
    final lower = text.toLowerCase();
    return lower.contains('dioexception') ||
        lower.contains('socketexception') ||
        lower.contains('formatexception') ||
        lower.contains('status code of') ||
        lower.contains('developer.mozilla') ||
        lower.contains('error code: 502') ||
        lower.contains('handshake') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup');
  }

  static String _fromDio(
    DioException error, {
    String? fallbackEn,
    String? fallbackTl,
  }) {
    // Registration fee / application gate — detect first so the app can route
    // the user to the payment/status screen instead of a generic 403.
    if (_isRegistrationNotActive(error.response?.data)) {
      return _pick(
        fallbackEn,
        fallbackTl,
        'Your account is still under review. Complete your registration fee and wait for admin approval to use the app.',
        'Nire-review pa ang iyong account. Bayaran ang registration fee at hintayin ang approval ng admin para magamit ang app.',
      );
    }

    final apiMsg = _extractApiMessage(error.response?.data);
    if (apiMsg != null) return apiMsg;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return _pick(
          fallbackEn,
          fallbackTl,
          'Request timed out. Please try again.',
          'Nag-timeout ang request. Subukan muli.',
        );
      case DioExceptionType.connectionError:
        return _pick(
          fallbackEn,
          fallbackTl,
          'Cannot reach LeSGo server. Try again in a moment.',
          'Hindi maabot ang LeSGo server. Subukan muli maya-maya.',
        );
      default:
        break;
    }

    final code = error.response?.statusCode;
    if (code == 401) {
      return _pick(fallbackEn, fallbackTl, 'Please log in again.', 'Mag-log in muli.');
    }
    if (code == 403) {
      return _pick(
        fallbackEn,
        fallbackTl,
        'You do not have permission for this action.',
        'Walang pahintulot para sa aksyong ito.',
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
    if (code != null && code >= 500) {
      return _pick(
        fallbackEn,
        fallbackTl,
        'Server error. Please try again in a few minutes.',
        'May error sa server. Subukan muli maya-maya.',
      );
    }

    final dioMsg = error.message;
    if (dioMsg != null && _isTechnical(dioMsg)) {
      return _pick(fallbackEn, fallbackTl, _defaultEn, _defaultTl);
    }

    return _pick(fallbackEn, fallbackTl, _defaultEn, _defaultTl);
  }

  static String? _extractApiMessage(dynamic data) {
    if (data is! Map) {
      if (data is String && data.isNotEmpty && !_isTechnical(data) && data.length < 160) {
        return data;
      }
      return null;
    }

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          final msg = value.first.toString();
          if (msg.isNotEmpty && !_isTechnical(msg)) {
            return msg;
          }
        } else if (value is String && value.isNotEmpty && !_isTechnical(value)) {
          return value;
        }
      }
    }

    for (final key in ['message', 'error', 'detail']) {
      final v = data[key];
      if (v is String &&
          v.isNotEmpty &&
          !_isTechnical(v) &&
          v.length < 160 &&
          !_isGenericValidationMessage(v)) {
        return v;
      }
    }

    return null;
  }

  static bool _isGenericValidationMessage(String message) {
    final lower = message.toLowerCase();
    return lower == 'the given data was invalid.' ||
        lower.contains('validation failed');
  }

  static String _sanitize(String raw) {
    var text = raw;
    if (text.startsWith('Exception: ')) {
      text = text.substring('Exception: '.length);
    }
    if (_isTechnical(text)) return _defaultEn;
    if (text.length > 160) return '${text.substring(0, 157)}...';
    return text;
  }

  static String _pick(String? en, String? tl, String defaultEn, String defaultTl) {
    final english = (en != null && en.isNotEmpty) ? en : defaultEn;
    final tagalog = (tl != null && tl.isNotEmpty) ? tl : defaultTl;
    if (english == tagalog) return english;
    return '$english\n$tagalog';
  }

  static const _defaultEn = 'Something went wrong. Please try again.';
  static const _defaultTl = 'May nangyaring mali. Subukan muli.';
}
