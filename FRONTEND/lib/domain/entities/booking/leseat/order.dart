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

  OrderMoney get money => OrderMoney.calculate(
    subtotal: subtotal,
    deliveryFee: deliveryFee,
    discount: discount,
    items: items,
  );

  /// Display-safe value. Checkout must inspect [money] and reject invalid
  /// totals before it creates an order; this fallback is never chargeable.
  double get total => money.finalTotal ?? 0;

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
    bool clearVoucherCode = false,
  }) {
    return Order(
      id: id ?? this.id,
      restaurantName: restaurantName ?? this.restaurantName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      voucherCode: clearVoucherCode ? null : (voucherCode ?? this.voucherCode),
    );
  }
}

/// Validated, cent-precision checkout amounts derived from an order snapshot.
/// Invalid source money is rejected instead of being silently clamped.
class OrderMoney {
  final double validatedSubtotal;
  final double validatedDeliveryFee;
  final double validatedDiscount;
  final double? finalTotal;
  final String? error;

  const OrderMoney._({
    required this.validatedSubtotal,
    required this.validatedDeliveryFee,
    required this.validatedDiscount,
    required this.finalTotal,
    required this.error,
  });

  bool get isValid => error == null && finalTotal != null;

  factory OrderMoney.calculate({
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required List<OrderItem> items,
  }) {
    const maxCurrencyAmount = 90071992547409.91;
    final amounts = [subtotal, deliveryFee, discount];
    if (amounts.any(
      (amount) => !amount.isFinite || amount < 0 || amount > maxCurrencyAmount,
    )) {
      return const OrderMoney._(
        validatedSubtotal: 0,
        validatedDeliveryFee: 0,
        validatedDiscount: 0,
        finalTotal: null,
        error: 'Order amounts must be finite, non-negative currency values.',
      );
    }

    final subtotalCents = _toCents(subtotal);
    final deliveryFeeCents = _toCents(deliveryFee);
    final discountCents = _toCents(discount);
    var itemSubtotalCents = 0;

    for (final item in items) {
      if (!item.price.isFinite ||
          item.price < 0 ||
          item.price > maxCurrencyAmount ||
          item.quantity <= 0 ||
          (item.price * 100 - _toCents(item.price)).abs() > 0.000001) {
        return const OrderMoney._(
          validatedSubtotal: 0,
          validatedDeliveryFee: 0,
          validatedDiscount: 0,
          finalTotal: null,
          error: 'Order items must have valid prices and quantities.',
        );
      }
      final unitCents = _toCents(item.price);
      if (unitCents > 9007199254740991 ~/ item.quantity) {
        return const OrderMoney._(
          validatedSubtotal: 0,
          validatedDeliveryFee: 0,
          validatedDiscount: 0,
          finalTotal: null,
          error: 'Order subtotal exceeds the supported currency range.',
        );
      }
      final lineCents = unitCents * item.quantity;
      if (lineCents > 9007199254740991 - itemSubtotalCents) {
        return const OrderMoney._(
          validatedSubtotal: 0,
          validatedDeliveryFee: 0,
          validatedDiscount: 0,
          finalTotal: null,
          error: 'Order subtotal exceeds the supported currency range.',
        );
      }
      itemSubtotalCents += lineCents;
    }

    if (itemSubtotalCents != subtotalCents) {
      return const OrderMoney._(
        validatedSubtotal: 0,
        validatedDeliveryFee: 0,
        validatedDiscount: 0,
        finalTotal: null,
        error: 'Order subtotal does not match the current cart items.',
      );
    }

    final grossCents = subtotalCents + deliveryFeeCents;
    if (grossCents > 9007199254740991 || discountCents > grossCents) {
      return const OrderMoney._(
        validatedSubtotal: 0,
        validatedDeliveryFee: 0,
        validatedDiscount: 0,
        finalTotal: null,
        error: 'Order total exceeds its supported range or voucher discount exceeds the order amount.',
      );
    }

    return OrderMoney._(
      validatedSubtotal: subtotalCents / 100,
      validatedDeliveryFee: deliveryFeeCents / 100,
      validatedDiscount: discountCents / 100,
      finalTotal: (grossCents - discountCents) / 100,
      error: null,
    );
  }

  static int _toCents(double amount) => (amount * 100).round();
}
