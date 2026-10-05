import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/booking/leseat/menu_item.dart';
import '../../../../core/utils/menu_item_options.dart';

class MenuItemDetailState {
  final MenuItem item;
  final MenuOptionChoice? selectedSize;
  final MenuOptionChoice? selectedFlavor;
  final Map<String, int> addonQuantities;
  final int quantity;

  MenuItemDetailState({
    required this.item,
    this.selectedSize,
    this.selectedFlavor,
    Map<String, int>? addonQuantities,
    this.quantity = 1,
  }) : addonQuantities = addonQuantities ?? const {};

  SelectedMenuOptions get selectedOptions {
    final addons = <SelectedAddon>[];
    for (final addon in item.optionGroups.addons) {
      final qty = addonQuantities[addon.label] ?? 0;
      if (qty > 0) {
        addons.add(SelectedAddon(choice: addon, quantity: qty));
      }
    }

    return SelectedMenuOptions(
      size: selectedSize,
      flavor: selectedFlavor,
      addons: addons,
    );
  }

  double get adjustedPrice =>
      selectedOptions.unitPriceForBase(item.price);

  double get totalPrice => adjustedPrice * quantity;

  bool get isValid {
    if (item.optionGroups.hasSizes && selectedSize == null) return false;
    if (item.optionGroups.hasFlavors && selectedFlavor == null) return false;
    return true;
  }

  MenuItemDetailState copyWith({
    MenuItem? item,
    MenuOptionChoice? selectedSize,
    MenuOptionChoice? selectedFlavor,
    Map<String, int>? addonQuantities,
    int? quantity,
    bool clearSize = false,
    bool clearFlavor = false,
  }) {
    return MenuItemDetailState(
      item: item ?? this.item,
      selectedSize: clearSize ? null : (selectedSize ?? this.selectedSize),
      selectedFlavor:
          clearFlavor ? null : (selectedFlavor ?? this.selectedFlavor),
      addonQuantities: addonQuantities ?? this.addonQuantities,
      quantity: quantity ?? this.quantity,
    );
  }
}

class MenuItemDetailNotifier extends StateNotifier<MenuItemDetailState> {
  MenuItemDetailNotifier(MenuItem item)
      : super(
          MenuItemDetailState(
            item: item,
            selectedSize: item.optionGroups.sizes.length == 1
                ? item.optionGroups.sizes.first
                : null,
            selectedFlavor: item.optionGroups.flavors.length == 1
                ? item.optionGroups.flavors.first
                : null,
          ),
        );

  void selectSize(MenuOptionChoice size) {
    state = state.copyWith(selectedSize: size);
  }

  void selectFlavor(MenuOptionChoice flavor) {
    state = state.copyWith(selectedFlavor: flavor);
  }

  void setAddonQuantity(MenuOptionChoice addon, int quantity) {
    final updated = Map<String, int>.from(state.addonQuantities);
    if (quantity <= 0) {
      updated.remove(addon.label);
    } else {
      updated[addon.label] = quantity;
    }
    state = state.copyWith(addonQuantities: updated);
  }

  void incrementQuantity() {
    state = state.copyWith(quantity: state.quantity + 1);
  }

  void decrementQuantity() {
    if (state.quantity > 1) {
      state = state.copyWith(quantity: state.quantity - 1);
    }
  }
}

final menuItemDetailProvider =
    StateNotifierProvider.family<
      MenuItemDetailNotifier,
      MenuItemDetailState,
      MenuItem
    >((ref, item) => MenuItemDetailNotifier(item));
