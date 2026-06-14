import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../di/injection.dart';
import '../network/dio_client.dart';

/// Missions, vouchers, loyalty, referrals, security, and device registration.
class BenefitsApi {
  BenefitsApi._();

  static Dio get _dio => getIt<DioClient>().dio;

  static Future<Map<String, dynamic>> getDriverMissions() async {
    final res = await _dio.get('/v1/driver/missions');
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> claimMissionReward(int missionId) async {
    final res = await _dio.post('/v1/driver/missions/$missionId/claim');
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getMerchantMissions() async {
    final res = await _dio.get('/v1/merchant/missions');
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> claimMerchantMissionReward(
    int missionId,
  ) async {
    final res = await _dio.post('/v1/merchant/missions/$missionId/claim');
    return res.data as Map<String, dynamic>;
  }

  /// Registers the authenticated user's FCM token with the backend.
  static Future<void> registerPushToken({
    required String fcmToken,
    required String platform,
  }) async {
    await _dio.post(ApiConstants.authFcmToken, data: {
      'fcm_token': fcmToken,
      'platform': platform,
      'app': 'lesgo_rider',
    });
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

  static Future<void> trackAnalyticsEvent(
    String eventType, {
    Map<String, dynamic>? properties,
  }) async {
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
}
