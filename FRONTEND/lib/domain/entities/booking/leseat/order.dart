import 'order_item.dart';

class Order {
  final String id;
  final String restaurantName;
  final String deliveryAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final String? voucherCode;

  Order({
    required this.id,
    required this.restaurantName,
    required this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0,
    this.voucherCode,
  });

  double get total => subtotal + deliveryFee - discount;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({
    String? id,
    String? restaurantName,
    String? deliveryAddress,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    String? voucherCode,
  }) {
    return Order(
      id: id ?? this.id,
      restaurantName: restaurantName ?? this.restaurantName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      voucherCode: voucherCode ?? this.voucherCode,
    );
  }
}
