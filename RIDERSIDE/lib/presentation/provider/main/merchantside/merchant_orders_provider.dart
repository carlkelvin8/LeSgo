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

/// Provider for all merchant orders from API
final merchantOrdersProvider = FutureProvider.autoDispose<List<OrderDto>>((ref) async {
  // Get partner_id from auth state
  final authState = ref.watch(riderAuthProvider);
  final partnerId = authState.user?.partnerId;
  
  if (partnerId == null) {
    print('❌ merchantOrdersProvider - No partner_id available');
    return [];
  }
  
  print('📋 merchantOrdersProvider - Fetching ALL orders for partner: $partnerId');
  
  try {
    final dataSource = ref.read(merchantDataSourceProvider);
    // Fetch ALL orders without status filter
    final orders = await dataSource.getPartnerOrders(partnerId);
    print('✅ Loaded ${orders.length} total orders for partner $partnerId');
    return orders;
  } catch (e) {
    print('❌ Error loading merchant orders: $e');
    rethrow;
  }
});

/// Provider for filtered orders (local filtering)
final filteredMerchantOrdersProvider = Provider<List<OrderDto>>((ref) {
  final ordersAsync = ref.watch(merchantOrdersProvider);
  final filter = ref.watch(selectedMerchantOrderFilterProvider);
  
  return ordersAsync.when(
    data: (orders) {
      if (filter == MerchantOrderFilter.all) {
        return orders;
      }
      
      return orders.where((order) {
        final status = order.status.toLowerCase();
        switch (filter) {
          case MerchantOrderFilter.pending:
            return status == 'pending';
          case MerchantOrderFilter.pickUp:
            // For Pick Up should include both searching_driver (preparing) and accepted (driver assigned)
            return status == 'searching_driver' || status == 'accepted';
          case MerchantOrderFilter.forDelivery:
            return status == 'picked_up' || status == 'in_progress' || status == 'driver_arrived_at_pickup';
          case MerchantOrderFilter.delivered:
            return status == 'completed';
          default:
            return true;
        }
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final merchantOrderActionProvider = Provider((ref) {
  return MerchantOrderActionNotifier(ref);
});

class MerchantOrderActionNotifier {
  final Ref ref;
  MerchantOrderActionNotifier(this.ref);

  Future<void> acceptOrder(int orderId) async {
    try {
      final dataSource = ref.read(merchantDataSourceProvider);
      // For merchants, accepting an order means transitioning from 'pending' to 'searching_driver'
      await dataSource.updateOrderStatus(orderId, 'searching_driver');
      // Refresh the orders list
      ref.invalidate(merchantOrdersProvider);
    } catch (e) {
      rethrow;
    }
  }
}
