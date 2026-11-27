import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/domain/entities/booking/lesbuy/cart_item.dart';
import 'package:lesgo/domain/entities/booking/lesbuy/product.dart';
import 'package:lesgo/presentation/provider/main/booking/lesbuy/lesbuy_checkout_provider.dart';
import 'package:lesgo/presentation/provider/main/booking/lesbuy/store_detail_provider.dart';
import 'package:lesgo/presentation/screens/main/booking/order_digital_payment_screen.dart';

Product _p(String id, double price, {bool inStock = true}) => Product(
  id: id,
  name: 'Item $id',
  description: '',
  price: price,
  imagePath: '',
  categoryId: 'c',
  inStock: inStock,
);

void main() {
  group('reconcileCartWithMenu', () {
    test('refreshes prices, keeps quantity, drops missing/out-of-stock', () {
      final restored = [
        LesbuyCartItem(product: _p('1', 100), quantity: 2),
        LesbuyCartItem(product: _p('2', 50), quantity: 1),
        LesbuyCartItem(product: _p('3', 20), quantity: 4),
      ];
      final menu = [_p('1', 120), _p('3', 20, inStock: false)];
      final out = reconcileCartWithMenu(restored, menu);
      expect(out.length, 1);
      expect(out.first.product.price, 120);
      expect(out.first.quantity, 2);
    });
  });

  group('isInvoicePaidStatus', () {
    test('only paid/completed count as paid', () {
      expect(isInvoicePaidStatus('PAID'), isTrue);
      expect(isInvoicePaidStatus('completed'), isTrue);
      expect(isInvoicePaidStatus('pending'), isFalse);
      expect(isInvoicePaidStatus('expired'), isFalse);
      expect(isInvoicePaidStatus(null), isFalse);
    });
  });

  test('checkout state does not invent a delivery fee', () {
    const s = LesbuyCheckoutState();
    expect(s.deliveryFee, 0);
    expect(s.deliveryFeeKnown, isFalse);
  });
}
