import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../di/local_storage_service.dart';
import 'token_refresh_service.dart';

/// Attaches bearer tokens and silently refreshes on 401 before retrying.
class AuthTokenInterceptor extends QueuedInterceptor {
  final LocalStorageService _localStorageService;
  final TokenRefreshService _tokenRefreshService;
  final Dio _dio;

  AuthTokenInterceptor(
    this._localStorageService,
    this._tokenRefreshService,
    this._dio,
  );

  static const _skipRefreshPaths = <String>{
    ApiConstants.loginEndpoint,
    ApiConstants.authRefresh,
    '/v1/auth/register',
    '/v1/auth/google',
    '/v1/auth/otp/send',
    '/v1/auth/otp/verify',
    '/v1/auth/forgot-password/send-otp',
    '/v1/auth/forgot-password/verify-otp',
    '/v1/auth/forgot-password/reset',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _localStorageService.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    if (statusCode != 401 || _shouldSkipRefresh(err.requestOptions)) {
      handler.next(err);
      return;
    }

    if (err.requestOptions.extra['retriedAfterRefresh'] == true) {
      await _localStorageService.clearToken();
      handler.next(err);
      return;
    }

    final newToken = await _tokenRefreshService.refreshAccessToken();
    if (newToken == null || newToken.isEmpty) {
      await _localStorageService.clearToken();
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
        await _localStorageService.clearToken();
      }
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _shouldSkipRefresh(RequestOptions options) {
    if (options.extra['skipAuthRefresh'] == true) return true;

    final path = options.path;
    if (_skipRefreshPaths.contains(path)) return true;

    for (final skipPath in _skipRefreshPaths) {
      if (path.endsWith(skipPath)) return true;
    }

    return false;
  }
}
