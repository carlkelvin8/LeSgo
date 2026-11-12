import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/merchant_item_inventory_utils.dart';
import '../../../../data/data_source/dto/merchant/menu_item_dto.dart';
import 'merchant_menu_provider.dart';

/// Provider that watches menu items and filters items with low stock (≤ 5).
final merchantLowStockItemsProvider = Provider<List<MenuItemDto>>((ref) {
  final menuItemsAsync = ref.watch(merchantMenuItemsProvider);

  return menuItemsAsync.when(
    data: (items) {
      return items.where((item) {
        // Stock lives in options._inventory; the API does not send stock_count.
        final inventory = MenuItemInventory.fromMenuItem(item);
        return inventory.isLowStock || inventory.isSoldOut;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
