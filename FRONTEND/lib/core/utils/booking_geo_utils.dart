import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Shared geo helpers — Cagayan de Oro (CDO) defaults and distance math.
class BookingGeoUtils {
  BookingGeoUtils._();

  /// Cagayan de Oro city center (Divisoria area).
  static const double defaultLat = 8.4542;
  static const double defaultLng = 124.6319;

  static LatLng get defaultLatLng => const LatLng(defaultLat, defaultLng);

  static CameraPosition get defaultCamera => const CameraPosition(
        target: LatLng(defaultLat, defaultLng),
        zoom: 14,
      );

  /// Service coverage radius from CDO center (km) — used when geofence API unavailable.
  static const double serviceRadiusKm = 40;

  static bool hasValidCoords(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat.abs() < 0.0001 && lng.abs() < 0.0001) return false;
    return lat.abs() <= 90 && lng.abs() <= 180;
  }

  static LatLng resolveCoords({
    double? lat,
    double? lng,
    LatLng? fallback,
  }) {
    if (hasValidCoords(lat, lng)) {
      return LatLng(lat!, lng!);
    }
    return fallback ?? defaultLatLng;
  }

  /// Haversine distance in meters between two WGS84 points.
  static int distanceMeters({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadiusM = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final meters = earthRadiusM * c;
    return meters.isFinite && meters > 0 ? meters.round() : 500;
  }

  static bool isInsideServiceArea(double lat, double lng) {
    return distanceKm(
          lat1: defaultLat,
          lng1: defaultLng,
          lat2: lat,
          lng2: lng,
        ) <=
        serviceRadiusKm;
  }

  static double distanceKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    return distanceMeters(
          lat1: lat1,
          lng1: lng1,
          lat2: lat2,
          lng2: lng2,
        ) /
        1000.0;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
