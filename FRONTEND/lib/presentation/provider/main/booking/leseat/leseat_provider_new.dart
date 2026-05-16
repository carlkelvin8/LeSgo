import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../data/data_source/partner_remote_datasource.dart';
import '../../../../../data/data_source/dto/partner/partner_dto.dart';
import '../../../../../domain/entities/booking/leseat/restaurant.dart';
import '../../../../../domain/entities/booking/leseat/food_category.dart';

class LeseatState {
  final List<FoodCategory> categories;
  final List<Restaurant> restaurants;
  final List<Restaurant> filteredRestaurants;
  final String? selectedCategoryId;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  LeseatState({
    List<FoodCategory>? categories,
    List<Restaurant>? restaurants,
    List<Restaurant>? filteredRestaurants,
    this.selectedCategoryId,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  }) : categories = categories ?? _defaultCategories,
       restaurants = restaurants ?? [],
       filteredRestaurants = filteredRestaurants ?? [];

  static final List<FoodCategory> _defaultCategories = [
    FoodCategory(
      id: 'all',
      name: 'All',
      iconPath: 'assets/images/book/leseat/Pizza.svg',
    ),
    FoodCategory(
      id: 'pizza',
      name: 'Pizza',
      iconPath: 'assets/images/book/leseat/Pizza.svg',
    ),
    FoodCategory(
      id: 'chicken',
      name: 'Chicken',
      iconPath: 'assets/images/book/leseat/Chicken.svg',
    ),
    FoodCategory(
      id: 'fries',
      name: 'Fries',
      iconPath: 'assets/images/book/leseat/Fries.svg',
    ),
    FoodCategory(
      id: 'drinks',
      name: 'Drinks',
      iconPath: 'assets/images/book/leseat/Drink.svg',
    ),
    FoodCategory(
      id: 'burger',
      name: 'Burger',
      iconPath: 'assets/images/book/leseat/Burger.svg',
    ),
  ];

  LeseatState copyWith({
    List<FoodCategory>? categories,
    List<Restaurant>? restaurants,
    List<Restaurant>? filteredRestaurants,
    String? selectedCategoryId,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearSelectedCategory = false,
  }) {
    return LeseatState(
      categories: categories ?? this.categories,
      restaurants: restaurants ?? this.restaurants,
      filteredRestaurants: filteredRestaurants ?? this.filteredRestaurants,
      selectedCategoryId: clearSelectedCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LeseatNotifier extends StateNotifier<LeseatState> {
  final PartnerRemoteDataSource _partnerDataSource;

  LeseatNotifier(this._partnerDataSource) : super(LeseatState()) {
    loadRestaurants();
  }

  /// Load restaurants from API
  Future<void> loadRestaurants() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔵 LeseatProvider: Loading restaurants from API...');

      final response = await _partnerDataSource.getPartners(
        category: 'restaurant',
        perPage: 50,
      );

      print('🔵 LeseatProvider: Received ${response.data.length} restaurants');

      final restaurants = response.data.map(_mapToRestaurant).toList();

      state = state.copyWith(
        restaurants: restaurants,
        filteredRestaurants: restaurants,
        isLoading: false,
      );

      print('🔵 LeseatProvider: Restaurants loaded successfully');
    } catch (e) {
      print('🔴 LeseatProvider: Error loading restaurants - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load restaurants: $e',
      );
    }
  }

  /// Map PartnerDto to Restaurant entity
  Restaurant _mapToRestaurant(PartnerDto partner) {
    // Extract categories from tags or cuisine types
    final categories = <String>[];
    if (partner.tags != null) {
      categories.addAll(partner.tags!.map((tag) => tag.toLowerCase()));
    }
    if (partner.cuisineTypes != null) {
      categories.addAll(partner.cuisineTypes!.map((c) => c.toLowerCase()));
    }

    // Build cuisine string
    final cuisineStr = partner.cuisineTypes?.join(' • ') ?? 'Restaurant';

    return Restaurant(
      id: partner.id.toString(),
      name: partner.name,
      address: partner.description ?? 'No address provided',
      imagePath: partner.logoUrl ?? 'assets/images/book/leseat/Pizza.svg',
      rating: partner.rating ?? 0.0,
      reviewCount: partner.totalReviews ?? 0,
      categories: categories,
      cuisine: cuisineStr,
      openingHours: '9:00 AM - 9:00 PM',
      isNew: partner.isFeatured ?? false,
    );
  }

  void selectCategory(String? categoryId) {
    if (categoryId == null || categoryId == 'all') {
      state = state.copyWith(clearSelectedCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
    _filterRestaurants();
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _filterRestaurants();
  }

  void _filterRestaurants() {
    var filtered = state.restaurants;

    // Filter by category
    if (state.selectedCategoryId != null && state.selectedCategoryId != 'all') {
      filtered = filtered.where((restaurant) {
        return restaurant.categories.contains(state.selectedCategoryId);
      }).toList();
    }

    // Filter by search query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((restaurant) {
        return restaurant.name.toLowerCase().contains(query) ||
            restaurant.address.toLowerCase().contains(query) ||
            (restaurant.cuisine?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    state = state.copyWith(filteredRestaurants: filtered);
  }

  void clearFilters() {
    state = state.copyWith(
      selectedCategoryId: null,
      searchQuery: '',
      filteredRestaurants: state.restaurants,
    );
  }

  /// Refresh restaurants
  Future<void> refresh() async {
    await loadRestaurants();
  }
}

final leseatProvider = StateNotifierProvider<LeseatNotifier, LeseatState>((
  ref,
) {
  final partnerDataSource = getIt<PartnerRemoteDataSource>();
  return LeseatNotifier(partnerDataSource);
});
