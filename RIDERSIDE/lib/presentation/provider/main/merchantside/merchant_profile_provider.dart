import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../data/data_source/merchant_remote_datasource.dart';
import '../../../../data/data_source/dto/merchant/partner_dto.dart';
import '../../auth/rider_auth_provider.dart';

/// Provider for merchant data source
final merchantDataSourceProvider = Provider((ref) => MerchantRemoteDataSource());

/// Provider for merchant profile data
final merchantProfileProvider = FutureProvider.autoDispose<PartnerDto?>((ref) async {
  // Get partner_id from auth state
  final authState = ref.watch(riderAuthProvider);
  final partnerId = authState.user?.partnerId;
  
  if (partnerId == null) {
    AppLogger.warn('merchantProfileProvider - No partner_id available');
    return null;
  }
  
  AppLogger.debug('📋 merchantProfileProvider - Using partner_id: $partnerId');
  
  try {
    final dataSource = ref.read(merchantDataSourceProvider);
    final profile = await dataSource.getPartnerProfile(partnerId);
    AppLogger.debug('✅ Loaded merchant profile: ${profile.name}');
    return profile;
  } catch (e) {
    AppLogger.error('Error loading merchant profile', e);
    rethrow;
  }
});

/// Referral code is stored on the user account, not the partner record.
final merchantReferralCodeProvider = FutureProvider.autoDispose<String>((ref) async {
  ref.watch(riderAuthProvider);

  try {
    final dashboard = await ApiService.getReferralDashboard();
    final code = dashboard['referral_code']?.toString().trim();
    if (code != null && code.isNotEmpty) return code;
  } catch (e) {
    AppLogger.warn('Referral dashboard fetch failed: $e');
  }

  try {
    final data = await ApiService.getMe();
    final user = data['user'] ?? data['data'] ?? data;
    if (user is Map<String, dynamic>) {
      final code = user['referral_code']?.toString().trim();
      if (code != null && code.isNotEmpty) return code;
    }
  } catch (e) {
    AppLogger.warn('getMe referral fetch failed: $e');
  }

  return '';
});
