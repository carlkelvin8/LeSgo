import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lezgo_rider/domain/models/rider_order.dart';
import 'package:lezgo_rider/core/utils/rider_route_utils.dart';

void main() {
  for (final status in ['accepted', 'driver_arrived_at_pickup', 'picked_up']) {
    test('manual purchase and customer locations remain distinct for $status', () {
      final order = RiderOrder.fromJson({
        'id': 7, 'service_id': 4, 'status': status,
        'pickup_address': 'SM Fairview, Quirino Highway, Quezon City',
        'pickup_lat': '14.7360000', 'pickup_lng': '121.0580000',
        'dropoff_address': 'Customer home',
        'dropoff_lat': '14.7200000', 'dropoff_lng': '121.0400000',
        'meta': {'order_type': 'lesbuy_manual'},
      });
      expect(order.pickupAddress, 'SM Fairview, Quirino Highway, Quezon City');
      expect(order.dropoffAddress, 'Customer home');
      final expected = status == 'picked_up' ? const LatLng(14.72, 121.04) : const LatLng(14.736, 121.058);
      expect(RiderRouteUtils.navigationTarget(order).destination, expected);
      expect(RiderRouteUtils.navigationTargetForStatus(status: status,
        pickupLat: order.pickupLat, pickupLng: order.pickupLng,
        dropoffLat: order.dropoffLat, dropoffLng: order.dropoffLng).destination, expected);
    });
  }
}
