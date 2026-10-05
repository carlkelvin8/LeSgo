import 'package:dio/dio.dart';

/// Base exception class for all app-level errors.
/// Provides a user-friendly message and optional technical details for logging.
sealed class AppException implements Exception {
  /// User-friendly message safe to display in UI.
  String get userMessage;

  /// Technical details for logging/crash reporting (never shown to users).
  String? get technicalDetails;

  /// HTTP status code if this originated from an API call.
  int? get statusCode;

  @override
  String toString() => 'AppException($userMessage)';
}

/// Network connectivity issues (no internet, DNS failure, timeout).
class NetworkException extends AppException {
  @override
  final String userMessage;
  @override
  final String? technicalDetails;
  @override
  int? get statusCode => null;

  NetworkException({
    this.userMessage = 'No internet connection. Please check your network.',
    this.technicalDetails,
  });
}

/// Server returned an error response (4xx, 5xx).
class ApiException extends AppException {
  @override
  final String userMessage;
  @override
  final String? technicalDetails;
  @override
  final int? statusCode;

  /// The raw error body from the server (if available).
  final Map<String, dynamic>? responseBody;

  /// Validation errors from 422 responses.
  final Map<String, List<String>>? validationErrors;

  ApiException({
    required this.userMessage,
    this.technicalDetails,
    this.statusCode,
    this.responseBody,
    this.validationErrors,
  });

  /// True if this is a validation error (422).
  bool get isValidation => statusCode == 422;

  /// True if authentication is required (401).
  bool get isUnauthorized => statusCode == 401;

  /// True if user lacks permission (403).
  bool get isForbidden => statusCode == 403;

  /// True if resource not found (404).
  bool get isNotFound => statusCode == 404;

  /// True if rate limited (429).
  bool get isRateLimited => statusCode == 429;

  /// True if server error (5xx).
  bool get isServerError => statusCode != null && statusCode! >= 500;
}

/// Unexpected errors (parsing failures, null values where unexpected, etc.).
class UnexpectedException extends AppException {
  @override
  final String userMessage;
  @override
  final String? technicalDetails;
  @override
  int? get statusCode => null;

  UnexpectedException({
    this.userMessage = 'Something went wrong. Please try again.',
    this.technicalDetails,
  });
}

/// Authentication expired or invalid — user needs to re-login.
class AuthExpiredException extends AppException {
  @override
  final String userMessage;
  @override
  final String? technicalDetails;
  @override
  int? get statusCode => 401;

  AuthExpiredException({
    this.userMessage = 'Your session has expired. Please log in again.',
    this.technicalDetails,
  });
}

/// Utility to convert raw exceptions into typed AppExceptions.
class AppExceptionMapper {
  AppExceptionMapper._();

  /// Convert any caught exception into an [AppException].
  static AppException from(Object error, {String? context}) {
    if (error is AppException) return error;

    if (error is DioException) return _fromDio(error, context: context);

    final msg = error.toString();
    if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
      return NetworkException(technicalDetails: '$context: $msg');
    }

    return UnexpectedException(
      technicalDetails: '$context: $msg',
    );
  }

  static AppException _fromDio(DioException error, {String? context}) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    // Network-level errors
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          userMessage: 'Connection timed out. Please try again.',
          technicalDetails: '$context: ${error.type} - ${error.message}',
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          technicalDetails: '$context: ${error.message}',
        );
      default:
        break;
    }

    // HTTP errors
    final apiMessage = _extractMessage(responseData);

    if (statusCode == 401) {
      return AuthExpiredException(
        technicalDetails: '$context: $apiMessage',
      );
    }

    if (statusCode == 422) {
      return ApiException(
        userMessage: apiMessage ?? 'Please check your input and try again.',
        statusCode: 422,
        responseBody: responseData is Map<String, dynamic> ? responseData : null,
        validationErrors: _extractValidationErrors(responseData),
        technicalDetails: '$context: 422 - $apiMessage',
      );
    }

    if (statusCode == 429) {
      return ApiException(
        userMessage: 'Too many requests. Please wait a moment.',
        statusCode: 429,
        technicalDetails: '$context: Rate limited',
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return ApiException(
        userMessage: 'Server is temporarily unavailable. Please try again shortly.',
        statusCode: statusCode,
        technicalDetails: '$context: $statusCode - $apiMessage',
      );
    }

    return ApiException(
      userMessage: apiMessage ?? 'Something went wrong. Please try again.',
      statusCode: statusCode,
      technicalDetails: '$context: $statusCode - ${error.message}',
    );
  }

  static String? _extractMessage(dynamic data) {
    if (data is! Map) return null;
    for (final key in ['message', 'error', 'detail']) {
      final v = data[key];
      if (v is String && v.isNotEmpty && v.length < 200) return v;
    }
    return null;
  }

  static Map<String, List<String>>? _extractValidationErrors(dynamic data) {
    if (data is! Map) return null;
    final errors = data['errors'];
    if (errors is! Map) return null;

    final result = <String, List<String>>{};
    for (final entry in errors.entries) {
      if (entry.value is List) {
        result[entry.key.toString()] =
            (entry.value as List).map((e) => e.toString()).toList();
      }
    }
    return result.isEmpty ? null : result;
  }
}
