import '../di/injection.dart';
import '../utils/booking_geo_utils.dart';
import '../../data/data_source/geofence_remote_datasource.dart';

class ServiceAreaResult {
  final bool isAvailable;
  final String messageEn;
  final String messageTl;

  const ServiceAreaResult({
    required this.isAvailable,
    required this.messageEn,
    required this.messageTl,
  });

  static const available = ServiceAreaResult(
    isAvailable: true,
    messageEn: '',
    messageTl: '',
  );

  static ServiceAreaResult unavailable() => const ServiceAreaResult(
        isAvailable: false,
        messageEn:
            'LesGo is not available in your area yet. We currently serve Cagayan de Oro and nearby towns.',
        messageTl:
            'Hindi pa available ang LesGo sa iyong lugar. Kasalukuyang serbisyo: Cagayan de Oro at kalapit na bayan.',
      );
}

/// Validates pickup/dropoff against geofence API with CDO-radius fallback.
class ServiceAreaChecker {
  ServiceAreaChecker._();

  static Future<ServiceAreaResult> checkCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    if (!BookingGeoUtils.hasValidCoords(latitude, longitude)) {
      return ServiceAreaResult.unavailable();
    }

    try {
      final result = await getIt<GeofenceRemoteDataSource>().checkLocation(
        latitude: latitude,
        longitude: longitude,
      );
      if (result.insideGeofence) {
        return ServiceAreaResult.available;
      }
      return ServiceAreaResult.unavailable();
    } catch (_) {
      if (BookingGeoUtils.isInsideServiceArea(latitude, longitude)) {
        return ServiceAreaResult.available;
      }
      return ServiceAreaResult.unavailable();
    }
  }

  static Future<ServiceAreaResult> checkBookingPoints({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    final pickup = await checkCoordinates(
      latitude: pickupLat,
      longitude: pickupLng,
    );
    if (!pickup.isAvailable) return pickup;

    return checkCoordinates(
      latitude: dropoffLat,
      longitude: dropoffLng,
    );
  }

}
