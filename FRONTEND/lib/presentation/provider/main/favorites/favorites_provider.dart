import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/core/state/user_session_epoch.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/di/injection.dart';

class FavoritesState {
  final List<FavoriteItem> restaurants;
  final List<FavoriteItem> stores;
  final List<FavoriteItem> addresses;
  final List<FavoriteItem> allFavorites;
  final bool isLoading;
  final String? error;

  FavoritesState({
    this.restaurants = const [],
    this.stores = const [],
    this.addresses = const [],
    this.allFavorites = const [],
    this.isLoading = false,
    this.error,
  });

  int get totalCount => allFavorites.length;
  int get restaurantsCount => restaurants.length;
  int get storesCount => stores.length;
  int get addressesCount => addresses.length;

  FavoritesState copyWith({
    List<FavoriteItem>? restaurants,
    List<FavoriteItem>? stores,
    List<FavoriteItem>? addresses,
    List<FavoriteItem>? allFavorites,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FavoritesState(
      restaurants: restaurants ?? this.restaurants,
      stores: stores ?? this.stores,
      addresses: addresses ?? this.addresses,
      allFavorites: allFavorites ?? this.allFavorites,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error,
    );
  }
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final FavoritesService _favoritesService = getIt<FavoritesService>();

  FavoritesNotifier() : super(FavoritesState()) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final restaurants = await _favoritesService.getFavoriteRestaurants();
      final stores = await _favoritesService.getFavoriteStores();
      final addresses = await _favoritesService.getFavoriteAddresses();
      final all = await _favoritesService.getAllFavorites();

      state = state.copyWith(
        restaurants: restaurants,
        stores: stores,
        addresses: addresses,
        allFavorites: all,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Restaurants
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> toggleFavoriteRestaurant({
    required String id,
    required String name,
    String? subtitle,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final isFavorite = await _favoritesService.isFavoriteRestaurant(id);

    if (isFavorite) {
      await _favoritesService.removeFavoriteRestaurant(id);
    } else {
      await _favoritesService.addFavoriteRestaurant(
        id: id,
        name: name,
        subtitle: subtitle,
        imageUrl: imageUrl,
        metadata: metadata,
      );
    }

    await loadFavorites();
    return !isFavorite; // Return new state
  }

  Future<bool> isFavoriteRestaurant(String id) async {
    return await _favoritesService.isFavoriteRestaurant(id);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stores
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> toggleFavoriteStore({
    required String id,
    required String name,
    String? subtitle,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final isFavorite = await _favoritesService.isFavoriteStore(id);

    if (isFavorite) {
      await _favoritesService.removeFavoriteStore(id);
    } else {
      await _favoritesService.addFavoriteStore(
        id: id,
        name: name,
        subtitle: subtitle,
        imageUrl: imageUrl,
        metadata: metadata,
      );
    }

    await loadFavorites();
    return !isFavorite; // Return new state
  }

  Future<bool> isFavoriteStore(String id) async {
    return await _favoritesService.isFavoriteStore(id);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Addresses
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> toggleFavoriteAddress({
    required String id,
    required String name,
    String? subtitle,
    Map<String, dynamic>? metadata,
  }) async {
    final isFavorite = await _favoritesService.isFavoriteAddress(id);

    if (isFavorite) {
      await _favoritesService.removeFavoriteAddress(id);
    } else {
      await _favoritesService.addFavoriteAddress(
        id: id,
        name: name,
        subtitle: subtitle,
        metadata: metadata,
      );
    }

    await loadFavorites();
    return !isFavorite; // Return new state
  }

  Future<bool> isFavoriteAddress(String id) async {
    return await _favoritesService.isFavoriteAddress(id);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // General
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> clearAllFavorites() async {
    await _favoritesService.clearAllFavorites();
    await loadFavorites();
  }

  Future<void> removeFavorite(FavoriteItem item) async {
    switch (item.type) {
      case FavoriteType.restaurant:
        await _favoritesService.removeFavoriteRestaurant(item.id);
        break;
      case FavoriteType.store:
        await _favoritesService.removeFavoriteStore(item.id);
        break;
      case FavoriteType.address:
        await _favoritesService.removeFavoriteAddress(item.id);
        break;
    }
    await loadFavorites();
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
      ref.watch(userSessionEpochProvider);
      return FavoritesNotifier();
    });
