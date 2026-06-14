import '../../data/data_source/dto/merchant/menu_item_dto.dart';

const String kMenuInventoryOptionsKey = '_inventory';

class MenuItemInventory {
  final int? stock;
  final bool trackStock;
  final bool autoHideWhenEmpty;

  const MenuItemInventory({
    this.stock,
    this.trackStock = false,
    this.autoHideWhenEmpty = true,
  });

  static const unlimited = MenuItemInventory(trackStock: false);

  bool get isSoldOut => trackStock && stock != null && stock! <= 0;

  bool get isLowStock =>
      trackStock && stock != null && stock! > 0 && stock! <= 5;

  bool resolveAvailability({required bool liveOnMenu}) {
    if (!liveOnMenu) return false;
    if (trackStock && autoHideWhenEmpty && isSoldOut) return false;
    return true;
  }

  Map<String, dynamic> toOptionsMap() {
    if (!trackStock) return {};
    return {
      'stock': stock,
      'track_stock': trackStock,
      'auto_hide_when_empty': autoHideWhenEmpty,
    };
  }

  factory MenuItemInventory.fromOptionsMap(Map<String, dynamic>? options) {
    if (options == null || options.isEmpty) {
      return MenuItemInventory.unlimited;
    }

    final raw = options[kMenuInventoryOptionsKey];
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final trackStock = _parseBool(map['track_stock'], fallback: true);
      if (!trackStock) return MenuItemInventory.unlimited;
      return MenuItemInventory(
        stock: _parseIntNullable(map['stock']),
        trackStock: true,
        autoHideWhenEmpty: _parseBool(map['auto_hide_when_empty'], fallback: true),
      );
    }

    return MenuItemInventory.unlimited;
  }

  factory MenuItemInventory.fromMenuItem(MenuItemDto item) {
    final fromOptions = MenuItemInventory.fromOptionsMap(item.options);
    if (fromOptions.trackStock) return fromOptions;

    final stockCount = item.stockCount;
    if (stockCount != null) {
      return MenuItemInventory(
        stock: stockCount,
        trackStock: true,
        autoHideWhenEmpty: true,
      );
    }

    return MenuItemInventory.unlimited;
  }

  MenuItemInventory copyWith({
    int? stock,
    bool? trackStock,
    bool? autoHideWhenEmpty,
  }) {
    return MenuItemInventory(
      stock: stock ?? this.stock,
      trackStock: trackStock ?? this.trackStock,
      autoHideWhenEmpty: autoHideWhenEmpty ?? this.autoHideWhenEmpty,
    );
  }
}

Map<String, dynamic> mergeInventoryIntoOptions(
  Map<String, dynamic>? existingOptions,
  MenuItemInventory inventory,
) {
  final map = Map<String, dynamic>.from(existingOptions ?? const {});
  if (!inventory.trackStock) {
    map.remove(kMenuInventoryOptionsKey);
    return map;
  }
  map[kMenuInventoryOptionsKey] = inventory.toOptionsMap();
  return map;
}

int? _parseIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

Map<String, String> menuItemToEditFormMap(
  MenuItemDto item, {
  required String categoryName,
  required String Function(Map<String, dynamic> options) encodeOptions,
}) {
  final inventory = MenuItemInventory.fromMenuItem(item);
  final map = <String, String>{
    'id': item.id.toString(),
    'menuCategoryId': item.menuCategoryId.toString(),
    'name': item.name,
    'description': item.description ?? '',
    'price': item.price.toStringAsFixed(2),
    'category': categoryName,
    'isAvailable': item.isAvailable.toString(),
    'trackStock': inventory.trackStock.toString(),
    'stock': '${inventory.stock ?? 0}',
    'autoHideWhenEmpty': inventory.autoHideWhenEmpty.toString(),
  };

  if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
    map['imageUrl'] = item.imageUrl!;
  }
  if (item.tags != null && item.tags!.isNotEmpty) {
    map['selectedTags'] = item.tags!.join(',');
  }
  if (item.options != null && item.options!.isNotEmpty) {
    map['optionsJson'] = encodeOptions(item.options!);
  }

  return map;
}

bool _parseBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}
