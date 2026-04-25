import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cart_provider.dart';

class CartCheckoutState {
  final double subtotal;
  final int itemCount;
  final double deliveryFee;

  const CartCheckoutState({
    required this.subtotal,
    required this.itemCount,
    required this.deliveryFee,
  });

  double get total => subtotal + deliveryFee;
}

final cartCheckoutProvider = Provider<CartCheckoutState>((ref) {
  final cartState = ref.watch(cartProvider);

  return CartCheckoutState(
    subtotal: cartState.subtotal,
    itemCount: cartState.itemCount,
    deliveryFee: 50,
  );
});
