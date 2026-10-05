import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../constants/api_constants.dart';
import '../di/local_storage_service.dart';
import '../services/rate_limiter_service.dart';
import 'auth_token_interceptor.dart';
import 'rate_limit_interceptor.dart';
import 'token_refresh_service.dart';

@lazySingleton
class DioClient {
  final Dio dio;
  final LocalStorageService _localStorageService;
  final RateLimiterService _rateLimiter;
  final TokenRefreshService _tokenRefreshService;

  DioClient(
    this._localStorageService,
    this._rateLimiter,
    this._tokenRefreshService,
  ) : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    dio.interceptors.add(RateLimitInterceptor(_rateLimiter));
    dio.interceptors.add(
      AuthTokenInterceptor(_localStorageService, _tokenRefreshService, dio),
    );
  }
}
