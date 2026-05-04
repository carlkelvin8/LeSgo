import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';
import '../../auth/rider_auth_provider.dart';
import 'merchant_profile_provider.dart';

enum MerchantOrderFilter { all, pending, pickUp, forDelivery, delivered }

extension MerchantOrderFilterX on MerchantOrderFilter {
  String get label {
    switch (this) {
      case MerchantOrderFilter.all:
        return 'All';
      case MerchantOrderFilter.pending:
        return 'Pending';
      case MerchantOrderFilter.pickUp:
        return 'For Pick Up';
      case MerchantOrderFilter.forDelivery:
        return 'For Delivery';
      case MerchantOrderFilter.delivered:
        return 'Delivered';
    }
  }
  
  /// Map filter to API status
  String? get apiStatus {
    switch (this) {
      case MerchantOrderFilter.all:
        return null;
      case MerchantOrderFilter.pending:
        return 'pending';
      case MerchantOrderFilter.pickUp:
        return 'accepted';
      case MerchantOrderFilter.forDelivery:
        return 'picked_up';
      case MerchantOrderFilter.delivered:
        return 'completed';
    }
  }
}

final merchantOrderFiltersProvider = Provider<List<MerchantOrderFilter>>((ref) {
  return MerchantOrderFilter.values;
});

final selectedMerchantOrderFilterProvider =
    StateProvider<MerchantOrderFilter>((ref) {
  return MerchantOrderFilter.all;
});

/// Provider for merchant orders from API
final merchantOrdersProvider = FutureProvider.autoDispose<List<OrderDto>>((ref) async {
  // Get partner_id from auth state
  final authState = ref.watch(riderAuthProvider);
  final partnerId = authState.user?.partnerId;
  final filter = ref.watch(selectedMerchantOrderFilterProvider);
  
  if (partnerId == null) {
    print('❌ merchantOrdersProvider - No partner_id available');
    return [];
  }
  
  print('📋 merchantOrdersProvider - Using partner_id: $partnerId');
  
  try {
    final dataSource = ref.read(merchantDataSourceProvider);
    final orders = await dataSource.getPartnerOrders(partnerId, status: filter.apiStatus);
    print('✅ Loaded ${orders.length} orders for partner $partnerId (filter: ${filter.label})');
    return orders;
  } catch (e) {
    print('❌ Error loading merchant orders: $e');
    rethrow;
  }
});

/// Provider for filtered orders (for backward compatibility with UI)
final filteredMerchantOrdersProvider = Provider<List<OrderDto>>((ref) {
  final ordersAsync = ref.watch(merchantOrdersProvider);
  
  return ordersAsync.when(
    data: (orders) => orders,
    loading: () => [],
    error: (_, __) => [],
  );
});
