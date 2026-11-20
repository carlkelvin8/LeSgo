import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/presentation/provider/cart/cart_provider.dart';

void main() {
  group('CartNotifier menuItemId', () {
    test('keeps the menu item id on the cart line', () {
      final cart = CartNotifier();

      cart.addItem(
        name: 'hshaha',
        size: 'Regular',
        unitPrice: 100,
        menuItemId: 3499,
      );

      expect(cart.state.items, hasLength(1));
      expect(cart.state.items.single.menuItemId, 3499);
    });

    test('merges the same menu item and size into one line', () {
      final cart = CartNotifier();

      cart.addItem(name: 'hshaha', size: 'Regular', unitPrice: 100, menuItemId: 3499);
      cart.addItem(name: 'hshaha', size: 'Regular', unitPrice: 100, menuItemId: 3499);

      expect(cart.state.items, hasLength(1));
      expect(cart.state.items.single.quantity, 2);
    });

    test('does not merge different menu items that share a name', () {
      final cart = CartNotifier();

      cart.addItem(name: 'hshaha', size: 'Regular', unitPrice: 10, menuItemId: 3001);
      cart.addItem(name: 'hshaha', size: 'Regular', unitPrice: 100, menuItemId: 3499);

      expect(cart.state.items, hasLength(2));
      expect(cart.state.items.map((i) => i.menuItemId), [3001, 3499]);
    });

    test('copyWith preserves the menu item id', () {
      final cart = CartNotifier();
      cart.addItem(name: 'hshaha', size: 'Regular', unitPrice: 100, menuItemId: 3499);

      cart.incrementItemQuantity(cart.state.items.single.id);

      expect(cart.state.items.single.quantity, 2);
      expect(cart.state.items.single.menuItemId, 3499);
    });
  });
}
