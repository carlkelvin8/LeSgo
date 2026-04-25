import 'package:flutter_riverpod/flutter_riverpod.dart';
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
       restaurants = restaurants ?? _defaultRestaurants,
       filteredRestaurants = filteredRestaurants ?? _defaultRestaurants;

  static final List<FoodCategory> _defaultCategories = [
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

  static final List<Restaurant> _defaultRestaurants = [
    Restaurant(
      id: '1',
      name: 'Bella Italia Pizzeria',
      address: 'Station 3, Barangay Balabag, Boracay',
      imagePath: 'assets/images/book/leseat/Pizza.svg',
      rating: 4.8,
      reviewCount: 200,
      categories: ['pizza', 'pasta', 'starters'],
      cuisine: 'Italian • Pizza • Pasta',
      openingHours: '10:00 AM - 10:00 PM',
    ),
    Restaurant(
      id: '2',
      name: 'Jollibee - Claveria',
      address: 'Station 2, Barangay Balabag, Boracay',
      imagePath: 'assets/images/book/leseat/Chicken.svg',
      rating: 4.7,
      reviewCount: 1000,
      categories: ['chicken', 'burger', 'fries'],
      isNew: true,
      cuisine: 'Fast Food • Chicken • Burgers',
      openingHours: '7:00 AM - 11:00 PM',
    ),
    Restaurant(
      id: '3',
      name: 'Sun Sets Cafe - Claveria',
      address: 'Station 3, Barangay Balabag, Boracay',
      imagePath: 'assets/images/book/leseat/Pizza.svg',
      rating: 4.6,
      reviewCount: 500,
      categories: ['pizza', 'drinks'],
      cuisine: 'Cafe • Pizza • Beverages',
      openingHours: '8:00 AM - 9:00 PM',
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
  LeseatNotifier() : super(LeseatState());

  void selectCategory(String? categoryId) {
    if (categoryId == null) {
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
    if (state.selectedCategoryId != null) {
      filtered = filtered.where((restaurant) {
        return restaurant.categories.contains(state.selectedCategoryId);
      }).toList();
    }

    // Filter by search query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((restaurant) {
        return restaurant.name.toLowerCase().contains(query) ||
            restaurant.address.toLowerCase().contains(query);
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
}

final leseatProvider = StateNotifierProvider<LeseatNotifier, LeseatState>((
  ref,
) {
  return LeseatNotifier();
});
