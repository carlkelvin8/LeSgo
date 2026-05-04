import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    print('❌ merchantProfileProvider - No partner_id available');
    return null;
  }
  
  print('📋 merchantProfileProvider - Using partner_id: $partnerId');
  
  try {
    final dataSource = ref.read(merchantDataSourceProvider);
    final profile = await dataSource.getPartnerProfile(partnerId);
    print('✅ Loaded merchant profile: ${profile.name}');
    return profile;
  } catch (e) {
    print('❌ Error loading merchant profile: $e');
    rethrow;
  }
});
