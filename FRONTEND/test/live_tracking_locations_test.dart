import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/utils/booking_geo_utils.dart';
import 'package:lesgo/presentation/provider/tracking/live_tracking_provider.dart';

void main() {
  group('parseTrackingLocations', () {
    test('reads the nested pickup/dropoff the API sends', () {
      final loc = parseTrackingLocations({
        'pickup': {'address': 'A', 'latitude': 18.607, 'longitude': 121.0825},
        'dropoff': {'address': 'B', 'latitude': 18.612, 'longitude': 121.09},
      });
      expect(loc.pickup.latitude, 18.607);
      expect(loc.pickup.longitude, 121.0825);
      expect(loc.dropoff.latitude, 18.612);
      expect(loc.dropoff.longitude, 121.09);
    });

    test('still accepts flat keys and numeric strings', () {
      final loc = parseTrackingLocations({
        'pickup_lat': '14.5995',
        'pickup_lng': 120.9842,
        'dropoff_latitude': 14.609,
        'dropoff_longitude': '121.0',
      });
      expect(loc.pickup.latitude, 14.5995);
      expect(loc.pickup.longitude, 120.9842);
      expect(loc.dropoff.latitude, 14.609);
      expect(loc.dropoff.longitude, 121.0);
    });

    test('falls back to the default location, dropoff to the pickup', () {
      final empty = parseTrackingLocations({});
      expect(empty.pickup.latitude, BookingGeoUtils.defaultLat);
      expect(empty.pickup.longitude, BookingGeoUtils.defaultLng);
      expect(empty.dropoff, empty.pickup);

      final onlyPickup = parseTrackingLocations({
        'pickup': {'latitude': 10.0, 'longitude': 123.0},
      });
      expect(onlyPickup.dropoff, onlyPickup.pickup);
    });
  });
}
