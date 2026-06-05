import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../services/secure_storage_service.dart';
import 'auth_token_interceptor.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  late final Dio _dio;

  Dio get dio => _dio;

  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final deviceId = await SecureStorageService.getDeviceId();
          options.headers['X-Device-ID'] = deviceId;
          handler.next(options);
        },
      ),
      AuthTokenInterceptor(_dio),
    ]);
  }
}
