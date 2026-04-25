import 'product.dart';

class LesbuyCartItem {
  final Product product;
  final int quantity;

  LesbuyCartItem({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.price * quantity;

  LesbuyCartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return LesbuyCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
