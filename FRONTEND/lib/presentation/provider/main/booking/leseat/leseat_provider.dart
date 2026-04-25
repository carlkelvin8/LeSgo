import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../domain/entities/booking/leseat/restaurant.dart';
import '../../../../../domain/entities/booking/leseat/food_category.dart';
import '../../../../../data/data_source/partner_remote_datasource.dart';
import '../../../../../core/di/injection.dart';

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
  final PartnerRemoteDataSource _partnerDataSource = getIt<PartnerRemoteDataSource>();

  LeseatNotifier() : super(LeseatState()) {
    loadRestaurants();
  }

  Future<void> loadRestaurants() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('🔵 LeseatProvider: Loading restaurants from API');
      
      final response = await _partnerDataSource.getPartners(
        category: 'restaurant',
        perPage: 50,
      );
      
      final restaurants = response.data.map((partnerDto) {
        return Restaurant(
          id: partnerDto.id.toString(),
          name: partnerDto.name,
          address: partnerDto.description ?? 'No address available',
          imagePath: partnerDto.logoUrl ?? 'assets/images/book/leseat/Pizza.svg',
          rating: partnerDto.rating ?? 4.0,
          reviewCount: partnerDto.totalReviews ?? 0,
          categories: partnerDto.tags ?? [],
          cuisine: partnerDto.cuisineTypes?.join(' • ') ?? partnerDto.category ?? 'Restaurant',
          openingHours: '10:00 AM - 10:00 PM', // TODO: Parse from opening_hours
          isNew: partnerDto.isFeatured ?? false,
        );
      }).toList();
      
      print('🟢 LeseatProvider: Loaded ${restaurants.length} restaurants');
      
      state = state.copyWith(
        restaurants: restaurants,
        filteredRestaurants: restaurants,
        isLoading: false,
      );
      
      _filterRestaurants();
    } catch (e) {
      print('🔴 LeseatProvider: Error loading restaurants - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load restaurants. Please try again.',
      );
    }
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
            restaurant.cuisine?.toLowerCase().contains(query) == true;
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

  Future<void> refresh() async {
    await loadRestaurants();
  }
}

final leseatProvider = StateNotifierProvider<LeseatNotifier, LeseatState>((
  ref,
) {
  return LeseatNotifier();
});
