import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/data_source/dto/merchant/menu_item_dto.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';
import 'merchant_menu_provider.dart';

/// Resolves order line-item images from API `image_url` or partner menu catalog.
class MenuItemImageLookup {
  MenuItemImageLookup({
    required Map<String, String> byName,
    required Map<int, String> byId,
  })  : _byName = byName,
        _byId = byId;

  final Map<String, String> _byName;
  final Map<int, String> _byId;

  String? resolve(OrderItemDto item) {
    final direct = item.imageUrl?.trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final menuItemId = item.menuItemId;
    if (menuItemId != null) {
      final byId = _byId[menuItemId];
      if (byId != null && byId.isNotEmpty) return byId;
    }

    return _byName[item.itemName.trim().toLowerCase()];
  }
}

final menuItemImageLookupProvider = Provider<MenuItemImageLookup>((ref) {
  final menu = ref.watch(merchantMenuProvider).valueOrNull;
  final byName = <String, String>{};
  final byId = <int, String>{};

  if (menu != null) {
    for (final category in menu.categories) {
      for (final menuItem in category.availableItems ?? <MenuItemDto>[]) {
        final url = menuItem.imageUrl?.trim();
        if (url == null || url.isEmpty) continue;
        byName[menuItem.name.trim().toLowerCase()] = url;
        byId[menuItem.id] = url;
      }
    }
  }

  return MenuItemImageLookup(byName: byName, byId: byId);
});
