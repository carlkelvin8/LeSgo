import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'offline_request_record.dart';

/// Persists queued offline requests across app restarts.
class OfflineQueueStorage {
  OfflineQueueStorage._();

  static const String _storageKey = 'offline_request_queue_v1';

  static Future<List<OfflineRequestRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((item) => OfflineRequestRecord.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (_) {
      await prefs.remove(_storageKey);
      return [];
    }
  }

  static Future<void> save(List<OfflineRequestRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    if (records.isEmpty) {
      await prefs.remove(_storageKey);
      return;
    }

    final encoded = jsonEncode(records.map((record) => record.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
