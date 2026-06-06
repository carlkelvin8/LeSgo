import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../network/auth_token_interceptor.dart';
import '../utils/api_error_mapper.dart';
import 'secure_storage_service.dart';

class ApiService {
  static String get _baseUrl => ApiConstants.baseUrl;

  static Dio? _dioInstance;

  static Dio get _dio {
    final existing = _dioInstance;
    if (existing != null) return existing;

    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    dio.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final deviceId = await SecureStorageService.getDeviceId();
          options.headers['X-Device-ID'] = deviceId;
          handler.next(options);
        },
      ),
      AuthTokenInterceptor(dio),
    ]);
    _dioInstance = dio;
    return dio;
  }

  static Dio get dio => _dio;

  static Future<String?> getToken() async {
    final token = await SecureStorageService.getToken();
    print('🔐 getToken: ${token != null ? "Token found" : "No token"}');
    return token;
  }

  static Future<void> saveToken(
    String token, {
    int expiresIn = 3600,
    String? refreshToken,
    int? userId,
  }) async {
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    await SecureStorageService.saveToken(
      token: token,
      expiresAt: expiresAt,
      refreshToken: refreshToken,
      userId: userId,
    );
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
    int driverProfileId,
    double lat,
    double lng, {
    String status = 'online',
    int? orderId,
  }) async {
    try {
      await _dio.post(
        '/v1/tracking/driver/location',
        data: {
          'driver_id': driverProfileId,
          'latitude': lat,
          'longitude': lng,
          'status': status,
          if (orderId != null) 'order_id': orderId,
        },
      );
    } catch (e) {
      print('❌ Error updating driver location: $e');
      rethrow;
    }
  }

  /// PATCH /v1/drivers/{id} - Update driver availability
  static Future<void> updateDriverAvailability(
    int driverProfileId,
    bool isAvailable,
  ) async {
    try {
      await _dio.patch('/v1/drivers/$driverProfileId', data: {
        'is_available': isAvailable,
      });
    } catch (e) {
      print('❌ Error updating driver availability: $e');
      rethrow;
    }
  }

  /// POST /v1/drivers/{id}/duty-attendance - Upload on-duty attendance photo
  static Future<Map<String, dynamic>> submitDutyAttendance(
    int driverProfileId,
    XFile photo, {
    double? latitude,
    double? longitude,
  }) async {
    final bytes = await photo.readAsBytes();
    final formData = FormData.fromMap({
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'photo': MultipartFile.fromBytes(
        bytes,
        filename: photo.name.isNotEmpty ? photo.name : 'duty_attendance.jpg',
      ),
    });

    final res = await _dio.post(
      '/v1/drivers/$driverProfileId/duty-attendance',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = res.data['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return Map<String, dynamic>.from(res.data as Map? ?? {});
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

  /// PUT /v1/auth/me - Update user profile
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.put('/v1/auth/me', data: data);
    return res.data as Map<String, dynamic>;
  }

  /// POST /v1/auth/me/profile-picture - Upload profile picture (from XFile for web compatibility)
  static Future<Map<String, dynamic>> uploadProfilePictureFromXFile(XFile imageFile) async {
    try {
      return await _uploadProfilePictureViaMedia(imageFile);
    } catch (mediaError) {
      if (kDebugMode) {
        print('Profile upload via media failed, trying direct endpoint: $mediaError');
      }
      return _uploadProfilePictureDirect(imageFile);
    }
  }

  static Future<Map<String, dynamic>> _uploadProfilePictureViaMedia(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final filename = imageFile.name.isNotEmpty ? imageFile.name : 'profile.jpg';
    final formData = FormData.fromMap({'context': 'profile'});
    formData.files.add(MapEntry(
      'file',
      MultipartFile.fromBytes(bytes, filename: filename),
    ));

    final uploadRes = await _dio.post(
      ApiConstants.mediaUpload,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final uploadData = uploadRes.data['data'] ?? uploadRes.data;
    if (uploadData is! Map) {
      throw Exception('Media upload returned unexpected response');
    }
    final publicUrl = uploadData['url']?.toString();
    final storedPath = uploadData['path']?.toString();
    if (publicUrl == null || publicUrl.isEmpty) {
      throw Exception('Media upload did not return a URL');
    }

    final payload = <String, dynamic>{'profile_photo_url': publicUrl};
    if (storedPath != null && storedPath.isNotEmpty) {
      payload['profile_picture'] = storedPath;
    }

    return updateProfile(payload);
  }

  static Future<Map<String, dynamic>> _uploadProfilePictureDirect(XFile imageFile) async {
    final formData = FormData();

    try {
      final bytes = await imageFile.readAsBytes();
      final file = MultipartFile.fromBytes(
        bytes,
        filename: imageFile.name.isNotEmpty ? imageFile.name : 'profile.jpg',
      );
      formData.files.add(MapEntry('profile_picture', file));
    } catch (e) {
      print('Error creating multipart file: $e');
      rethrow;
    }

    final res = await _dio.post(
      '/v1/auth/me/profile-picture',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /v1/auth/me/profile-picture - Upload profile picture (legacy, for mobile)
  static Future<Map<String, dynamic>> uploadProfilePicture(String imagePath) async {
    try {
      return await _uploadProfilePictureViaMedia(XFile(imagePath));
    } catch (mediaError) {
      if (kDebugMode) {
        print('Profile upload via media failed, trying direct endpoint: $mediaError');
      }
    }

    final formData = FormData();

    try {
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
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /v1/auth/logout — always clears local auth even if the API fails.
  static Future<void> logout() async {
    String? token;
    try {
      token = await getToken();
    } catch (_) {}

    await clearToken();

    if (token == null || token.isEmpty) return;

    try {
      await _dio
          .post(
            '/v1/auth/logout',
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
            ),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  /// POST /v1/auth/change-password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String password,
  }) async {
    final res = await _dio.post(
      ApiConstants.authChangePassword,
      data: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': password,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /v1/auth/account/deactivate
  static Future<Map<String, dynamic>> deactivateAccount({
    required String password,
    String? reason,
  }) async {
    final res = await _dio.post(
      ApiConstants.authDeactivateAccount,
      data: {
        'password': password,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return res.data as Map<String, dynamic>;
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

  /// GET /v1/merchant/missions - Get merchant missions
  static Future<Map<String, dynamic>> getMerchantMissions() async {
    final res = await _dio.get('/v1/merchant/missions');
    return res.data as Map<String, dynamic>;
  }

  /// POST /v1/merchant/missions/{id}/claim - Claim merchant mission reward
  static Future<Map<String, dynamic>> claimMerchantMissionReward(int missionId) async {
    final res = await _dio.post('/v1/merchant/missions/$missionId/claim');
    return res.data as Map<String, dynamic>;
  }

  /// POST /v1/orders — create a new order
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    final res = await _dio.post('/v1/orders', data: data);
    return res.data as Map<String, dynamic>;
  }

  /// Register device for push notifications
  static Future<void> registerPushDevice({
    required String deviceToken,
    required String platform,
  }) async {
    try {
      await _dio.post(ApiConstants.deviceRegister, data: {
        'fcm_token': deviceToken,
        'token': deviceToken,
        'platform': platform,
        'app': 'lesgo_rider',
      });
    } catch (_) {}
  }

  static Future<void> registerFcmToken(String token) async {
    try {
      await _dio.post(ApiConstants.authFcmToken, data: {'fcm_token': token});
    } catch (_) {}
  }

  static Future<List<dynamic>> getFaqArticles() async {
    final res = await _dio.get(ApiConstants.faqArticles);
    final data = res.data['data'];
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is List) return data;
    return [];
  }

  static Future<List<dynamic>> getAvailableVouchers() async {
    final res = await _dio.get(ApiConstants.vouchersAvailable);
    final data = res.data['data'];
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return [];
  }

  static Future<List<dynamic>> getLoyaltyRewards() async {
    final res = await _dio.get(ApiConstants.loyaltyRewards);
    final data = res.data['data'];
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return [];
  }

  static Future<Map<String, dynamic>> getReferralDashboard() async {
    final res = await _dio.get(ApiConstants.referralDashboard);
    final data = res.data['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  static Future<Map<String, dynamic>> getSecurityDashboard() async {
    final res = await _dio.get(ApiConstants.securityDashboard);
    final data = res.data['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  static Future<void> trackAnalyticsEvent(String eventType,
      {Map<String, dynamic>? properties}) async {
    try {
      await _dio.post(ApiConstants.analyticsTrackEvent, data: {
        'event_type': eventType,
        if (properties != null) 'properties': properties,
      });
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> claimVoucher(String voucherCode) async {
    final res = await _dio.post(
      ApiConstants.vouchersClaim,
      data: {'voucher_code': voucherCode},
    );
    return Map<String, dynamic>.from(res.data['data'] as Map? ?? {});
  }

  static Future<Map<String, dynamic>> redeemLoyaltyReward(int rewardId) async {
    final res = await _dio.post(ApiConstants.loyaltyRedeem(rewardId));
    return Map<String, dynamic>.from(res.data['data'] as Map? ?? {});
  }

  static Future<Map<String, dynamic>> setup2fa() async {
    final res = await _dio.post(ApiConstants.security2faSetup);
    return Map<String, dynamic>.from(res.data['data'] as Map? ?? {});
  }

  static Future<Map<String, dynamic>> verify2fa(String code) async {
    final res = await _dio.post(
      ApiConstants.security2faVerify,
      data: {'code': code},
    );
    return Map<String, dynamic>.from(res.data['data'] as Map? ?? {});
  }

  static Future<void> disable2fa() async {
    await _dio.post(ApiConstants.security2faDisable);
  }

  static Future<List<dynamic>> getMyDocuments({int perPage = 30}) async {
    final res = await _dio.get(
      ApiConstants.documentsMy,
      queryParameters: {'per_page': perPage},
    );
    return _parseListData(res.data['data']);
  }

  static Future<List<dynamic>> getDocumentTypes() async {
    final res = await _dio.get(ApiConstants.documentsTypes);
    final data = res.data['data'];
    if (data is List) return data;
    return [];
  }

  static Future<Map<String, dynamic>> getDocumentVerificationStatus() async {
    final res = await _dio.get(ApiConstants.documentsVerificationStatus);
    return Map<String, dynamic>.from(res.data['data'] as Map? ?? {});
  }

  static Future<Map<String, dynamic>> submitDocument({
    required String documentType,
    required String documentNumber,
    required List<String> documentUrls,
    String? description,
  }) async {
    final res = await _dio.post(
      ApiConstants.documentsSubmit,
      data: {
        'document_type': documentType,
        'document_number': documentNumber,
        'document_urls': documentUrls,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return Map<String, dynamic>.from(res.data['data'] as Map? ?? {});
  }

  static Future<String> uploadDocumentFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'context': 'document',
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.name.isNotEmpty ? file.name : 'document.jpg',
      ),
    });
    final res = await _dio.post(ApiConstants.documentsUpload, data: formData);
    final data = res.data['data'] as Map<String, dynamic>;
    return data['url']?.toString() ?? '';
  }

  static Future<List<String>> uploadDocumentFiles(List<XFile> files) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadDocumentFile(file);
      if (url.isNotEmpty) urls.add(url);
    }
    return urls;
  }

  static List<dynamic> _parseListData(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return [];
  }

  static String extractError(dynamic e) {
    return ApiErrorMapper.message(e);
  }
}
