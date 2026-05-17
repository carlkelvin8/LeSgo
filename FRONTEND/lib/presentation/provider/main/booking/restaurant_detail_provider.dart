import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/booking/leseat/menu_item.dart';
import '../../../../domain/entities/booking/leseat/food_category.dart';
import '../../../../domain/entities/booking/leseat/order_item.dart';
import '../../../../data/data_source/partner_remote_datasource.dart';
import '../../../../core/di/injection.dart';

class RestaurantDetailState {
  final List<FoodCategory> menuCategories;
  final List<MenuItem> menuItems;
  final List<MenuItem> filteredMenuItems;
  final String? selectedCategoryId;
  final List<OrderItem> cartItems;
  final String? activeRestaurantId;
  final String? activeRestaurantName;
  final bool isLoading;
  final String? error;

  RestaurantDetailState({
    List<FoodCategory>? menuCategories,
    List<MenuItem>? menuItems,
    List<MenuItem>? filteredMenuItems,
    this.selectedCategoryId,
    List<OrderItem>? cartItems,
    this.activeRestaurantId,
    this.activeRestaurantName,
    this.isLoading = false,
    this.error,
  }) : menuCategories = menuCategories ?? _defaultMenuCategories,
       menuItems = menuItems ?? [],
       filteredMenuItems = filteredMenuItems ?? [],
       cartItems = cartItems ?? [];

  static List<FoodCategory> get _defaultMenuCategories => [
    FoodCategory(id: 'popular', name: 'Popular', iconPath: ''),
  ];

  String? get selectedCategoryName {
    if (selectedCategoryId == null) return null;
    return menuCategories
        .firstWhere(
          (cat) => cat.id == selectedCategoryId,
          orElse: () => FoodCategory(id: '', name: '', iconPath: ''),
        )
        .name;
  }

  int get cartItemCount {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  double get cartTotal {
    return cartItems.fold(0.0, (sum, item) => sum + item.total);
  }

  RestaurantDetailState copyWith({
    List<FoodCategory>? menuCategories,
    List<MenuItem>? menuItems,
    List<MenuItem>? filteredMenuItems,
    String? selectedCategoryId,
    List<OrderItem>? cartItems,
    String? activeRestaurantId,
    String? activeRestaurantName,
    bool? isLoading,
    String? error,
  }) {
    return RestaurantDetailState(
      menuCategories: menuCategories ?? this.menuCategories,
      menuItems: menuItems ?? this.menuItems,
      filteredMenuItems: filteredMenuItems ?? this.filteredMenuItems,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      cartItems: cartItems ?? this.cartItems,
      activeRestaurantId: activeRestaurantId ?? this.activeRestaurantId,
      activeRestaurantName: activeRestaurantName ?? this.activeRestaurantName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RestaurantDetailNotifier extends StateNotifier<RestaurantDetailState> {
  final PartnerRemoteDataSource _partnerDataSource =
      getIt<PartnerRemoteDataSource>();

  RestaurantDetailNotifier() : super(RestaurantDetailState());

  Future<void> loadRestaurantDetails(
    String restaurantId,
    List<String> restaurantCategories, {
    String? restaurantName,
  }) async {
    state = state.copyWith(
      activeRestaurantId: restaurantId,
      activeRestaurantName: restaurantName,
      isLoading: true,
      error: null,
    );

    try {
      print('🔵 RestaurantDetail: Loading menu for restaurant $restaurantId');

      final response = await _partnerDataSource.getPartnerMenu(
        int.parse(restaurantId),
      );

      // Convert categories
      final menuCategories = [
        FoodCategory(id: 'popular', name: 'Popular', iconPath: ''),
        ...response.data.categories.map(
          (catDto) => FoodCategory(
            id: catDto.id.toString(),
            name: catDto.name,
            iconPath: '',
          ),
        ),
      ];

      // Convert menu items
      final allMenuItems = <MenuItem>[];
      for (final catDto in response.data.categories) {
        if (catDto.availableItems != null) {
          for (final itemDto in catDto.availableItems!) {
            allMenuItems.add(
              MenuItem(
                id: itemDto.id.toString(),
                name: itemDto.name,
                description: itemDto.description ?? '',
                price: itemDto.price,
                imagePath:
                    itemDto.imageUrl ?? 'assets/images/book/leseat/Pizza.svg',
                categoryId: catDto.id.toString(),
                isPopular: itemDto.isPopular ?? false,
              ),
            );
          }
        }
      }

      print('🟢 RestaurantDetail: Loaded ${allMenuItems.length} menu items');

      state = state.copyWith(
        menuCategories: menuCategories,
        menuItems: allMenuItems,
        filteredMenuItems: allMenuItems
            .where((item) => item.isPopular)
            .toList(),
        selectedCategoryId: 'popular',
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectCategory(String? categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
    _filterMenuItems();
  }

  void _filterMenuItems() {
    var filtered = state.menuItems;

    if (state.selectedCategoryId == 'popular') {
      filtered = filtered.where((item) => item.isPopular).toList();
    } else if (state.selectedCategoryId != null) {
      filtered = filtered
          .where((item) => item.categoryId == state.selectedCategoryId)
          .toList();
    }

    state = state.copyWith(filteredMenuItems: filtered);
  }

  void addToCart(MenuItem item) {
    final restaurantId = state.activeRestaurantId;
    final cartItemId = restaurantId != null
        ? '$restaurantId:${item.id}'
        : item.id;

    final existingItemIndex = state.cartItems.indexWhere(
      (cartItem) => cartItem.id == cartItemId,
    );

    List<OrderItem> updatedCart;
    if (existingItemIndex >= 0) {
      // Update quantity
      updatedCart = List.from(state.cartItems);
      updatedCart[existingItemIndex] = updatedCart[existingItemIndex].copyWith(
        quantity: updatedCart[existingItemIndex].quantity + 1,
      );
    } else {
      // Add new item
      updatedCart = [
        ...state.cartItems,
        OrderItem(
          id: cartItemId,
          name: item.name,
          imagePath: item.imagePath,
          price: item.price,
          quantity: 1,
          restaurantId: restaurantId,
          restaurantName: state.activeRestaurantName,
        ),
      ];
    }

    state = state.copyWith(cartItems: updatedCart);
  }

  void removeFromCart(String itemId) {
    final updatedCart = state.cartItems
        .where((item) => item.id != itemId)
        .toList();
    state = state.copyWith(cartItems: updatedCart);
  }

  void updateCartItemQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(itemId);
      return;
    }

    final updatedCart = state.cartItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(cartItems: updatedCart);
  }

  void clearCart() {
    state = state.copyWith(cartItems: []);
  }
}

final restaurantDetailProvider =
    StateNotifierProvider.autoDispose<RestaurantDetailNotifier, RestaurantDetailState>(
      (ref) => RestaurantDetailNotifier(),
    );
