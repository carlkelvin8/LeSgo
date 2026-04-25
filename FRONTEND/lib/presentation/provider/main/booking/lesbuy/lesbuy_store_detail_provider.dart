import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../domain/entities/booking/lesbuy/store.dart';
import '../../../../../domain/entities/booking/lesbuy/product.dart';
import '../../../../../domain/entities/booking/lesbuy/cart_item.dart';
import '../../../../../domain/entities/booking/lesbuy/product_category.dart';
import '../../../../../data/data_source/partner_remote_datasource.dart';
import '../../../../../core/di/injection.dart';

class LesbuyStoreDetailState {
  final Store? store;
  final List<Product> products;
  final List<Product> filteredProducts;
  final List<ProductCategory> categories;
  final String? selectedCategoryId;
  final List<LesbuyCartItem> cartItems;
  final bool isLoading;
  final String? error;

  LesbuyStoreDetailState({
    this.store,
    this.products = const [],
    this.filteredProducts = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.cartItems = const [],
    this.isLoading = false,
    this.error,
  });

  double get cartTotal => cartItems.fold(0, (sum, item) => sum + item.totalPrice);

  int get cartItemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);

  LesbuyStoreDetailState copyWith({
    Store? store,
    List<Product>? products,
    List<Product>? filteredProducts,
    List<ProductCategory>? categories,
    String? selectedCategoryId,
    List<LesbuyCartItem>? cartItems,
    bool? isLoading,
    String? error,
    bool clearSelectedCategory = false,
  }) {
    return LesbuyStoreDetailState(
      store: store ?? this.store,
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      categories: categories ?? this.categories,
      selectedCategoryId: clearSelectedCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      cartItems: cartItems ?? this.cartItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LesbuyStoreDetailNotifier extends StateNotifier<LesbuyStoreDetailState> {
  final PartnerRemoteDataSource _partnerDataSource = getIt<PartnerRemoteDataSource>();

  LesbuyStoreDetailNotifier() : super(LesbuyStoreDetailState());

  Future<void> loadStore(Store store) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔵 LesbuyStoreDetail: Loading products for store ${store.id}');
      
      final response = await _partnerDataSource.getPartnerMenu(int.parse(store.id));
      
      // Convert menu items to products
      final allProducts = <Product>[];
      for (final catDto in response.data.categories) {
        if (catDto.availableItems != null) {
          for (final itemDto in catDto.availableItems!) {
            allProducts.add(Product(
              id: itemDto.id.toString(),
              name: itemDto.name,
              description: itemDto.description ?? '',
              price: itemDto.price,
              imagePath: itemDto.imageUrl ?? 'assets/images/book/lesbuy/Product.svg',
              categoryId: catDto.id.toString(),
              inStock: itemDto.isAvailable ?? true,
            ));
          }
        }
      }
      
      final categories = _buildCategories(allProducts);
      
      print('🟢 LesbuyStoreDetail: Loaded ${allProducts.length} products');
      
      state = state.copyWith(
        store: store,
        products: allProducts,
        filteredProducts: allProducts,
        categories: categories,
        isLoading: false,
      );
    } catch (e) {
      print('🔴 LesbuyStoreDetail: Error loading products - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load products. Please try again.',
      );
    }
  }

  List<ProductCategory> _buildCategories(List<Product> products) {
    final categoryIds = products.map((p) => p.categoryId).toSet();
    final categories = <ProductCategory>[
      ProductCategory(id: 'all', name: 'All', iconPath: ''),
    ];

    // Group products by category and create category objects
    for (final catId in categoryIds) {
      final categoryProducts = products.where((p) => p.categoryId == catId).toList();
      if (categoryProducts.isNotEmpty) {
        categories.add(ProductCategory(
          id: catId,
          name: 'Category $catId', // You can improve this with a category name map
          iconPath: '',
        ));
      }
    }

    return categories;
  }

  void selectCategory(String? categoryId) {
    if (categoryId == 'all' || categoryId == null) {
      state = state.copyWith(
        clearSelectedCategory: true,
        filteredProducts: state.products,
      );
    } else {
      final filtered = state.products
          .where((p) => p.categoryId == categoryId)
          .toList();
      state = state.copyWith(
        selectedCategoryId: categoryId,
        filteredProducts: filtered,
      );
    }
  }

  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = state.cartItems
        .indexWhere((item) => item.product.id == product.id);

    List<LesbuyCartItem> updatedCart;
    if (existingIndex >= 0) {
      updatedCart = List.from(state.cartItems);
      updatedCart[existingIndex] = updatedCart[existingIndex].copyWith(
        quantity: updatedCart[existingIndex].quantity + quantity,
      );
    } else {
      updatedCart = [
        ...state.cartItems,
        LesbuyCartItem(product: product, quantity: quantity),
      ];
    }

    state = state.copyWith(cartItems: updatedCart);
  }

  void removeFromCart(String productId) {
    final updatedCart = state.cartItems
        .where((item) => item.product.id != productId)
        .toList();
    state = state.copyWith(cartItems: updatedCart);
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final updatedCart = state.cartItems.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(cartItems: updatedCart);
  }

  void clearCart() {
    state = state.copyWith(cartItems: []);
  }

  void reset() {
    state = LesbuyStoreDetailState();
  }
}

final lesbuyStoreDetailProvider =
    StateNotifierProvider<LesbuyStoreDetailNotifier, LesbuyStoreDetailState>((ref) {
  return LesbuyStoreDetailNotifier();
});
