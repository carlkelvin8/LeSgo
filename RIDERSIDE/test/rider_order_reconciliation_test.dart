import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/domain/models/rider_order.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_orders_state.dart';

RiderOrder order(String status, {int driver = 5}) => RiderOrder.fromJson({
  'id': 42,
  'status': status,
  'driver_id': driver,
  'service_id': 1,
});

void main() {
  for (final status in ['cancelled', 'completed']) {
    test('$status server order removes stale active booking', () {
      expect(
        reconcileActiveOrders([order(status)], order('accepted'), 5),
        isEmpty,
      );
    });
  }

  test('reassignment removes the previous rider active booking', () {
    expect(
      reconcileActiveOrders(
        [order('accepted', driver: 9)],
        order('accepted'),
        5,
      ),
      isEmpty,
    );
  });

  test('paginated response preserves missing locally accepted booking', () {
    final current = order('accepted');
    expect(reconcileActiveOrders([], current, 5), [current]);
  });

  test('cached booking belonging to a different rider is never restored', () {
    expect(reconcileActiveOrders([order('accepted')], null, 9), isEmpty);
    expect(reconcileActiveOrders([order('accepted')], null, null), isEmpty);
  });

  test('fresh status replaces old status without duplicating the booking', () {
    final fresh = order('picked_up');
    expect(reconcileActiveOrders([fresh], order('accepted'), 5), [fresh]);
  });

  test('finished action clears its order id', () {
    final state = RiderOrdersState(
      action: RiderOrderAction.accepting,
      actionOrderId: 42,
    );
    expect(state.copyWith(action: RiderOrderAction.none).actionOrderId, isNull);
  });
}
