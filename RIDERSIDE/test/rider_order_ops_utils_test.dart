import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/utils/rider_order_ops_utils.dart';

void main() {
  test('canCancel allows pre-pickup active statuses', () {
    expect(RiderOrderOpsUtils.canCancel('accepted'), isTrue);
    expect(RiderOrderOpsUtils.canCancel('ready_for_pickup'), isTrue);
    expect(RiderOrderOpsUtils.canCancel('driver_arrived_at_pickup'), isTrue);
    expect(RiderOrderOpsUtils.canCancel('in_progress'), isTrue);
  });

  test('canCancel blocks terminal and post-pickup statuses', () {
    expect(RiderOrderOpsUtils.canCancel('picked_up'), isFalse);
    expect(RiderOrderOpsUtils.canCancel('completed'), isFalse);
    expect(RiderOrderOpsUtils.canCancel('cancelled'), isFalse);
    expect(RiderOrderOpsUtils.canCancel(null), isFalse);
  });
}
