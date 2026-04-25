import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/booking/leseat/menu_item.dart';

class MenuItemDetailState {
  final MenuItem item;
  final String? selectedSize;
  final int quantity;

  MenuItemDetailState({
    required this.item,
    this.selectedSize,
    this.quantity = 1,
  });

  double get sizeMultiplier {
    if (selectedSize == null || item.sizeOptions == null) return 1.0;
    
    final index = item.sizeOptions!.indexOf(selectedSize!);
    if (index == -1) return 1.0;
    
    // Price increases by 10% for each size up from the first option
    return 1.0 + (index * 0.1);
  }

  double get adjustedPrice => item.price * sizeMultiplier;
  double get totalPrice => adjustedPrice * quantity;

  MenuItemDetailState copyWith({
    MenuItem? item,
    String? selectedSize,
    int? quantity,
  }) {
    return MenuItemDetailState(
      item: item ?? this.item,
      selectedSize: selectedSize ?? this.selectedSize,
      quantity: quantity ?? this.quantity,
    );
  }
}

class MenuItemDetailNotifier extends StateNotifier<MenuItemDetailState> {
  MenuItemDetailNotifier(MenuItem item)
    : super(MenuItemDetailState(
        item: item,
        // Default to first size option if available
        selectedSize: item.sizeOptions?.isNotEmpty == true 
            ? item.sizeOptions!.first 
            : null,
      ));

  void selectSize(String size) {
    state = state.copyWith(selectedSize: size);
  }

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

final menuItemDetailProvider =
    StateNotifierProvider.family<
      MenuItemDetailNotifier,
      MenuItemDetailState,
      MenuItem
    >((ref, item) => MenuItemDetailNotifier(item));
