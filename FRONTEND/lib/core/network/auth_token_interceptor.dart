import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../di/local_storage_service.dart';
import 'token_refresh_service.dart';

class AuthTokenInterceptor extends Interceptor {
  final LocalStorageService _localStorageService;
  final TokenRefreshService _tokenRefreshService;
  final Dio _dio;

  AuthTokenInterceptor(this._localStorageService, this._tokenRefreshService, this._dio);

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
    if (err.response?.statusCode != 401 || _shouldSkipRefresh(err.requestOptions)) {
      handler.next(err);
      return;
    }
    final failedToken = _requestToken(err.requestOptions);
    final currentToken = _localStorageService.token;
    if (currentToken != null && currentToken.isNotEmpty &&
        (failedToken == null || currentToken != failedToken)) {
      await _retryWithToken(err, handler, currentToken);
      return;
    }
    if (err.requestOptions.extra['retriedAfterRefresh'] == true) {
      await _clearTokenOnlyIfCurrent(failedToken);
      handler.next(err);
      return;
    }
    final newToken = await _tokenRefreshService.refreshAccessToken();
    if (newToken == null || newToken.isEmpty) {
      await _clearTokenOnlyIfCurrent(failedToken);
      handler.next(err);
      return;
    }
    await _retryWithToken(err, handler, newToken);
  }

  Future<void> _retryWithToken(DioException originalError, ErrorInterceptorHandler handler, String token) async {
    try {
      final requestOptions = originalError.requestOptions;
      if (requestOptions.data case final FormData data) {
        requestOptions.data = data.clone();
      }
      requestOptions.headers['Authorization'] = 'Bearer $token';
      requestOptions.extra['retriedAfterRefresh'] = true;
      handler.resolve(await _dio.fetch<dynamic>(requestOptions));
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode == 401) {
        await _clearTokenOnlyIfCurrent(token);
      }
      handler.next(retryError);
    } catch (_) {
      handler.next(originalError);
    }
  }

  String? _requestToken(RequestOptions options) {
    final authorization = options.headers['Authorization']?.toString();
    if (authorization == null || !authorization.startsWith('Bearer ')) return null;
    return authorization.substring('Bearer '.length);
  }

  Future<void> _clearTokenOnlyIfCurrent(String? failedToken) async {
    if (failedToken == null || _localStorageService.token != failedToken) return;
    await _localStorageService.clearToken();
  }

  bool _shouldSkipRefresh(RequestOptions options) {
    if (options.extra['skipAuthRefresh'] == true) return true;
    final path = options.path;
    if (_skipRefreshPaths.contains(path)) return true;
    return _skipRefreshPaths.any(path.endsWith);
  }
}
