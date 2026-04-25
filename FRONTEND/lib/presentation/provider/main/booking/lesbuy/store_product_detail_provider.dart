import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../domain/entities/booking/lesbuy/product.dart';

class StoreProductDetailState {
  final Product product;
  final int quantity;

  StoreProductDetailState({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  StoreProductDetailState copyWith({
    Product? product,
    int? quantity,
  }) {
    return StoreProductDetailState(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class StoreProductDetailNotifier extends StateNotifier<StoreProductDetailState> {
  StoreProductDetailNotifier(Product product)
      : super(StoreProductDetailState(product: product));

  void incrementQuantity() {
    state = state.copyWith(quantity: state.quantity + 1);
  }

  void decrementQuantity() {
    if (state.quantity > 1) {
      state = state.copyWith(quantity: state.quantity - 1);
    }
  }

  void setQuantity(int quantity) {
    if (quantity >= 1) {
      state = state.copyWith(quantity: quantity);
    }
  }
}

final storeProductDetailProvider = StateNotifierProvider.family<
    StoreProductDetailNotifier,
    StoreProductDetailState,
    Product>((ref, product) => StoreProductDetailNotifier(product));
