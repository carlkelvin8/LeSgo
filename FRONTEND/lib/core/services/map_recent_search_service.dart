import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MapRecentPlace {
  final String placeId;
  final String description;
  final double latitude;
  final double longitude;

  const MapRecentPlace({
    required this.placeId,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'place_id': placeId,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory MapRecentPlace.fromJson(Map<String, dynamic> json) {
    return MapRecentPlace(
      placeId: json['place_id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MapRecentSearchService {
  MapRecentSearchService(this._prefs);

  static const _key = 'map_recent_searches';
  static const _maxItems = 8;

  final SharedPreferences _prefs;

  List<MapRecentPlace> getRecent() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => MapRecentPlace.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.placeId.isNotEmpty && p.description.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addRecent(MapRecentPlace place) async {
    if (place.placeId.isEmpty || place.description.isEmpty) return;

    final existing = getRecent()
      ..removeWhere((p) => p.placeId == place.placeId);
    existing.insert(0, place);

    final trimmed = existing.take(_maxItems).map((p) => p.toJson()).toList();
    await _prefs.setString(_key, jsonEncode(trimmed));
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
