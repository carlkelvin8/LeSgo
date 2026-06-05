import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../di/injection.dart';
import '../../domain/entities/booking/leseat/order_item.dart';

class LeseatCartSnapshot {
  final String restaurantId;
  final String? restaurantName;
  final List<OrderItem> items;

  const LeseatCartSnapshot({
    required this.restaurantId,
    this.restaurantName,
    required this.items,
  });
}

/// Persists LesEat restaurant cart across navigation and app restarts.
class LeseatCartCache {
  LeseatCartCache._();

  static const _prefsKey = 'leseat_cart_v1';

  static Future<LeseatCartSnapshot?> load() async {
    try {
      final prefs = getIt<SharedPreferences>();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final restaurantId = decoded['restaurant_id']?.toString();
      if (restaurantId == null || restaurantId.isEmpty) return null;

      final itemsRaw = decoded['items'];
      if (itemsRaw is! List) {
        return LeseatCartSnapshot(
          restaurantId: restaurantId,
          restaurantName: decoded['restaurant_name']?.toString(),
          items: const [],
        );
      }

      final items = itemsRaw
          .whereType<Map>()
          .map((entry) => _itemFromJson(Map<String, dynamic>.from(entry)))
          .whereType<OrderItem>()
          .toList();

      return LeseatCartSnapshot(
        restaurantId: restaurantId,
        restaurantName: decoded['restaurant_name']?.toString(),
        items: items,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save({
    required String? restaurantId,
    String? restaurantName,
    required List<OrderItem> items,
  }) async {
    try {
      final prefs = getIt<SharedPreferences>();
      if (restaurantId == null ||
          restaurantId.isEmpty ||
          items.isEmpty) {
        await prefs.remove(_prefsKey);
        return;
      }

      await prefs.setString(
        _prefsKey,
        jsonEncode({
          'restaurant_id': restaurantId,
          'restaurant_name': restaurantName,
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

  static Map<String, dynamic> _itemToJson(OrderItem item) => {
        'id': item.id,
        'name': item.name,
        'imagePath': item.imagePath,
        'price': item.price,
        'quantity': item.quantity,
        'restaurantId': item.restaurantId,
        'restaurantName': item.restaurantName,
      };

  static OrderItem? _itemFromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;
    final quantity = json['quantity'];
    if (quantity is! num || quantity <= 0) return null;

    return OrderItem(
      id: id,
      name: json['name']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ??
          'assets/images/book/leseat/Pizza.svg',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: quantity.toInt(),
      restaurantId: json['restaurantId']?.toString(),
      restaurantName: json['restaurantName']?.toString(),
    );
  }
}
