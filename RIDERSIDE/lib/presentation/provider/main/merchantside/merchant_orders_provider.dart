import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/helpers/fakedata.dart';

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
}

final merchantOrderFiltersProvider = Provider<List<MerchantOrderFilter>>((ref) {
  return MerchantOrderFilter.values;
});

final selectedMerchantOrderFilterProvider =
    StateProvider<MerchantOrderFilter>((ref) {
  return MerchantOrderFilter.all;
});

final merchantOrdersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  const statusCycle = ['accept', 'pickup', 'delivery', 'delivered'];

  return merchantFoodMenuItems.asMap().entries.map((entry) {
    final index = entry.key;
    final item = entry.value;
    final statusType = statusCycle[index % statusCycle.length];
    final statusLabel = switch (statusType) {
      'accept' => 'Accept',
      'pickup' => 'For Pick Up',
      'delivery' => 'For Delivery',
      'delivered' => 'Delivered',
      _ => 'Accept',
    };

    return <String, dynamic>{
      'orderId': '#53472${920 + index}',
      'itemName': item['name']!,
      'price': item['price']!,
      'customerName': 'Juan Dela Cruz',
      'address': 'Libertad, Claveria, Cagayan',
      'statusType': statusType,
      'statusLabel': statusLabel,
    };
  }).toList();
});

final filteredMerchantOrdersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final selected = ref.watch(selectedMerchantOrderFilterProvider);
  final orders = ref.watch(merchantOrdersProvider);

  if (selected == MerchantOrderFilter.all) {
    return orders;
  }

  final targetStatusType = switch (selected) {
    MerchantOrderFilter.pending => 'accept',
    MerchantOrderFilter.pickUp => 'pickup',
    MerchantOrderFilter.forDelivery => 'delivery',
    MerchantOrderFilter.delivered => 'delivered',
    MerchantOrderFilter.all => '',
  };

  return orders
      .where((order) => order['statusType'] == targetStatusType)
      .toList();
});
