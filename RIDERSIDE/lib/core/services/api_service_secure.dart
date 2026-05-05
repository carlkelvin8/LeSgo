import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Enhanced API Service with security features
class ApiServiceSecure {
  static late Dio _dio;
  static bool _initialized = false;

  // API Configuration
  static String get _baseUrl => kReleaseMode
      ? 'https://api.lesgo.com/api' // Production HTTPS
      : (kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://10.0.2.2:8000/api');

  // Security headers
  static const String _apiVersion = 'v1';
  static const String _appVersion = '1.0.0';

  /// Initialize API service with security interceptors
  static Future<void> initialize() async {
    if (_initialized) return;

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-API-Version': _apiVersion,
        'X-App-Version': _appVersion,
      },
    ));

    // Add security interceptors
    _dio.interceptors.add(_SecurityInterceptor());
    _dio.interceptors.add(_RetryInterceptor());
    _dio.interceptors.add(_LoggingInterceptor());

    _initialized = true;
    print('🔒 ApiServiceSecure: Initialized with security features');
  }

  static Dio get dio {
    if (!_initialized) {
      throw StateError('ApiServiceSecure not initialized. Call initialize() first.');
    }
    return _dio;
  }

  /// Login with enhanced security
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final deviceId = await SecureStorageService.getDeviceId();
      
      final response = await _dio.post('/v1/auth/login', data: {
        'email': email,
        'password': password,
        'device_id': deviceId,
        'device_name': await _getDeviceName(),
      });

      final data = response.data as Map<String, dynamic>;
      
      // Extract token and expiry
      final token = data['data']?['token'] ?? data['token'];
      final expiresIn = data['data']?['expires_in'] ?? 3600; // Default 1 hour
      final refreshToken = data['data']?['refresh_token'];
      final userId = data['data']?['user']?['id'];

      if (token != null) {
        // Save token securely with expiration
        await SecureStorageService.saveToken(
          token: token,
          expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
          refreshToken: refreshToken,
          userId: userId,
        );
      }

      return data;
    } catch (e) {
      print('❌ ApiServiceSecure: Login failed: $e');
      rethrow;
    }
  }

  /// Refresh token
  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken == null) {
        print('❌ ApiServiceSecure: No refresh token available');
        return false;
      }

      final response = await _dio.post('/v1/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      final data = response.data as Map<String, dynamic>;
      final newToken = data['data']?['token'] ?? data['token'];
      final expiresIn = data['data']?['expires_in'] ?? 3600;
      final newRefreshToken = data['data']?['refresh_token'];

      if (newToken != null) {
        await SecureStorageService.saveToken(
          token: newToken,
          expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
          refreshToken: newRefreshToken ?? refreshToken,
        );
        print('✅ ApiServiceSecure: Token refreshed successfully');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ ApiServiceSecure: Token refresh failed: $e');
      return false;
    }
  }

  /// Logout
  static Future<void> logout() async {
    try {
      await _dio.post('/v1/auth/logout');
    } catch (e) {
      print('⚠️ ApiServiceSecure: Logout request failed: $e');
    } finally {
      await SecureStorageService.clearAuth();
    }
  }

  /// Get device name
  static Future<String> _getDeviceName() async {
    if (kIsWeb) return 'Web Browser';
    // In production, use device_info_plus package
    return 'Mobile Device';
  }

  /// Generate request signature (for critical operations)
  static String _generateSignature(String data, String timestamp) {
    final secret = 'YOUR_SECRET_KEY'; // Should be from secure config
    final message = '$data:$timestamp:$secret';
    final bytes = utf8.encode(message);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}

/// Security Interceptor
class _SecurityInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Add authentication token
      final token = await SecureStorageService.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      // Add device ID
      final deviceId = await SecureStorageService.getDeviceId();
      options.headers['X-Device-ID'] = deviceId;

      // Add timestamp
      options.headers['X-Timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();

      // Add request ID for tracking
      options.headers['X-Request-ID'] = _generateRequestId();

      // Security headers
      options.headers['X-Content-Type-Options'] = 'nosniff';
      options.headers['X-Frame-Options'] = 'DENY';

      print('🔒 Security: Request to ${options.path}');
    } catch (e) {
      print('❌ Security: Error in request interceptor: $e');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized - token expired
    if (err.response?.statusCode == 401) {
      print('🔒 Security: 401 Unauthorized - attempting token refresh');
      
      final refreshed = await ApiServiceSecure.refreshToken();
      if (refreshed) {
        // Retry original request with new token
        try {
          final token = await SecureStorageService.getToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          
          final response = await Dio().fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          print('❌ Security: Retry failed: $e');
        }
      }
      
      // Token refresh failed - clear auth and redirect to login
      await SecureStorageService.clearAuth();
      print('🔒 Security: Token refresh failed - user needs to login');
    }

    handler.next(err);
  }

  String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    return '$timestamp-$random';
  }
}

/// Retry Interceptor for network failures
class _RetryInterceptor extends Interceptor {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retryCount'] ?? 0;
      
      if (retryCount < maxRetries) {
        print('🔄 Retry: Attempt ${retryCount + 1}/$maxRetries for ${err.requestOptions.path}');
        
        await Future.delayed(retryDelay * (retryCount + 1));
        
        err.requestOptions.extra['retryCount'] = retryCount + 1;
        
        try {
          final response = await Dio().fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          print('❌ Retry: Failed: $e');
        }
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // Retry on network errors and 5xx server errors
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}

/// Logging Interceptor (only in debug mode)
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('📤 Request: ${options.method} ${options.path}');
      if (options.data != null) {
        print('📤 Data: ${_sanitizeData(options.data)}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('📥 Response: ${response.statusCode} ${response.requestOptions.path}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('❌ Error: ${err.response?.statusCode} ${err.requestOptions.path}');
      print('❌ Message: ${err.message}');
    }
    handler.next(err);
  }

  /// Sanitize sensitive data from logs
  dynamic _sanitizeData(dynamic data) {
    if (data is Map) {
      final sanitized = Map.from(data);
      const sensitiveKeys = ['password', 'token', 'secret', 'api_key'];
      
      for (final key in sensitiveKeys) {
        if (sanitized.containsKey(key)) {
          sanitized[key] = '***REDACTED***';
        }
      }
      
      return sanitized;
    }
    return data;
  }
}

