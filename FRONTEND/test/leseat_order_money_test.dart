import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/domain/entities/booking/leseat/order.dart';
import 'package:lesgo/domain/entities/booking/leseat/order_item.dart';
import 'package:lesgo/presentation/provider/main/booking/checkout_provider.dart';

Order _order({
  required int quantity,
  required double discount,
  double fee = 20,
}) {
  final item = OrderItem(
    id: 'item-1',
    name: 'Meal',
    imagePath: '',
    price: 50,
    quantity: quantity,
  );
  return Order(
    id: 'order-1',
    restaurantName: 'Restaurant',
    deliveryAddress: 'Address',
    items: [item],
    subtotal: item.total,
    deliveryFee: fee,
    discount: discount,
    voucherCode: 'SAVE10',
  );
}

void main() {
  group('CheckoutState', () {
    test('preserves validated location and fare state through copyWith', () {
      final state = CheckoutState(
        hasValidDeliveryFee: true,
        hasValidPickupLocation: true,
        hasValidDropoffLocation: true,
      );
      final updated = state.copyWith(isLoading: true);
      expect(updated.hasValidDeliveryFee, isTrue);
      expect(updated.hasValidPickupLocation, isTrue);
      expect(updated.hasValidDropoffLocation, isTrue);
    });
  });

  group('OrderMoney', () {
    test('accepts a voucher against its original cart total', () {
      final order = _order(quantity: 2, discount: 10);
      expect(order.money.isValid, isTrue);
      expect(order.money.finalTotal, 110);
    });

    test('recalculates cart money after quantity decreases', () {
      final oldOrder = _order(quantity: 2, discount: 10);
      final changed = _order(quantity: 1, discount: 0);
      expect(oldOrder.money.isValid, isTrue);
      expect(changed.money.validatedSubtotal, 50);
      expect(changed.money.finalTotal, 70);
    });

    test('recalculates cart money after an item is removed', () {
      final remaining = Order(
        id: 'order-1',
        restaurantName: 'Restaurant',
        deliveryAddress: 'Address',
        items: const [],
        subtotal: 0,
        deliveryFee: 20,
      );
      expect(remaining.money.isValid, isTrue);
      expect(remaining.money.finalTotal, 20);
    });

    test('rejects a discount larger than subtotal and delivery fee', () {
      final order = _order(quantity: 1, discount: 71);
      expect(order.money.isValid, isFalse);
      expect(order.money.error, contains('discount exceeds'));
    });

    test(
      'accepts exactly zero final total without producing a negative value',
      () {
        final order = _order(quantity: 1, discount: 70);
        expect(order.money.isValid, isTrue);
        expect(order.money.finalTotal, 0);
      },
    );

    test('rejects a stale subtotal that no longer matches items', () {
      final order = _order(quantity: 1, discount: 0).copyWith(subtotal: 100);
      expect(order.money.isValid, isFalse);
      expect(order.money.error, contains('does not match'));
    });
  });
}
