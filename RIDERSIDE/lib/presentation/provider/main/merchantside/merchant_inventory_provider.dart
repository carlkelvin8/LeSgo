import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/merchant_item_inventory_utils.dart';
import '../../../../data/data_source/dto/merchant/menu_item_dto.dart';
import '../../../../data/data_source/merchant_remote_datasource.dart';
import 'merchant_menu_provider.dart';
import 'merchant_profile_provider.dart';

enum MerchantInventoryFilter { all, inStock, lowStock, soldOut }

final merchantInventoryFilterProvider =
    StateProvider<MerchantInventoryFilter>((ref) {
  return MerchantInventoryFilter.all;
});

Future<void> updateMerchantItemStock(
  WidgetRef ref, {
  required MenuItemDto item,
  required int newStock,
}) async {
  final inventory = MenuItemInventory.fromMenuItem(item).copyWith(
    stock: newStock,
    trackStock: true,
    autoHideWhenEmpty: true,
  );

  final liveOnMenu = item.isAvailable || !inventory.isSoldOut;
  final resolvedAvailability = inventory.resolveAvailability(
    liveOnMenu: liveOnMenu,
  );

  final options = mergeInventoryIntoOptions(item.options, inventory);

  final dataSource = ref.read(merchantDataSourceProvider);
  await dataSource.updateMenuItem(
    item.id,
    UpdateMenuItemRequest(
      isAvailable: resolvedAvailability,
      stockCount: inventory.trackStock ? newStock : null,
      options: options,
    ),
  );

  ref.invalidate(merchantMenuProvider);
  ref.invalidate(merchantMenuItemsProvider);
}

List<MenuItemDto> filterMenuItemsByInventory(
  List<MenuItemDto> items,
  MerchantInventoryFilter filter,
) {
  if (filter == MerchantInventoryFilter.all) return items;

  return items.where((item) {
    final inventory = MenuItemInventory.fromMenuItem(item);
    switch (filter) {
      case MerchantInventoryFilter.inStock:
        return !inventory.trackStock ||
            (inventory.stock != null && inventory.stock! > 5);
      case MerchantInventoryFilter.lowStock:
        return inventory.isLowStock;
      case MerchantInventoryFilter.soldOut:
        return inventory.isSoldOut || !item.isAvailable;
      case MerchantInventoryFilter.all:
        return true;
    }
  }).toList();
}
