import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/booking/leseat/menu_item.dart';
import '../../../../domain/entities/booking/leseat/food_category.dart';
import '../../../../domain/entities/booking/leseat/order_item.dart';
import '../../../../data/data_source/partner_remote_datasource.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/leseat_cart_cache.dart';
import '../../../../core/utils/menu_image_utils.dart';
import '../../../../core/utils/menu_item_options.dart';

const _defaultMenuImage = 'assets/images/book/leseat/Pizza.svg';

class RestaurantDetailState {
  final List<FoodCategory> menuCategories;
  final List<MenuItem> menuItems;
  final List<MenuItem> filteredMenuItems;
  final String? selectedCategoryId;
  final List<OrderItem> cartItems;
  final String? activeRestaurantId;
  final String? activeRestaurantName;
  final String? restaurantImagePath;
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
    this.restaurantImagePath,
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
    String? restaurantImagePath,
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
      restaurantImagePath: restaurantImagePath ?? this.restaurantImagePath,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RestaurantDetailNotifier extends StateNotifier<RestaurantDetailState> {
  final PartnerRemoteDataSource _partnerDataSource =
      getIt<PartnerRemoteDataSource>();

  int _cartEpoch = 0;

  RestaurantDetailNotifier() : super(RestaurantDetailState()) {
    _restoreCachedCart();
  }

  Future<void> _restoreCachedCart() async {
    final epoch = _cartEpoch;
    final cached = await LeseatCartCache.load();
    if (epoch != _cartEpoch) return;
    if (cached == null || cached.items.isEmpty) return;

    state = state.copyWith(
      activeRestaurantId: cached.restaurantId,
      activeRestaurantName: cached.restaurantName,
      cartItems: cached.items,
    );
  }

  void _persistCart() {
    unawaited(_persistCartAsync());
  }

  Future<void> _persistCartAsync() async {
    final epoch = _cartEpoch;
    final items = List<OrderItem>.from(state.cartItems);
    final restaurantId = state.activeRestaurantId;
    final restaurantName = state.activeRestaurantName;

    if (items.isEmpty ||
        restaurantId == null ||
        restaurantId.isEmpty) {
      await LeseatCartCache.clear();
      return;
    }

    await LeseatCartCache.save(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      items: items,
    );

    if (epoch != _cartEpoch) {
      await LeseatCartCache.clear();
    }
  }

  Future<void> loadRestaurantDetails(
    String restaurantId,
    List<String> restaurantCategories, {
    String? restaurantName,
  }) async {
    final epoch = _cartEpoch;
    final cached = await LeseatCartCache.load();
    final restoredCart = epoch == _cartEpoch &&
            cached != null &&
            cached.restaurantId == restaurantId
        ? cached.items
        : const <OrderItem>[];

    state = state.copyWith(
      activeRestaurantId: restaurantId,
      activeRestaurantName: restaurantName,
      isLoading: true,
      error: null,
    );

    try {
      print('🔵 RestaurantDetail: Loading menu for restaurant $restaurantId');

      final partnerId = int.parse(restaurantId);
      final partner = await _partnerDataSource.getPartner(partnerId);
      final response = await _partnerDataSource.getPartnerMenu(partnerId);
      final restaurantImagePath = MenuImageUtils.resolveOrAsset(
        partner.coverImageUrl ?? partner.logoUrl,
        _defaultMenuImage,
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
                imagePath: MenuImageUtils.resolveOrAsset(
                  itemDto.imageUrl,
                  _defaultMenuImage,
                ),
                categoryId: catDto.id.toString(),
                isPopular: itemDto.isPopular ?? false,
                optionGroups: MenuItemOptionGroups.fromApiMap(itemDto.options),
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
        cartItems: restoredCart,
        restaurantImagePath: restaurantImagePath,
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

  void addToCart(
    MenuItem item, {
    SelectedMenuOptions selectedOptions = const SelectedMenuOptions(),
    int quantity = 1,
  }) {
    final restaurantId = state.activeRestaurantId;
    final suffix = selectedOptions.cartKeySuffix();
    final cartItemId = restaurantId != null
        ? '$restaurantId:${item.id}${suffix.isEmpty ? '' : ':$suffix'}'
        : '${item.id}${suffix.isEmpty ? '' : ':$suffix'}';
    final unitPrice = selectedOptions.unitPriceForBase(item.price);

    final existingItemIndex = state.cartItems.indexWhere(
      (cartItem) => cartItem.id == cartItemId,
    );

    List<OrderItem> updatedCart;
    if (existingItemIndex >= 0) {
      updatedCart = List.from(state.cartItems);
      updatedCart[existingItemIndex] = updatedCart[existingItemIndex].copyWith(
        quantity: updatedCart[existingItemIndex].quantity + quantity,
      );
    } else {
      updatedCart = [
        ...state.cartItems,
        OrderItem(
          id: cartItemId,
          name: item.name,
          imagePath: item.imagePath,
          price: unitPrice,
          quantity: quantity,
          restaurantId: restaurantId,
          restaurantName: state.activeRestaurantName,
          menuItemId: item.id,
          selectedOptions: selectedOptions,
        ),
      ];
    }

    state = state.copyWith(cartItems: updatedCart);
    _persistCart();
  }

  void removeFromCart(String itemId) {
    final updatedCart = state.cartItems
        .where((item) => item.id != itemId)
        .toList();
    state = state.copyWith(cartItems: updatedCart);
    _persistCart();
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
    _persistCart();
  }

  Future<void> clearCart() async {
    _cartEpoch++;
    state = state.copyWith(cartItems: []);
    await LeseatCartCache.clear();
  }
}

final restaurantDetailProvider =
    StateNotifierProvider<RestaurantDetailNotifier, RestaurantDetailState>(
      (ref) {
        ref.keepAlive();
        return RestaurantDetailNotifier();
      },
    );
