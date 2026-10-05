import '../../../../core/utils/menu_item_options.dart';

class OrderItem {
  final String id;
  final String name;
  final String imagePath;
  final double price;
  final int quantity;
  final String? restaurantId;
  final String? restaurantName;
  final String? menuItemId;
  final SelectedMenuOptions selectedOptions;

  OrderItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.quantity,
    this.restaurantId,
    this.restaurantName,
    this.menuItemId,
    this.selectedOptions = const SelectedMenuOptions(),
  });

  double get total => price * quantity;

  String? get optionsDisplay =>
      selectedOptions.isEmpty ? null : selectedOptions.formatDisplay();

  OrderItem copyWith({
    String? id,
    String? name,
    String? imagePath,
    double? price,
    int? quantity,
    String? restaurantId,
    String? restaurantName,
    String? menuItemId,
    SelectedMenuOptions? selectedOptions,
  }) {
    return OrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      menuItemId: menuItemId ?? this.menuItemId,
      selectedOptions: selectedOptions ?? this.selectedOptions,
    );
  }
}
