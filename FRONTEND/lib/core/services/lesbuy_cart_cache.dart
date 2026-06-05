import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../di/injection.dart';
import '../../domain/entities/booking/lesbuy/cart_item.dart';
import '../../domain/entities/booking/lesbuy/product.dart';

class LesbuyCartSnapshot {
  final String storeId;
  final String? storeName;
  final List<LesbuyCartItem> items;

  const LesbuyCartSnapshot({
    required this.storeId,
    this.storeName,
    required this.items,
  });
}

/// Persists LesBuy store cart across navigation and app restarts.
class LesbuyCartCache {
  LesbuyCartCache._();

  static const _prefsKey = 'lesbuy_cart_v1';

  static Future<LesbuyCartSnapshot?> load() async {
    try {
      final prefs = getIt<SharedPreferences>();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final storeId = decoded['store_id']?.toString();
      if (storeId == null || storeId.isEmpty) return null;

      final itemsRaw = decoded['items'];
      if (itemsRaw is! List || itemsRaw.isEmpty) {
        return LesbuyCartSnapshot(
          storeId: storeId,
          storeName: decoded['store_name']?.toString(),
          items: const [],
        );
      }

      final items = itemsRaw
          .whereType<Map>()
          .map((entry) => _itemFromJson(Map<String, dynamic>.from(entry)))
          .whereType<LesbuyCartItem>()
          .toList();

      return LesbuyCartSnapshot(
        storeId: storeId,
        storeName: decoded['store_name']?.toString(),
        items: items,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save({
    required String? storeId,
    String? storeName,
    required List<LesbuyCartItem> items,
  }) async {
    try {
      final prefs = getIt<SharedPreferences>();
      if (storeId == null ||
          storeId.isEmpty ||
          items.isEmpty) {
        await prefs.remove(_prefsKey);
        return;
      }

      await prefs.setString(
        _prefsKey,
        jsonEncode({
          'store_id': storeId,
          'store_name': storeName,
          'items': items.map(_itemToJson).toList(),
        }),
      );
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      await getIt<SharedPreferences>().remove(_prefsKey);
    } catch (_) {}
  }

  static Map<String, dynamic> _itemToJson(LesbuyCartItem item) => {
        'product': _productToJson(item.product),
        'quantity': item.quantity,
      };

  static LesbuyCartItem? _itemFromJson(Map<String, dynamic> json) {
    final productRaw = json['product'];
    if (productRaw is! Map) return null;
    final quantity = json['quantity'];
    if (quantity is! num || quantity <= 0) return null;
    return LesbuyCartItem(
      product: _productFromJson(Map<String, dynamic>.from(productRaw)),
      quantity: quantity.toInt(),
    );
  }

  static Map<String, dynamic> _productToJson(Product product) => {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'imagePath': product.imagePath,
        'categoryId': product.categoryId,
        'isPopular': product.isPopular,
        'inStock': product.inStock,
        'stockCount': product.stockCount,
      };

  static Product _productFromJson(Map<String, dynamic> json) => Product(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        imagePath: json['imagePath']?.toString() ??
            'assets/images/book/lesbuy/Product.svg',
        categoryId: json['categoryId']?.toString() ?? '',
        isPopular: json['isPopular'] == true,
        inStock: json['inStock'] != false,
        stockCount: (json['stockCount'] as num?)?.toInt(),
      );
}
