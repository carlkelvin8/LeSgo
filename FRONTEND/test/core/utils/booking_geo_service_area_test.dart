import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/utils/booking_geo_utils.dart';

void main() {
  test('Claveria center is inside service area', () {
    expect(
      BookingGeoUtils.isInsideServiceArea(
        BookingGeoUtils.defaultLat,
        BookingGeoUtils.defaultLng,
      ),
      isTrue,
    );
  });

  test('Manila is outside Claveria service radius', () {
    expect(
      BookingGeoUtils.isInsideServiceArea(14.5995, 120.9842),
      isFalse,
    );
  });

  test('resolveCoords uses pin when valid', () {
    final pin = BookingGeoUtils.resolveCoords(
      lat: 8.5,
      lng: 124.6,
    );
    expect(pin.latitude, closeTo(8.5, 0.001));
  });

  test('resolveCoords falls back to Claveria when invalid', () {
    final pin = BookingGeoUtils.resolveCoords(lat: 0, lng: 0);
    expect(pin, BookingGeoUtils.defaultLatLng);
  });
}

