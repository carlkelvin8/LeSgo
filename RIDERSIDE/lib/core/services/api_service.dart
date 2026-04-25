import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

const String _baseUrl = 'http://127.0.0.1:8000/api';
const String _tokenKey = 'rider_token';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );

  static Dio get dio => _dio;

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Login and return token
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await _dio.post('/v1/auth/login', data: {
      'email': email,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
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

  /// PATCH /v1/drivers/{id}/location
  static Future<void> updateDriverLocation(
      int driverProfileId, double lat, double lng) async {
    await _dio.patch(
      '/v1/drivers/$driverProfileId/location',
      data: {'last_latitude': lat, 'last_longitude': lng},
    );
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
