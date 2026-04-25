class OrderItem {
  final String id;
  final String name;
  final String imagePath;
  final double price;
  final int quantity;

  OrderItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  OrderItem copyWith({
    String? id,
    String? name,
    String? imagePath,
    double? price,
    int? quantity,
  }) {
    return OrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}
