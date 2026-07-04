import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/dto/merchant/menu_item_dto.dart';
import 'merchant_menu_provider.dart';

/// Provider that watches menu items and filters items with low stock (≤ 5).
final merchantLowStockItemsProvider = Provider<List<MenuItemDto>>((ref) {
  final menuItemsAsync = ref.watch(merchantMenuItemsProvider);

  return menuItemsAsync.when(
    data: (items) {
      return items
          .where((item) =>
              item.stockCount != null && item.stockCount! <= 5)
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
