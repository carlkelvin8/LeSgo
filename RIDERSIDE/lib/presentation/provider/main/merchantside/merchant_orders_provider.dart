import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/merchant_order_ops_utils.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';
import '../../auth/rider_auth_provider.dart';
import 'merchant_prep_timer_provider.dart';
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

final merchantOrdersProvider =
    FutureProvider.autoDispose<List<OrderDto>>((ref) async {
  final authState = ref.watch(riderAuthProvider);
  final partnerId = authState.user?.partnerId;

  if (partnerId == null) {
    return [];
  }

  final dataSource = ref.read(merchantDataSourceProvider);
  return dataSource.getPartnerOrders(partnerId);
});

final merchantOrderDetailProvider =
    FutureProvider.autoDispose.family<OrderDto, int>((ref, orderId) async {
  final dataSource = ref.read(merchantDataSourceProvider);
  return dataSource.getOrderById(orderId);
});

final merchantPendingOrderCountProvider = Provider<int>((ref) {
  final ordersAsync = ref.watch(merchantOrdersProvider);
  return ordersAsync.maybeWhen(
    data: (orders) =>
        orders.where((order) => MerchantOrderOpsUtils.isPending(order.status)).length,
    orElse: () => 0,
  );
});

final filteredMerchantOrdersProvider = Provider<List<OrderDto>>((ref) {
  final ordersAsync = ref.watch(merchantOrdersProvider);
  final filter = ref.watch(selectedMerchantOrderFilterProvider);

  return ordersAsync.when(
    data: (orders) => _filterOrders(orders, filter),
    loading: () => [],
    error: (_, __) => [],
  );
});

List<OrderDto> _filterOrders(List<OrderDto> orders, MerchantOrderFilter filter) {
  if (filter == MerchantOrderFilter.all) return orders;

  return orders.where((order) {
    final status = order.status.toLowerCase();
    switch (filter) {
      case MerchantOrderFilter.pending:
        return status == 'pending';
      case MerchantOrderFilter.pickUp:
        // Orders waiting for pickup (after driver accepted, before pickup)
        return status == 'searching_driver' || status == 'accepted';
      case MerchantOrderFilter.forDelivery:
        // Orders picked up by driver (in transit or ready)
        return status == 'ready_for_pickup' ||
            status == 'picked_up' ||
            status == 'in_progress' ||
            status == 'driver_arrived_at_pickup';
      case MerchantOrderFilter.delivered:
        return status == 'completed';
      default:
        return true;
    }
  }).toList();
}

final merchantOrderActionProvider = Provider((ref) {
  return MerchantOrderActionNotifier(ref);
});

class MerchantOrderActionNotifier {
  final Ref ref;
  MerchantOrderActionNotifier(this.ref);

  Future<void> _refresh() async {
    ref.invalidate(merchantOrdersProvider);
  }

  Future<void> acceptOrder(int orderId) async {
    final dataSource = ref.read(merchantDataSourceProvider);
    await dataSource.updateOrderStatus(orderId, 'searching_driver');
    await ref.read(merchantPrepTimerProvider.notifier).start(orderId);
    await _refresh();
  }

  Future<void> rejectOrder(int orderId, String reason) async {
    final dataSource = ref.read(merchantDataSourceProvider);
    await dataSource.updateOrderStatus(
      orderId,
      'cancelled',
      cancelReason: reason,
    );
    await ref.read(merchantPrepTimerProvider.notifier).remove(orderId);
    await _refresh();
  }

  Future<void> cancelOrder(int orderId, String reason) async {
    final dataSource = ref.read(merchantDataSourceProvider);
    await dataSource.updateOrderStatus(
      orderId,
      'cancelled',
      cancelReason: reason,
    );
    await ref.read(merchantPrepTimerProvider.notifier).remove(orderId);
    await _refresh();
  }

  Future<void> markReadyForPickup(int orderId) async {
    final dataSource = ref.read(merchantDataSourceProvider);
    await dataSource.updateOrderStatus(orderId, 'ready_for_pickup');
    await ref.read(merchantPrepTimerProvider.notifier).remove(orderId);
    await _refresh();
  }
}
