import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../services/secure_storage_service.dart';
import 'token_refresh_service.dart';

/// Attaches bearer tokens and silently refreshes on 401 before retrying.
class AuthTokenInterceptor extends QueuedInterceptor {
  AuthTokenInterceptor(this._dio);

  final Dio _dio;

  static const _skipRefreshPaths = <String>{
    ApiConstants.loginEndpoint,
    ApiConstants.authRefresh,
    '/v1/auth/register',
    '/v1/auth/google',
    '/v1/auth/forgot-password/send-otp',
    '/v1/auth/forgot-password/verify-otp',
    '/v1/auth/forgot-password/reset',
  };

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || _shouldSkipRefresh(err.requestOptions)) {
      handler.next(err);
      return;
    }

    final failedToken = _bearerOf(err.requestOptions);

    // The session may have been renewed while this request was in flight
    // (another 401 refreshed it, or a password change issued new tokens and
    // revoked the old ones). Retry with the current token instead of
    // refreshing again or - worse - clearing the brand-new session.
    final storedToken = await SecureStorageService.getToken();
    if (err.requestOptions.extra['retriedAfterRefresh'] != true &&
        storedToken != null &&
        storedToken.isNotEmpty &&
        failedToken != null &&
        storedToken != failedToken) {
      await _retryWith(storedToken, err, handler);
      return;
    }

    if (err.requestOptions.extra['retriedAfterRefresh'] == true) {
      await _clearAuthIfStillUsing(failedToken);
      handler.next(err);
      return;
    }

    final newToken = await TokenRefreshService.instance.refreshAccessToken();
    if (newToken == null || newToken.isEmpty) {
      // Only drop the session when the server actually rejected it; an
      // offline/throttled (429) refresh must not log the rider out.
      if (!TokenRefreshService.instance.lastFailureWasTransient) {
        await _clearAuthIfStillUsing(failedToken);
      }
      handler.next(err);
      return;
    }

    await _retryWith(newToken, err, handler);
  }

  Future<void> _retryWith(
    String token,
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final requestOptions = err.requestOptions;
      requestOptions.headers['Authorization'] = 'Bearer $token';
      requestOptions.extra['retriedAfterRefresh'] = true;
      final response = await _dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode == 401) {
        await _clearAuthIfStillUsing(token);
      }
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  /// Clears the session only if it still holds the exact token the server
  /// rejected. A request that carried no token (sent while logged out or
  /// mid-login) or an older token must never wipe a newer session that was
  /// saved while the request was in flight.
  Future<void> _clearAuthIfStillUsing(String? rejectedToken) async {
    if (rejectedToken == null || rejectedToken.isEmpty) return;
    final current = await SecureStorageService.getToken();
    if (current == null || current.isEmpty || current == rejectedToken) {
      await SecureStorageService.clearAuth();
    }
  }

  String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is! String || !header.startsWith('Bearer ')) return null;
    return header.substring('Bearer '.length);
  }

  bool _shouldSkipRefresh(RequestOptions options) {
    final path = options.path;
    for (final skipPath in _skipRefreshPaths) {
      if (path == skipPath || path.endsWith(skipPath)) return true;
    }
    return false;
  }
}
