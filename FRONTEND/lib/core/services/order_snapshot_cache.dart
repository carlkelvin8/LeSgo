import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../di/injection.dart';

/// Persists order meta/items when API responses omit them.
class OrderSnapshotCache {
  OrderSnapshotCache._();

  static const _prefsKey = 'order_snapshot_cache_v1';
  static final Map<int, Map<String, dynamic>> _cache = {};

  static Future<void> loadFromDisk() async {
    try {
      final prefs = getIt<SharedPreferences>();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        final id = int.tryParse(key);
        if (id != null && value is Map) {
          _cache[id] = Map<String, dynamic>.from(value);
        }
      });
    } catch (_) {}
  }

  static Future<void> _persist() async {
    try {
      final prefs = getIt<SharedPreferences>();
      final encoded = jsonEncode(
        _cache.map((k, v) => MapEntry(k.toString(), v)),
      );
      await prefs.setString(_prefsKey, encoded);
    } catch (_) {}
  }

  static void save(int orderId, Map<String, dynamic> snapshot) {
    _cache[orderId] = snapshot;
    _persist();
  }

  static void enrichOrderJson(Map<String, dynamic> data, int orderId) {
    final cached = _cache[orderId];
    if (cached == null) return;

    if (data['meta'] == null && cached['meta'] != null) {
      data['meta'] = cached['meta'];
    }

    final cachedItems = cached['items'];
    if (cachedItems is List && cachedItems.isNotEmpty) {
      if (data['lesbuy_items'] == null &&
          (data['items'] == null ||
              (data['items'] is List && (data['items'] as List).isEmpty))) {
        data['lesbuy_items'] = cachedItems;
      }
    }

    if (data['payment_method'] == null && cached['payment_method'] != null) {
      data['payment_method'] = cached['payment_method'];
    }
  }

  static List<Map<String, dynamic>>? itemsFromRequest(
    List<dynamic>? requestItems,
    int orderId,
  ) {
    if (requestItems == null) return null;
    return requestItems.map((e) {
      final json = Map<String, dynamic>.from(e as Map);
      json['order_id'] = orderId;
      if (json['id'] == null) {
        json['id'] = orderId * 1000 + json.hashCode.abs() % 1000;
      }
      return json;
    }).toList();
  }
}
