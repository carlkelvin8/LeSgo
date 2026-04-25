import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../constants/api_constants.dart';
import '../di/local_storage_service.dart';

@lazySingleton
class DioClient {
  final Dio dio;
  final LocalStorageService _localStorageService;

  DioClient(this._localStorageService)
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    print('🔵 DioClient: Initialized');
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
        onError: (error, handler) {
          print('🔴 DioClient: Error ${error.response?.statusCode} on ${error.requestOptions.path}');
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
