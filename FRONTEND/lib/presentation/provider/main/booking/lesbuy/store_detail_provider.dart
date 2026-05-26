import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../domain/entities/booking/lesbuy/product.dart';
import '../../../../../domain/entities/booking/lesbuy/cart_item.dart';
import '../../../../../data/data_source/partner_remote_datasource.dart';
import '../../../../../core/di/injection.dart';

class StoreDetailState {
  final String? partnerStoreId;
  final String? storeName;
  final List<Product> products;
  final List<Product> filteredProducts;
  final List<String> categories;
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

  StoreDetailNotifier() : super(StoreDetailState());

  Future<void> loadStoreDetails(String storeId, List<String> categories) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔵 StoreDetail: Loading products for store $storeId');
      
      final response = await _partnerDataSource.getPartnerMenu(int.parse(storeId));
      
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
      
      final storeName = response.data.partner.name;
      final allCategories = ['popular', ...response.data.categories.map((c) => c.id.toString())];
      
      print('🟢 StoreDetail: Loaded ${allProducts.length} products');

      state = state.copyWith(
        partnerStoreId: storeId,
        storeName: storeName,
        products: allProducts,
        categories: allCategories,
        selectedCategoryId: 'popular',
        selectedCategoryName: 'Popular Items',
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
    String categoryName = '';
    if (categoryId == 'popular') {
      categoryName = 'Popular Items';
    } else {
      categoryName = categoryId.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
    }

    state = state.copyWith(
      selectedCategoryId: categoryId,
      selectedCategoryName: categoryName,
    );
    _filterProducts();
  }

  void _filterProducts() {
    if (state.selectedCategoryId == 'popular') {
      state = state.copyWith(
        filteredProducts: state.products.where((p) => p.isPopular).toList(),
      );
    } else {
      state = state.copyWith(
        filteredProducts: state.products
            .where((p) => p.categoryId == state.selectedCategoryId)
            .toList(),
      );
    }
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
    }
  }
}

final storeDetailProvider =
    StateNotifierProvider<StoreDetailNotifier, StoreDetailState>((ref) {
  return StoreDetailNotifier();
});
