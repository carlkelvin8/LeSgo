import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/provider/main/booking/checkout_provider.dart';
import '../../presentation/provider/main/booking/lesbuy/manual_order_provider.dart';
import '../../presentation/provider/main/booking/lesbuy/store_detail_provider.dart';
import '../../presentation/provider/main/booking/restaurant_detail_provider.dart';

/// Clears all persisted customer carts (LesEat, LesBuy, manual list, checkout).
class CartCleanup {
  CartCleanup._();

  static Future<void> clearAllCarts(WidgetRef ref) async {
    await Future.wait([
      ref.read(restaurantDetailProvider.notifier).clearCart(),
      ref.read(storeDetailProvider.notifier).clearCart(),
    ]);
    ref.read(manualOrderProvider.notifier).clearAll();
    ref.read(checkoutProvider.notifier).resetCheckout();
  }
}
