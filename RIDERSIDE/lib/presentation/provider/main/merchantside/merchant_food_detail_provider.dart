import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A size from the item's own options; `price` is added to the base price.
class MerchantFoodSizeOption {
  final String label;
  final double price;

  const MerchantFoodSizeOption({required this.label, this.price = 0});

  static const regular = MerchantFoodSizeOption(label: 'Regular');

  @override
  bool operator ==(Object other) =>
      other is MerchantFoodSizeOption && other.label == label && other.price == price;

  @override
  int get hashCode => Object.hash(label, price);
}

class MerchantFoodDetailInput {
  final String foodName;
  final String price;
  final List<MerchantFoodSizeOption> sizes;
  final List<MerchantFoodSizeOption> flavors;
  final List<MerchantFoodSizeOption> addons;

  const MerchantFoodDetailInput({
    required this.foodName,
    required this.price,
    required this.sizes,
    this.flavors = const [],
    this.addons = const [],
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MerchantFoodDetailInput &&
        other.foodName == foodName &&
        other.price == price &&
        _listEquals(other.sizes, sizes) &&
        _listEquals(other.flavors, flavors) &&
        _listEquals(other.addons, addons);
  }

  @override
  int get hashCode => Object.hash(
        foodName,
        price,
        Object.hashAll(sizes),
        Object.hashAll(flavors),
        Object.hashAll(addons),
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class MerchantFoodDetailState {
  final List<MerchantFoodSizeOption> sizes;
  final MerchantFoodSizeOption selectedSize;

  /// False when the menu item has no sizes of its own and `sizes` is just Regular.
  final bool hasSizeChoices;
  final List<MerchantFoodSizeOption> flavors;
  final MerchantFoodSizeOption? selectedFlavor;
  final List<MerchantFoodSizeOption> addons;
  final List<MerchantFoodSizeOption> selectedAddons;
  final int quantity;
  final double basePrice;

  const MerchantFoodDetailState({
    required this.sizes,
    required this.selectedSize,
    required this.quantity,
    required this.basePrice,
    this.hasSizeChoices = true,
    this.flavors = const [],
    this.selectedFlavor,
    this.addons = const [],
    this.selectedAddons = const [],
  });

  double get unitPrice =>
      basePrice +
      selectedSize.price +
      (selectedFlavor?.price ?? 0) +
      selectedAddons.fold<double>(0, (sum, addon) => sum + addon.price);

  double get subtotal => unitPrice * quantity;

  /// Shown on the cart line and sent as the order note.
  String get optionsLabel => [
        selectedSize.label,
        if (selectedFlavor != null) selectedFlavor!.label,
        ...selectedAddons.map((addon) => '+ ${addon.label}'),
      ].join(', ');

  /// The choices as the API expects them; the server re-prices from these.
  Map<String, dynamic>? get selectedOptions {
    final options = <String, dynamic>{
      if (hasSizeChoices)
        'size': {'label': selectedSize.label, 'price': selectedSize.price},
      if (selectedFlavor != null)
        'flavor': {'label': selectedFlavor!.label, 'price': selectedFlavor!.price},
      if (selectedAddons.isNotEmpty)
        'addons': [
          for (final addon in selectedAddons)
            {'label': addon.label, 'price': addon.price, 'quantity': 1},
        ],
    };
    return options.isEmpty ? null : options;
  }

  MerchantFoodDetailState copyWith({
    MerchantFoodSizeOption? selectedSize,
    MerchantFoodSizeOption? selectedFlavor,
    List<MerchantFoodSizeOption>? selectedAddons,
    int? quantity,
    double? basePrice,
  }) {
    return MerchantFoodDetailState(
      sizes: sizes,
      selectedSize: selectedSize ?? this.selectedSize,
      quantity: quantity ?? this.quantity,
      basePrice: basePrice ?? this.basePrice,
      hasSizeChoices: hasSizeChoices,
      flavors: flavors,
      selectedFlavor: selectedFlavor ?? this.selectedFlavor,
      addons: addons,
      selectedAddons: selectedAddons ?? this.selectedAddons,
    );
  }
}

class MerchantFoodDetailNotifier extends StateNotifier<MerchantFoodDetailState> {
  MerchantFoodDetailNotifier({required MerchantFoodDetailInput input})
      : super(
          MerchantFoodDetailState(
            sizes: _sizesOrRegular(input.sizes),
            selectedSize: _sizesOrRegular(input.sizes).first,
            hasSizeChoices: input.sizes.isNotEmpty,
            flavors: input.flavors,
            selectedFlavor: input.flavors.isEmpty ? null : input.flavors.first,
            addons: input.addons,
            quantity: 1,
            basePrice: _parseDisplayPrice(input.price),
          ),
        );

  static double _parseDisplayPrice(String rawPrice) {
    return double.parse(rawPrice.replaceAll('PHP ', '').replaceAll(',', ''));
  }

  static List<MerchantFoodSizeOption> _sizesOrRegular(List<MerchantFoodSizeOption> sizes) {
    return sizes.isEmpty ? const [MerchantFoodSizeOption.regular] : sizes;
  }

  void selectSize(MerchantFoodSizeOption size) {
    state = state.copyWith(selectedSize: size);
  }

  void selectFlavor(MerchantFoodSizeOption flavor) {
    state = state.copyWith(selectedFlavor: flavor);
  }

  void toggleAddon(MerchantFoodSizeOption addon) {
    final selected = [...state.selectedAddons];
    selected.contains(addon) ? selected.remove(addon) : selected.add(addon);
    state = state.copyWith(selectedAddons: selected);
  }

  void incrementQuantity() {
    state = state.copyWith(quantity: state.quantity + 1);
  }

  void decrementQuantity() {
    if (state.quantity <= 1) return;
    state = state.copyWith(quantity: state.quantity - 1);
  }
}

final merchantFoodDetailProvider = StateNotifierProvider.autoDispose
    .family<MerchantFoodDetailNotifier, MerchantFoodDetailState, MerchantFoodDetailInput>(
  (ref, input) => MerchantFoodDetailNotifier(input: input),
);
