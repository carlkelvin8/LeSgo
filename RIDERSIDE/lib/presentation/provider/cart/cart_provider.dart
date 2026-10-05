import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final String id;
  final String name;
  final String size;
  final double unitPrice;
  final int quantity;

  const CartItem({
    required this.id,
    required this.name,
    required this.size,
    required this.unitPrice,
    required this.quantity,
  });

  CartItem copyWith({
    String? id,
    String? name,
    String? size,
    double? unitPrice,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Cart state with derived totals for thin-screen rendering.
class CartState {
  final List<CartItem> items;

  const CartState({
    this.items = const [],
  });

  int get itemCount =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold<double>(
        0,
        (sum, item) => sum + (item.unitPrice * item.quantity),
      );

  double get tax => subtotal * 0.12;

  double get total => subtotal + tax;

  CartState copyWith({
    List<CartItem>? items,
  }) {
    return CartState(
      items: items ?? this.items,
    );
  }
}

/// Cart notifier to manage cart state
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  double parseDisplayPrice(String rawPrice) {
    return double.parse(rawPrice.replaceAll('PHP ', '').replaceAll(',', ''));
  }

  /// Add item to cart. Merges same food+size by increasing quantity.
  void addItem({
    required String name,
    required String size,
    required double unitPrice,
    int quantity = 1,
  }) {
    if (quantity <= 0) return;

    final existingIndex = state.items.indexWhere(
      (item) => item.name == name && item.size == size,
    );

    if (existingIndex >= 0) {
      final updated = [...state.items];
      final existing = updated[existingIndex];
      updated[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
      state = state.copyWith(items: updated);
      return;
    }

    final newItem = CartItem(
      id: '${name}_${size}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      size: size,
      unitPrice: unitPrice,
      quantity: quantity,
    );

    state = state.copyWith(items: [...state.items, newItem]);
  }

  /// Remove item from cart
  void removeItem(String itemId) {
    final newItems = state.items.where((item) => item.id != itemId).toList();
    state = state.copyWith(items: newItems);
  }

  void incrementItemQuantity(String itemId) {
    final updatedItems = state.items.map((item) {
      if (item.id != itemId) return item;
      return item.copyWith(quantity: item.quantity + 1);
    }).toList();
    state = state.copyWith(items: updatedItems);
  }

  void decrementItemQuantity(String itemId) {
    final updatedItems = state.items.map((item) {
      if (item.id != itemId) return item;
      final nextQuantity = item.quantity - 1;
      return item.copyWith(quantity: nextQuantity < 1 ? 1 : nextQuantity);
    }).toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Clear entire cart
  void clearCart() {
    state = const CartState(items: []);
  }

  /// Get cart item count
  int get count => state.itemCount;
}

/// Cart provider for global cart state
final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);
