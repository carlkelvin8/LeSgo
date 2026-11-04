import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/data/data_source/dto/merchant/order_dto.dart';
import 'package:lezgo_rider/domain/models/rider_order.dart';

Map<String, dynamic> _order({Map<String, dynamic>? branch}) => {
      'id': 10,
      'customer_id': 1,
      'service_id': 3,
      'status': 'pending',
      'pickup_address': '300 Katipunan Ave, Quezon City',
      'pickup_lat': '14.6392',
      'pickup_lng': '121.0770',
      'pickup_contact_name': 'Kape Co – Katipunan',
      'dropoff_address': '456 Mabini Ave',
      'dropoff_lat': 14.609,
      'dropoff_lng': 121.0,
      'payment_method': 'cash',
      'payment_status': 'pending',
      'created_at': '2026-10-28T00:00:00Z',
      'updated_at': '2026-10-28T00:00:00Z',
      'meta': {if (branch != null) 'branch': branch, 'subtotal': 100},
    };

void main() {
  test('merchant order reads branch from meta', () {
    final order = OrderDto.fromJson(_order(branch: {'id': 7, 'name': 'Katipunan'}));
    expect(order.branchId, 7);
    expect(order.branchName, 'Katipunan');
  });

  test('merchant order without branch keeps fields null', () {
    final order = OrderDto.fromJson(_order());
    expect(order.branchId, isNull);
    expect(order.branchName, isNull);
  });

  test('rider sees store and branch with the pickup address', () {
    final order = RiderOrder.fromJson(_order(branch: {'id': 7, 'name': 'Katipunan'}));
    expect(order.pickupBranchName, 'Katipunan');
    expect(order.pickupDisplay, 'Kape Co – Katipunan · 300 Katipunan Ave, Quezon City');
    expect(order.pickupLat, closeTo(14.6392, 1e-6));
  });

  test('non-store rider orders show the plain address', () {
    final order = RiderOrder.fromJson(_order());
    expect(order.pickupStoreLabel, isNull);
    expect(order.pickupDisplay, '300 Katipunan Ave, Quezon City');
  });
}
