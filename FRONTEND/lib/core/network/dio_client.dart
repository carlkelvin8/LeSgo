import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../constants/api_constants.dart';
import '../di/local_storage_service.dart';
import '../services/rate_limiter_service.dart';
import 'rate_limit_interceptor.dart';

@lazySingleton
class DioClient {
  final Dio dio;
  final LocalStorageService _localStorageService;
  final RateLimiterService _rateLimiter;

  DioClient(this._localStorageService, this._rateLimiter)
    : dio = Dio(
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
    print('🔵 DioClient: Initialized');
    dio.interceptors.add(RateLimitInterceptor(_rateLimiter));
    // Add interceptor to attach token to all requests
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _localStorageService.token;
          print('🔵 DioClient: Request to ${options.path}, token: ${token != null ? "${token.substring(0, 20)}..." : "NULL"}');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('🟢 DioClient: Response ${response.statusCode} from ${response.requestOptions.path}');
          print('🟢 DioClient: Response data type: ${response.data.runtimeType}');
          if (response.data is Map) {
            final dataMap = response.data as Map;
            print('🟢 DioClient: Response keys: ${dataMap.keys.toList()}');
            if (dataMap.containsKey('data') && dataMap['data'] is List) {
              print('🟢 DioClient: Data array length: ${(dataMap['data'] as List).length}');
            }
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          print('🔴 DioClient: Error ${error.response?.statusCode} on ${error.requestOptions.path}');
          print('🔴 DioClient: Error type: ${error.type}');
          print('🔴 DioClient: Error message: ${error.message}');
          print('🔴 DioClient: Error response: ${error.response?.data}');

          // Handle 401 errors by clearing token
          if (error.response?.statusCode == 401) {
            print('🔴 DioClient: 401 Unauthorized - clearing token');
            _localStorageService.clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }
}
