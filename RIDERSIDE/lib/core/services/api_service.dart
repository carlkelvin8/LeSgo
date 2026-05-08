import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

class ApiService {
  static String get _baseUrl => kReleaseMode
      ? 'https://api.lesgo.com/api' // Production HTTPS
      : (kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://10.0.2.2:8000/api');
  
  static final Dio _dio = Dio()..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Set base URL dynamically
          options.baseUrl = _baseUrl;
          options.connectTimeout = const Duration(seconds: 30);
          options.receiveTimeout = const Duration(seconds: 30);
          options.headers['Accept'] = 'application/json';
          options.headers['Content-Type'] = 'application/json';
          
          final token = await getToken();
          print('🔒 Interceptor: Making request to ${options.path}');
          print('🔒 Interceptor: Token available: ${token != null}');
          
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('🔒 Interceptor: Authorization header set');
          } else {
            print('🔒 Interceptor: No token, skipping Authorization header');
          }
          
          // Add device ID for security
          final deviceId = await SecureStorageService.getDeviceId();
          options.headers['X-Device-ID'] = deviceId;
          
          handler.next(options);
        },
        onError: (error, handler) async {
          print('🔒 Interceptor: Request error: ${error.message}');
          if (error.response != null) {
            print('🔒 Interceptor: Response status: ${error.response?.statusCode}');
            print('🔒 Interceptor: Response data: ${error.response?.data}');
          }
          
          // Handle 401 Unauthorized - token expired
          if (error.response?.statusCode == 401) {
            print('🔒 Interceptor: 401 Unauthorized - token may be expired');
            await clearToken();
          }
          
          handler.next(error);
        },
      ),
    );

  static Dio get dio => _dio;

  static Future<String?> getToken() async {
    final token = await SecureStorageService.getToken();
    print('🔐 getToken: ${token != null ? "Token found" : "No token"}');
    return token;
  }

  static Future<void> saveToken(String token, {int expiresIn = 3600}) async {
    print('🔐 saveToken called with token: ${token.substring(0, 20)}...');
    
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    await SecureStorageService.saveToken(
      token: token,
      expiresAt: expiresAt,
    );
    
    print('🔐 Token saved securely with expiry: $expiresAt');
    
    // Verify it was saved
    final saved = await SecureStorageService.getToken();
    print('🔐 Verification - Token retrieved: ${saved != null ? "YES" : "NO"}');
  }

  static Future<void> clearToken() async {
    await SecureStorageService.clearAuth();
    print('🔐 Token cleared from secure storage');
  }

  /// Login and return token
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    print('🌐 API: Calling POST /v1/auth/login');
    print('🌐 API: Email: $email');
    
    try {
      final deviceId = await SecureStorageService.getDeviceId();
      
      final res = await _dio.post('/v1/auth/login', data: {
        'email': email,
        'password': password,
        'device_id': deviceId,
      });
      
      print('🌐 API: Login response status: ${res.statusCode}');
      print('🌐 API: Login response data: ${res.data}');
      
      return res.data as Map<String, dynamic>;
    } catch (e) {
      print('🌐 API: Login request failed: $e');
      rethrow;
    }
  }

  /// GET /v1/orders — scoped by role (driver sees only their orders)
  static Future<List<dynamic>> getOrders({
    String? status,
    int perPage = 30,
  }) async {
    final params = <String, dynamic>{'per_page': perPage};
    if (status != null) params['status'] = status;
    final res = await _dio.get('/v1/orders', queryParameters: params);
    return (res.data['data'] as List<dynamic>?) ?? [];
  }

  /// GET /v1/orders/{id} — get single order by ID
  static Future<Map<String, dynamic>?> getOrderById(int orderId) async {
    try {
      final res = await _dio.get('/v1/orders/$orderId');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        // Check if response has 'data' wrapper
        if (data.containsKey('data')) {
          return data['data'] as Map<String, dynamic>?;
        }
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching order by ID: $e');
      return null;
    }
  }

  /// PATCH /v1/orders/{id}/status
  static Future<Map<String, dynamic>> updateOrderStatus(
      int orderId, String status) async {
    final res = await _dio.patch(
      '/v1/orders/$orderId/status',
      data: {'status': status},
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /v1/orders/{id}/upload-proof
  static Future<Map<String, dynamic>> uploadProofImages(
      int orderId, List<String> imagePaths) async {
    final formData = FormData();
    
    for (var i = 0; i < imagePaths.length; i++) {
      try {
        final file = await MultipartFile.fromFile(
          imagePaths[i],
          filename: 'proof_$i.jpg',
        );
        formData.files.add(MapEntry('images[]', file));
      } catch (e) {
        // For web, use fromBytes instead
        print('Using bytes for web upload: $e');
        // This will be handled by the caller
        rethrow;
      }
    }
    
    final res = await _dio.post(
      '/v1/orders/$orderId/upload-proof',
      data: formData,
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /v1/orders/{id}/upload-proof (Web version)
  static Future<Map<String, dynamic>> uploadProofImagesWeb(
      int orderId, List<XFile> imageFiles) async {
    final formData = FormData();
    
    for (var i = 0; i < imageFiles.length; i++) {
      final bytes = await imageFiles[i].readAsBytes();
      final file = MultipartFile.fromBytes(
        bytes,
        filename: imageFiles[i].name,
      );
      formData.files.add(MapEntry('images[]', file));
    }
    
    final res = await _dio.post(
      '/v1/orders/$orderId/upload-proof',
      data: formData,
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /v1/tracking/driver/location - Update driver location for tracking
  static Future<void> updateDriverLocation(
      int driverProfileId, double lat, double lng) async {
    try {
      await _dio.post(
        '/v1/tracking/driver/location',
        data: {
          'driver_id': driverProfileId,
          'latitude': lat,
          'longitude': lng,
          'status': 'online',
        },
      );
      print('✅ Driver location updated: $lat, $lng');
    } catch (e) {
      print('❌ Error updating driver location: $e');
      rethrow;
    }
  }

  /// GET /v1/tracking/order/{id}/live - Get live order tracking data
  static Future<Map<String, dynamic>?> getLiveOrderTracking(int orderId) async {
    try {
      final res = await _dio.get('/v1/tracking/order/$orderId/live');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error getting live tracking: $e');
      return null;
    }
  }

  /// GET /v1/tracking/order/{id}/eta - Get order ETA
  static Future<Map<String, dynamic>?> getOrderETA(int orderId) async {
    try {
      final res = await _dio.get('/v1/tracking/order/$orderId/eta');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error getting ETA: $e');
      return null;
    }
  }

  /// GET /v1/tracking/route - Get route polyline between two points
  static Future<Map<String, dynamic>?> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final res = await _dio.get('/v1/tracking/route', queryParameters: {
        'origin_lat': originLat,
        'origin_lng': originLng,
        'dest_lat': destLat,
        'dest_lng': destLng,
      });
      return res.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error getting route: $e');
      return null;
    }
  }

  /// GET /v1/auth/me
  static Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/v1/auth/me');
    return res.data as Map<String, dynamic>;
  }

  /// POST /v1/auth/me/profile-picture - Upload profile picture (from XFile for web compatibility)
  static Future<Map<String, dynamic>> uploadProfilePictureFromXFile(XFile imageFile) async {
    final formData = FormData();
    
    try {
      final bytes = await imageFile.readAsBytes();
      final file = MultipartFile.fromBytes(
        bytes,
        filename: imageFile.name,
      );
      formData.files.add(MapEntry('profile_picture', file));
    } catch (e) {
      print('Error creating multipart file: $e');
      rethrow;
    }
    
    final res = await _dio.post(
      '/v1/auth/me/profile-picture',
      data: formData,
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /v1/auth/me/profile-picture - Upload profile picture (legacy, for mobile)
  static Future<Map<String, dynamic>> uploadProfilePicture(String imagePath) async {
    final formData = FormData();
    
    try {
      // For web, we need to use XFile and read bytes
      // The imagePath is actually from XFile.path which works differently on web
      final file = MultipartFile.fromBytes(
        await XFile(imagePath).readAsBytes(),
        filename: 'profile_picture.jpg',
      );
      formData.files.add(MapEntry('profile_picture', file));
    } catch (e) {
      print('Error creating multipart file: $e');
      rethrow;
    }
    
    final res = await _dio.post(
      '/v1/auth/me/profile-picture',
      data: formData,
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /v1/auth/logout
  static Future<void> logout() async {
    try {
      await _dio.post('/v1/auth/logout');
    } catch (_) {}
    await clearToken();
  }

  /// GET /v1/driver/missions - Get driver missions
  static Future<Map<String, dynamic>> getDriverMissions() async {
    final res = await _dio.get('/v1/driver/missions');
    return res.data as Map<String, dynamic>;
  }

  /// POST /v1/driver/missions/{id}/claim - Claim mission reward
  static Future<Map<String, dynamic>> claimMissionReward(int missionId) async {
    final res = await _dio.post('/v1/driver/missions/$missionId/claim');
    return res.data as Map<String, dynamic>;
  }

  static String extractError(dynamic e) {
    if (e is DioException) {
      final msg = e.response?.data?['message'];
      if (msg is String) return msg;
      return e.message ?? 'Network error';
    }
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }
}
