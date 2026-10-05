import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/rider_order.dart';
import '../utils/app_logger.dart';

/// Persists the active order JSON for offline read during delivery.
class RiderActiveOrderCache {
  RiderActiveOrderCache._();

  static const _key = 'rider_active_order_json_v1';

  static Future<void> saveRaw(Map<String, dynamic> orderJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(orderJson));
    } catch (e) {
      AppLogger.warn('Failed to cache active order: $e');
    }
  }

  static Future<RiderOrder?> loadOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return RiderOrder.fromJson(decoded);
    } catch (e) {
      AppLogger.warn('Failed to load cached active order: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
