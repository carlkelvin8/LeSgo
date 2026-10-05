import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types of favorites
enum FavoriteType { restaurant, store, address }

/// Favorite item model
class FavoriteItem {
  final String id;
  final FavoriteType type;
  final String name;
  final String? subtitle;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final DateTime addedAt;

  FavoriteItem({
    required this.id,
    required this.type,
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.metadata,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'metadata': metadata,
    'addedAt': addedAt.toIso8601String(),
  };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] as String,
      type: FavoriteType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FavoriteType.address,
      ),
      name: json['name'] as String,
      subtitle: json['subtitle'] as String?,
      imageUrl: json['imageUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }
}

/// Service for managing favorites/bookmarks
@lazySingleton
class FavoritesService {
  static const String _keyRestaurants = 'favorites_restaurants';
  static const String _keyStores = 'favorites_stores';
  static const String _keyAddresses = 'favorites_addresses';

  final SharedPreferences _prefs;
  String? _userScope;

  FavoritesService(this._prefs);

  /// Scope device-persisted favorites to the signed-in customer. Legacy
  /// unscoped entries are intentionally not exposed to whichever account logs
  /// in next on a shared device.
  void setUserScope(String? userId) {
    final normalized = userId?.trim();
    _userScope = normalized == null || normalized.isEmpty ? null : normalized;
  }

  String _scopedKey(String base) => '${base}_${_userScope ?? 'signed_out'}';

  // ─────────────────────────────────────────────────────────────────────────
  // Restaurants
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<FavoriteItem>> getFavoriteRestaurants() async {
    return _userScope == null ? [] : _getFavorites(_scopedKey(_keyRestaurants));
  }

  Future<bool> addFavoriteRestaurant({
    required String id,
    required String name,
    String? subtitle,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    return _addFavorite(
      _scopedKey(_keyRestaurants),
      FavoriteItem(
        id: id,
        type: FavoriteType.restaurant,
        name: name,
        subtitle: subtitle,
        imageUrl: imageUrl,
        metadata: metadata,
      ),
    );
  }

  Future<bool> removeFavoriteRestaurant(String id) async {
    return _userScope == null
        ? false
        : _removeFavorite(_scopedKey(_keyRestaurants), id);
  }

  Future<bool> isFavoriteRestaurant(String id) async {
    return _userScope == null
        ? false
        : _isFavorite(_scopedKey(_keyRestaurants), id);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stores
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<FavoriteItem>> getFavoriteStores() async {
    return _userScope == null ? [] : _getFavorites(_scopedKey(_keyStores));
  }

  Future<bool> addFavoriteStore({
    required String id,
    required String name,
    String? subtitle,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    return _addFavorite(
      _scopedKey(_keyStores),
      FavoriteItem(
        id: id,
        type: FavoriteType.store,
        name: name,
        subtitle: subtitle,
        imageUrl: imageUrl,
        metadata: metadata,
      ),
    );
  }

  Future<bool> removeFavoriteStore(String id) async {
    return _userScope == null
        ? false
        : _removeFavorite(_scopedKey(_keyStores), id);
  }

  Future<bool> isFavoriteStore(String id) async {
    return _userScope == null ? false : _isFavorite(_scopedKey(_keyStores), id);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Addresses
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<FavoriteItem>> getFavoriteAddresses() async {
    return _userScope == null ? [] : _getFavorites(_scopedKey(_keyAddresses));
  }

  Future<bool> addFavoriteAddress({
    required String id,
    required String name,
    String? subtitle,
    Map<String, dynamic>? metadata,
  }) async {
    return _addFavorite(
      _scopedKey(_keyAddresses),
      FavoriteItem(
        id: id,
        type: FavoriteType.address,
        name: name,
        subtitle: subtitle,
        metadata: metadata,
      ),
    );
  }

  Future<bool> removeFavoriteAddress(String id) async {
    return _userScope == null
        ? false
        : _removeFavorite(_scopedKey(_keyAddresses), id);
  }

  Future<bool> isFavoriteAddress(String id) async {
    return _userScope == null
        ? false
        : _isFavorite(_scopedKey(_keyAddresses), id);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // All Favorites
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<FavoriteItem>> getAllFavorites() async {
    final restaurants = await getFavoriteRestaurants();
    final stores = await getFavoriteStores();
    final addresses = await getFavoriteAddresses();

    final all = [...restaurants, ...stores, ...addresses];
    all.sort((a, b) => b.addedAt.compareTo(a.addedAt)); // Most recent first

    return all;
  }

  Future<int> getFavoritesCount() async {
    final all = await getAllFavorites();
    return all.length;
  }

  Future<bool> clearAllFavorites() async {
    try {
      await _prefs.remove(_keyRestaurants);
      await _prefs.remove(_keyStores);
      await _prefs.remove(_keyAddresses);
      debugPrint('✅ All favorites cleared');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to clear favorites: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<FavoriteItem>> _getFavorites(String key) async {
    try {
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => FavoriteItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get favorites from $key: $e');
      return [];
    }
  }

  Future<bool> _addFavorite(String key, FavoriteItem item) async {
    if (_userScope == null) return false;
    try {
      final favorites = await _getFavorites(key);

      // Check if already exists
      if (favorites.any((f) => f.id == item.id)) {
        debugPrint('⚠️ Favorite already exists: ${item.name}');
        return false;
      }

      favorites.add(item);

      final jsonString = jsonEncode(favorites.map((f) => f.toJson()).toList());
      await _prefs.setString(key, jsonString);

      debugPrint('✅ Added favorite: ${item.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to add favorite: $e');
      return false;
    }
  }

  Future<bool> _removeFavorite(String key, String id) async {
    try {
      final favorites = await _getFavorites(key);
      final initialLength = favorites.length;

      favorites.removeWhere((f) => f.id == id);

      if (favorites.length == initialLength) {
        debugPrint('⚠️ Favorite not found: $id');
        return false;
      }

      final jsonString = jsonEncode(favorites.map((f) => f.toJson()).toList());
      await _prefs.setString(key, jsonString);

      debugPrint('✅ Removed favorite: $id');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to remove favorite: $e');
      return false;
    }
  }

  Future<bool> _isFavorite(String key, String id) async {
    try {
      final favorites = await _getFavorites(key);
      return favorites.any((f) => f.id == id);
    } catch (e) {
      debugPrint('❌ Failed to check favorite: $e');
      return false;
    }
  }
}
