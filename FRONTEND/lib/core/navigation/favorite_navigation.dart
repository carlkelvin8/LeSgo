import 'package:flutter/material.dart';

import '../../core/constants/routers/app_router.dart';
import '../../core/constants/routers/booking/booking_routes.dart';
import '../../core/constants/routers/main/main_routes.dart';
import '../../core/services/favorites_service.dart';
import '../../domain/entities/booking/leseat/restaurant.dart';
import '../../domain/entities/booking/lesbuy/store.dart';

/// Opens a saved favorite in the correct detail screen.
class FavoriteNavigation {
  FavoriteNavigation._();

  static void open(BuildContext context, FavoriteItem item) {
    switch (item.type) {
      case FavoriteType.restaurant:
        _openRestaurant(context, item);
      case FavoriteType.store:
        _openStore(context, item);
      case FavoriteType.address:
        AppRouter.push(context, MainRoutes.addressManagement);
    }
  }

  static void _openRestaurant(BuildContext context, FavoriteItem item) {
    final meta = item.metadata ?? {};
    final categories = (meta['categories'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    final restaurant = Restaurant(
      id: item.id,
      name: item.name,
      address: meta['address']?.toString() ?? item.subtitle ?? '',
      imagePath: item.imageUrl ?? meta['imagePath']?.toString() ?? '',
      rating: (meta['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (meta['reviewCount'] as num?)?.toInt() ?? 0,
      categories: categories,
      isNew: meta['isNew'] as bool? ?? false,
      cuisine: meta['cuisine']?.toString(),
      deliveryTime: meta['deliveryTime']?.toString(),
      priceRange: meta['priceRange']?.toString(),
      openingHours: meta['openingHours']?.toString(),
    );

    AppRouter.push(
      context,
      BookingRoutes.leseatRestaurantDetail,
      arguments: restaurant,
    );
  }

  static void _openStore(BuildContext context, FavoriteItem item) {
    final meta = item.metadata ?? {};
    final categories = (meta['categories'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    final store = Store(
      id: item.id,
      name: item.name,
      address: meta['address']?.toString() ?? item.subtitle ?? '',
      imagePath: item.imageUrl ?? meta['imagePath']?.toString() ?? '',
      rating: (meta['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (meta['reviewCount'] as num?)?.toInt() ?? 0,
      categories: categories,
      isNew: meta['isNew'] as bool? ?? false,
      storeType: meta['storeType']?.toString(),
      deliveryTime: meta['deliveryTime']?.toString(),
      openingHours: meta['openingHours']?.toString(),
      priceRange: meta['priceRange']?.toString(),
    );

    AppRouter.push(
      context,
      BookingRoutes.lesbuyStoreDetail,
      arguments: store,
    );
  }

  static Map<String, dynamic> restaurantMetadata(Restaurant restaurant) {
    return {
      'address': restaurant.address,
      'imagePath': restaurant.imagePath,
      'rating': restaurant.rating,
      'reviewCount': restaurant.reviewCount,
      'categories': restaurant.categories,
      'isNew': restaurant.isNew,
      'cuisine': restaurant.cuisine,
      'deliveryTime': restaurant.deliveryTime,
      'priceRange': restaurant.priceRange,
      'openingHours': restaurant.openingHours,
    };
  }

  static Map<String, dynamic> storeMetadata(Store store) {
    return {
      'address': store.address,
      'imagePath': store.imagePath,
      'rating': store.rating,
      'reviewCount': store.reviewCount,
      'categories': store.categories,
      'isNew': store.isNew,
      'storeType': store.storeType,
      'deliveryTime': store.deliveryTime,
      'openingHours': store.openingHours,
      'priceRange': store.priceRange,
    };
  }
}
