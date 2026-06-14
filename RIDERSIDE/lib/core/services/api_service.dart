import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/api_constants.dart';
import '../di/injection.dart';
import '../network/dio_client.dart';
import '../utils/api_error_mapper.dart';
import '../utils/app_logger.dart';
import 'benefits_api.dart';
import 'orders_api.dart';
import 'profile_api.dart';
import 'secure_storage_service.dart';
import 'tracking_api.dart';

/// HTTP facade — delegates to feature APIs backed by the shared [DioClient].
class ApiService {
  static Dio get dio => getIt<DioClient>().dio;

  static Dio get _dio => dio;

  // ── Auth & session ─────────────────────────────────────────────────────────

  static Future<String?> getToken() async {
    final token = await SecureStorageService.getToken();
    AppLogger.auth('getToken: ${token != null ? "present" : "absent"}');
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
    AppLogger.auth('Auth tokens cleared from secure storage');
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    AppLogger.network('POST', '/v1/auth/login');
    try {
      final deviceId = await SecureStorageService.getDeviceId();
      final res = await _dio.post('/v1/auth/login', data: {
        'email': email,
        'password': password,
        'device_id': deviceId,
      });
      AppLogger.network('POST', '/v1/auth/login', statusCode: res.statusCode);
      return res.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Login request failed', e);
      rethrow;
    }
  }

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
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

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

  static String extractError(dynamic e) => ApiErrorMapper.message(e);

  // ── Orders ─────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getOrders({
    String? status,
    int perPage = 30,
  }) =>
      OrdersApi.getOrders(status: status, perPage: perPage);

  static Future<Map<String, dynamic>?> getOrderById(int orderId) =>
      OrdersApi.getOrderById(orderId);

  static Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String status, {
    String? cancelReason,
  }) =>
      OrdersApi.updateOrderStatus(
        orderId,
        status,
        cancelReason: cancelReason,
      );

  static Future<Map<String, dynamic>> uploadProofImages(
    int orderId,
    List<String> imagePaths, {
    double? latitude,
    double? longitude,
    bool firstItemProof = false,
  }) =>
      OrdersApi.uploadProofImages(
        orderId,
        imagePaths,
        latitude: latitude,
        longitude: longitude,
        firstItemProof: firstItemProof,
      );

  static Future<Map<String, dynamic>> uploadProofImagesWeb(
    int orderId,
    List<XFile> imageFiles, {
    double? latitude,
    double? longitude,
    bool firstItemProof = false,
  }) =>
      OrdersApi.uploadProofImagesWeb(
        orderId,
        imageFiles,
        latitude: latitude,
        longitude: longitude,
        firstItemProof: firstItemProof,
      );

  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) =>
      OrdersApi.createOrder(data);

  // ── Tracking & driver ────────────────────────────────────────────────────

  static Future<void> updateDriverLocation(
    int driverProfileId,
    double lat,
    double lng, {
    String status = 'online',
    int? orderId,
  }) =>
      TrackingApi.updateDriverLocation(
        driverProfileId,
        lat,
        lng,
        status: status,
        orderId: orderId,
      );

  static Future<void> updateDriverAvailability(
    int driverProfileId,
    bool isAvailable,
  ) =>
      TrackingApi.updateDriverAvailability(driverProfileId, isAvailable);

  static Future<Map<String, dynamic>> submitDutyAttendance(
    int driverProfileId,
    XFile photo, {
    double? latitude,
    double? longitude,
  }) =>
      TrackingApi.submitDutyAttendance(
        driverProfileId,
        photo,
        latitude: latitude,
        longitude: longitude,
      );

  static Future<Map<String, dynamic>?> getLiveOrderTracking(int orderId) =>
      TrackingApi.getLiveOrderTracking(orderId);

  static Future<Map<String, dynamic>?> getOrderETA(int orderId) =>
      TrackingApi.getOrderETA(orderId);

  static Future<Map<String, dynamic>?> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) =>
      TrackingApi.getRoute(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );

  // ── Profile & documents ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getMe() => ProfileApi.getMe();

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) =>
      ProfileApi.updateProfile(data);

  static Future<Map<String, dynamic>> uploadProfilePictureFromXFile(
    XFile imageFile,
  ) =>
      ProfileApi.uploadProfilePictureFromXFile(imageFile);

  static Future<Map<String, dynamic>> uploadProfilePicture(String imagePath) =>
      ProfileApi.uploadProfilePicture(imagePath);

  static Future<List<dynamic>> getMyDocuments({int perPage = 30}) =>
      ProfileApi.getMyDocuments(perPage: perPage);

  static Future<List<dynamic>> getDocumentTypes() =>
      ProfileApi.getDocumentTypes();

  static Future<Map<String, dynamic>> getDocumentVerificationStatus() =>
      ProfileApi.getDocumentVerificationStatus();

  static Future<Map<String, dynamic>> submitDocument({
    required String documentType,
    required String documentNumber,
    required List<String> documentUrls,
    String? description,
  }) =>
      ProfileApi.submitDocument(
        documentType: documentType,
        documentNumber: documentNumber,
        documentUrls: documentUrls,
        description: description,
      );

  static Future<String> uploadDocumentFile(XFile file) =>
      ProfileApi.uploadDocumentFile(file);

  static Future<List<String>> uploadDocumentFiles(List<XFile> files) =>
      ProfileApi.uploadDocumentFiles(files);

  // ── Benefits, missions, devices ────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDriverMissions() =>
      BenefitsApi.getDriverMissions();

  static Future<Map<String, dynamic>> claimMissionReward(int missionId) =>
      BenefitsApi.claimMissionReward(missionId);

  static Future<Map<String, dynamic>> getMerchantMissions() =>
      BenefitsApi.getMerchantMissions();

  static Future<Map<String, dynamic>> claimMerchantMissionReward(int missionId) =>
      BenefitsApi.claimMerchantMissionReward(missionId);

  static Future<void> registerPushToken({
    required String fcmToken,
    required String platform,
  }) =>
      BenefitsApi.registerPushToken(
        fcmToken: fcmToken,
        platform: platform,
      );

  static Future<List<dynamic>> getFaqArticles() => BenefitsApi.getFaqArticles();

  static Future<List<dynamic>> getAvailableVouchers() =>
      BenefitsApi.getAvailableVouchers();

  static Future<List<dynamic>> getLoyaltyRewards() =>
      BenefitsApi.getLoyaltyRewards();

  static Future<Map<String, dynamic>> getReferralDashboard() =>
      BenefitsApi.getReferralDashboard();

  static Future<Map<String, dynamic>> getSecurityDashboard() =>
      BenefitsApi.getSecurityDashboard();

  static Future<void> trackAnalyticsEvent(
    String eventType, {
    Map<String, dynamic>? properties,
  }) =>
      BenefitsApi.trackAnalyticsEvent(eventType, properties: properties);

  static Future<Map<String, dynamic>> claimVoucher(String voucherCode) =>
      BenefitsApi.claimVoucher(voucherCode);

  static Future<Map<String, dynamic>> redeemLoyaltyReward(int rewardId) =>
      BenefitsApi.redeemLoyaltyReward(rewardId);

  static Future<Map<String, dynamic>> setup2fa() => BenefitsApi.setup2fa();

  static Future<Map<String, dynamic>> verify2fa(String code) =>
      BenefitsApi.verify2fa(code);

  static Future<void> disable2fa() => BenefitsApi.disable2fa();
}
