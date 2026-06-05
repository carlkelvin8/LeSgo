import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../domain/entities/booking/lesbuy/product.dart';
import '../../../../../domain/entities/booking/lesbuy/cart_item.dart';
import '../../../../../data/data_source/partner_remote_datasource.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/services/lesbuy_cart_cache.dart';

class StoreDetailState {
  final String? partnerStoreId;
  final String? storeName;
  final List<Product> products;
  final List<Product> filteredProducts;
  final List<String> categories;
  final Map<String, String> categoryNames;
  final String? selectedCategoryId;
  final String? selectedCategoryName;
  final List<LesbuyCartItem> cartItems;
  final bool isLoading;
  final String? error;

  StoreDetailState({
    this.partnerStoreId,
    this.storeName,
    this.products = const [],
    this.filteredProducts = const [],
    this.categories = const [],
    this.categoryNames = const {},
    this.selectedCategoryId,
    this.selectedCategoryName,
    this.cartItems = const [],
    this.isLoading = false,
    this.error,
  });

  StoreDetailState copyWith({
    String? partnerStoreId,
    String? storeName,
    List<Product>? products,
    List<Product>? filteredProducts,
    List<String>? categories,
    Map<String, String>? categoryNames,
    String? selectedCategoryId,
    String? selectedCategoryName,
    List<LesbuyCartItem>? cartItems,
    bool? isLoading,
    String? error,
  }) {
    return StoreDetailState(
      partnerStoreId: partnerStoreId ?? this.partnerStoreId,
      storeName: storeName ?? this.storeName,
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      categories: categories ?? this.categories,
      categoryNames: categoryNames ?? this.categoryNames,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedCategoryName: selectedCategoryName ?? this.selectedCategoryName,
      cartItems: cartItems ?? this.cartItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get cartItemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);
  
  double get cartTotal => cartItems.fold(
      0, (sum, item) => sum + (item.product.price * item.quantity));
}

class StoreDetailNotifier extends StateNotifier<StoreDetailState> {
  final PartnerRemoteDataSource _partnerDataSource = getIt<PartnerRemoteDataSource>();

  StoreDetailNotifier() : super(StoreDetailState()) {
    _restoreCachedCart();
  }

  Future<void> _restoreCachedCart() async {
    final cached = await LesbuyCartCache.load();
    if (cached == null || cached.items.isEmpty) return;

    state = state.copyWith(
      partnerStoreId: cached.storeId,
      storeName: cached.storeName,
      cartItems: cached.items,
    );
  }

  void _persistCart() {
    LesbuyCartCache.save(
      storeId: state.partnerStoreId,
      storeName: state.storeName,
      items: state.cartItems,
    );
  }

  Future<void> loadStoreDetails(String storeId, List<String> categories) async {
    final cached = await LesbuyCartCache.load();
    final restoredCart =
        cached != null && cached.storeId == storeId ? cached.items : const <LesbuyCartItem>[];

    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔵 StoreDetail: Loading products for store $storeId');
      
      final response = await _partnerDataSource.getPartnerMenu(int.parse(storeId));
      
      // Convert menu items to products
      final allProducts = <Product>[];
      final categoryNames = <String, String>{'popular': 'Popular Items'};
      for (final catDto in response.data.categories) {
        categoryNames[catDto.id.toString()] = catDto.name;
        if (catDto.availableItems != null) {
          for (final itemDto in catDto.availableItems!) {
            allProducts.add(Product(
              id: itemDto.id.toString(),
              name: itemDto.name,
              description: itemDto.description ?? '',
              price: itemDto.price,
              imagePath: itemDto.imageUrl ?? 'assets/images/book/lesbuy/Product.svg',
              categoryId: catDto.id.toString(),
              isPopular: itemDto.isPopular ?? itemDto.isFeatured ?? false,
              inStock: itemDto.isAvailable ?? true,
            ));
          }
        }
      }
      
      final storeName = response.data.partner.name;
      final allCategories = ['popular', ...response.data.categories.map((c) => c.id.toString())];
      
      print('🟢 StoreDetail: Loaded ${allProducts.length} products');

      state = state.copyWith(
        partnerStoreId: storeId,
        storeName: storeName,
        products: allProducts,
        categories: allCategories,
        categoryNames: categoryNames,
        selectedCategoryId: 'popular',
        selectedCategoryName: 'Popular Items',
        cartItems: restoredCart,
        isLoading: false,
      );
      
      _filterProducts();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void selectCategory(String categoryId) {
    final categoryName = state.categoryNames[categoryId] ??
        (categoryId == 'popular' ? 'Popular Items' : categoryId);

    state = state.copyWith(
      selectedCategoryId: categoryId,
      selectedCategoryName: categoryName,
    );
    _filterProducts();
  }

  void _filterProducts() {
    List<Product> filtered;
    if (state.selectedCategoryId == 'popular') {
      filtered = state.products.where((p) => p.isPopular).toList();
      if (filtered.isEmpty) {
        filtered = state.products;
      }
    } else {
      filtered = state.products
          .where((p) => p.categoryId == state.selectedCategoryId)
          .toList();
    }

    state = state.copyWith(filteredProducts: filtered);
  }

  void addToCart(Product product) {
    final currentItems = [...state.cartItems];
    final index = currentItems.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      currentItems[index] = currentItems[index].copyWith(
        quantity: currentItems[index].quantity + 1,
      );
    } else {
      currentItems.add(LesbuyCartItem(product: product, quantity: 1));
    }

    state = state.copyWith(cartItems: currentItems);
    _persistCart();
  }

  void updateCartItemQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      removeFromCart(product);
      return;
    }

    final currentItems = [...state.cartItems];
    final index = currentItems.indexWhere((item) => item.product.id == product.id);
    if (index < 0) return;

    currentItems[index] = currentItems[index].copyWith(quantity: quantity);
    state = state.copyWith(cartItems: currentItems);
    _persistCart();
  }

  void clearCart() {
    state = state.copyWith(cartItems: []);
    LesbuyCartCache.clear();
  }

  void removeFromCart(Product product) {
    final currentItems = [...state.cartItems];
    final index = currentItems.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      if (currentItems[index].quantity > 1) {
        currentItems[index] = currentItems[index].copyWith(
          quantity: currentItems[index].quantity - 1,
        );
      } else {
        currentItems.removeAt(index);
      }
      state = state.copyWith(cartItems: currentItems);
      _persistCart();
    }
  }
}

final storeDetailProvider =
    StateNotifierProvider<StoreDetailNotifier, StoreDetailState>((ref) {
  ref.keepAlive();
  return StoreDetailNotifier();
});
