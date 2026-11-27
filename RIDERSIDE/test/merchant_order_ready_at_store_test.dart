import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/utils/merchant_order_ops_utils.dart';

void main() {
  group('MerchantOrderOpsUtils.isReadyAtStore', () {
    test('ready order is "ready" until the rider picks it up', () {
      for (final s in [
        'searching_driver',
        'accepted',
        'ready_for_pickup',
        'driver_arrived_at_pickup',
      ]) {
        expect(MerchantOrderOpsUtils.isReadyAtStore(s, alreadyReady: true), isTrue, reason: s);
      }
    });

    test('an order the rider already picked up is out for delivery, not ready', () {
      for (final s in ['picked_up', 'in_progress', 'completed', 'cancelled']) {
        expect(MerchantOrderOpsUtils.isReadyAtStore(s, alreadyReady: true), isFalse, reason: s);
      }
    });

    test('never ready when the store has not marked it ready', () {
      expect(MerchantOrderOpsUtils.isReadyAtStore('accepted', alreadyReady: false), isFalse);
    });
  });
}
