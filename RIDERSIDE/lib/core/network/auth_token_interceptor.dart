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

    if (err.requestOptions.extra['retriedAfterRefresh'] == true) {
      await SecureStorageService.clearAuth();
      handler.next(err);
      return;
    }

    final newToken = await TokenRefreshService.instance.refreshAccessToken();
    if (newToken == null || newToken.isEmpty) {
      await SecureStorageService.clearAuth();
      handler.next(err);
      return;
    }

    try {
      final requestOptions = err.requestOptions;
      requestOptions.headers['Authorization'] = 'Bearer $newToken';
      requestOptions.extra['retriedAfterRefresh'] = true;
      final response = await _dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode == 401) {
        await SecureStorageService.clearAuth();
      }
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _shouldSkipRefresh(RequestOptions options) {
    final path = options.path;
    for (final skipPath in _skipRefreshPaths) {
      if (path == skipPath || path.endsWith(skipPath)) return true;
    }
    return false;
  }
}
