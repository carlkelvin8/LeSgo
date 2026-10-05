import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/api_service.dart';
import '../../presentation/provider/main/riderside/rider_orders_provider.dart';
import 'directions_route_service.dart';

/// Shared rider navigation helpers — routes, polylines, external maps links.
class RiderRouteUtils {
  RiderRouteUtils._();

  static const double _routeDeviationMeters = 75;
  static const Duration _maxRouteAge = Duration(seconds: 45);
  static const int _coordPrecision = 4;

  static List<LatLng>? _cachedActivePoints;
  static String? _cachedRouteKey;
  static DateTime? _lastRouteFetchAt;

  static bool hasValidCoordinates(double lat, double lng) {
    return lat.abs() > 0.001 && lng.abs() > 0.001;
  }

  static bool isEnRouteToPickup(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'accepted':
      case 'driver_arrived_at_pickup':
      case 'ready_for_pickup':
      case 'searching_driver':
      case 'pending':
        return true;
      default:
        return false;
    }
  }

  static ({
    LatLng destination,
    String routeType,
    String navLabel,
  }) navigationTarget(RiderOrder order) {
    if (isEnRouteToPickup(order.status)) {
      return (
        destination: LatLng(order.pickupLat, order.pickupLng),
        routeType: 'to_pickup',
        navLabel: 'Pickup',
      );
    }
    return (
      destination: LatLng(order.dropoffLat, order.dropoffLng),
      routeType: 'to_dropoff',
      navLabel: 'Delivery Address',
    );
  }

  static ({
    LatLng destination,
    String navLabel,
  }) navigationTargetForStatus({
    required String? status,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) {
    if (isEnRouteToPickup(status)) {
      return (
        destination: LatLng(pickupLat, pickupLng),
        navLabel: 'Pickup',
      );
    }
    return (
      destination: LatLng(dropoffLat, dropoffLng),
      navLabel: 'Delivery Address',
    );
  }

  static RiderOrder? findOrder(RiderOrdersState state, int orderId) {
    if (state.activeOrder?.id == orderId) return state.activeOrder;
    for (final order in state.availableOrders) {
      if (order.id == orderId) return order;
    }
    return null;
  }

  static void clearRouteCache() {
    _cachedActivePoints = null;
    _cachedRouteKey = null;
    _lastRouteFetchAt = null;
  }

  static String routeKey(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) {
    return '${originLat.toStringAsFixed(_coordPrecision)},'
        '${originLng.toStringAsFixed(_coordPrecision)}->'
        '${destLat.toStringAsFixed(_coordPrecision)},'
        '${destLng.toStringAsFixed(_coordPrecision)}';
  }

  static String _destinationKey(double destLat, double destLng) {
    return '${destLat.toStringAsFixed(_coordPrecision)},'
        '${destLng.toStringAsFixed(_coordPrecision)}';
  }

  /// Skip redundant route API calls when rider is still on the cached path.
  static bool needsRouteRefresh({
    required double riderLat,
    required double riderLng,
    required double destLat,
    required double destLng,
    bool force = false,
  }) {
    if (force) return true;

    final destKey = _destinationKey(destLat, destLng);
    if (_cachedRouteKey != destKey) return true;
    if (_cachedActivePoints == null || _cachedActivePoints!.length < 2) {
      return true;
    }
    if (_lastRouteFetchAt == null) return true;
    if (DateTime.now().difference(_lastRouteFetchAt!) > _maxRouteAge) {
      return true;
    }

    var minDistance = double.infinity;
    for (final point in _cachedActivePoints!) {
      final distance = Geolocator.distanceBetween(
        riderLat,
        riderLng,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) minDistance = distance;
    }
    return minDistance > _routeDeviationMeters;
  }

  static void _rememberRoute(double destLat, double destLng, List<LatLng> points) {
    _cachedRouteKey = _destinationKey(destLat, destLng);
    _cachedActivePoints = List<LatLng>.from(points);
    _lastRouteFetchAt = DateTime.now();
  }

  static Map<String, dynamic> _unwrapRouteData(Map<String, dynamic> routeData) {
    if (routeData['data'] is Map) {
      return Map<String, dynamic>.from(routeData['data'] as Map);
    }
    return routeData;
  }

  static String? _extractEncodedPolyline(Map<String, dynamic> data) {
    for (final key in ['encoded_polyline', 'polyline']) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }

    final overview = data['overview_polyline'];
    if (overview is String && overview.isNotEmpty) return overview;
    if (overview is Map) {
      final points = overview['points'];
      if (points is String && points.isNotEmpty) return points;
    }
    return null;
  }

  static List<LatLng> parseRoutePoints(Map<String, dynamic>? routeData) {
    if (routeData == null) return const [];

    final data = _unwrapRouteData(routeData);

    final encoded = _extractEncodedPolyline(data);
    if (encoded != null) {
      final points = decodePolyline(encoded);
      if (points.length >= 2) return points;
    }

    final routes = data['routes'];
    if (routes is List && routes.isNotEmpty) {
      final points = parseGoogleDirectionsRoute(routes.first);
      if (points.length >= 2) return points;
    }

    final stepPoints = _parseStepsPolylines(data['legs'] ?? data['steps']);
    if (stepPoints.length >= 2) return stepPoints;

    final polyline = data['polyline'];
    if (polyline is List) {
      final points = <LatLng>[];
      for (final point in polyline) {
        if (point is! Map) continue;
        final lat = point['latitude'] ?? point['lat'];
        final lng = point['longitude'] ?? point['lng'];
        if (lat is num && lng is num) {
          points.add(LatLng(lat.toDouble(), lng.toDouble()));
        }
      }
      if (points.length >= 2) return points;
    }

    return const [];
  }

  static List<LatLng> parseGoogleDirectionsRoute(dynamic route) {
    if (route is! Map) return const [];
    final routeMap = Map<String, dynamic>.from(route);

    final stepPoints = _parseStepsPolylines(routeMap['legs']);
    if (stepPoints.length >= 2) return stepPoints;

    final overview = routeMap['overview_polyline'];
    if (overview is Map) {
      final encoded = overview['points']?.toString();
      if (encoded != null && encoded.isNotEmpty) {
        return decodePolyline(encoded);
      }
    }

    return const [];
  }

  static List<LatLng> _parseStepsPolylines(dynamic legsOrSteps) {
    final points = <LatLng>[];

    void addFromSteps(List steps) {
      for (final step in steps) {
        if (step is! Map) continue;
        final stepMap = Map<String, dynamic>.from(step);
        final polyline = stepMap['polyline'];
        if (polyline is Map) {
          final encoded = polyline['points']?.toString();
          if (encoded != null && encoded.isNotEmpty) {
            final decoded = decodePolyline(encoded);
            if (decoded.isNotEmpty) {
              if (points.isNotEmpty &&
                  points.last.latitude == decoded.first.latitude &&
                  points.last.longitude == decoded.first.longitude) {
                points.addAll(decoded.skip(1));
              } else {
                points.addAll(decoded);
              }
            }
          }
        }
      }
    }

    if (legsOrSteps is List) {
      for (final leg in legsOrSteps) {
        if (leg is Map && leg['steps'] is List) {
          addFromSteps(leg['steps'] as List);
        }
      }
      if (points.isEmpty && legsOrSteps.isNotEmpty && legsOrSteps.first is Map) {
        addFromSteps(legsOrSteps);
      }
    }

    return points;
  }

  static Future<List<LatLng>> fetchRoadRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    bool forceRefresh = false,
  }) async {
    try {
      final routeData = await ApiService.getRoute(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
        travelMode: RiderTravelMode.twoWheeler.apiValue,
      );
      final points = parseRoutePoints(routeData);
      if (points.length >= 2) {
        _rememberRoute(destLat, destLng, points);
        return points;
      }
    } catch (_) {}

    final directions = await DirectionsRouteService.fetchRoute(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      travelMode: RiderTravelMode.twoWheeler,
    );

    if (directions != null && directions.points.length >= 2) {
      _rememberRoute(destLat, destLng, directions.points);
      return directions.points;
    }

    return const [];
  }

  static Future<Set<Polyline>> buildNavigationPolylines({
    required RiderOrder order,
    required double riderLat,
    required double riderLng,
    bool forceRefresh = false,
  }) async {
    final target = navigationTarget(order);
    final origin = LatLng(riderLat, riderLng);

    if (!hasValidCoordinates(
      target.destination.latitude,
      target.destination.longitude,
    )) {
      return {};
    }

    if (!forceRefresh &&
        !needsRouteRefresh(
          riderLat: riderLat,
          riderLng: riderLng,
          destLat: target.destination.latitude,
          destLng: target.destination.longitude,
        )) {
      return _buildPolylinesFromCache(routeType: target.routeType);
    }

    final points = await fetchRoadRoute(
      originLat: origin.latitude,
      originLng: origin.longitude,
      destLat: target.destination.latitude,
      destLng: target.destination.longitude,
      forceRefresh: forceRefresh,
    );

    if (points.isEmpty) return {};

    return _assemblePolylines(
      order: order,
      routeType: target.routeType,
      mainPoints: points,
      pickupLat: order.pickupLat,
      pickupLng: order.pickupLng,
      dropoffLat: order.dropoffLat,
      dropoffLng: order.dropoffLng,
    );
  }

  static Future<Set<Polyline>> buildNavigationPolylinesForBooking({
    required String? status,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required double riderLat,
    required double riderLng,
    bool forceRefresh = false,
  }) async {
    final target = navigationTargetForStatus(
      status: status,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
    );
    final origin = LatLng(riderLat, riderLng);

    if (!hasValidCoordinates(
      target.destination.latitude,
      target.destination.longitude,
    )) {
      return {};
    }

    final routeType = isEnRouteToPickup(status) ? 'to_pickup' : 'to_dropoff';

    if (!forceRefresh &&
        !needsRouteRefresh(
          riderLat: riderLat,
          riderLng: riderLng,
          destLat: target.destination.latitude,
          destLng: target.destination.longitude,
        )) {
      return _buildPolylinesFromCache(routeType: routeType);
    }

    final points = await fetchRoadRoute(
      originLat: origin.latitude,
      originLng: origin.longitude,
      destLat: target.destination.latitude,
      destLng: target.destination.longitude,
      forceRefresh: forceRefresh,
    );

    if (points.isEmpty) return {};

    return _assemblePolylines(
      routeType: routeType,
      mainPoints: points,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
    );
  }

  static Future<Set<Polyline>> _assemblePolylines({
    RiderOrder? order,
    required String routeType,
    required List<LatLng> mainPoints,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    final polylines = <Polyline>{
      Polyline(
        polylineId: PolylineId('route_$routeType'),
        points: mainPoints,
        color: routeType == 'to_pickup' ? Colors.blue : Colors.orange,
        width: 5,
        geodesic: false,
        patterns: routeType == 'to_pickup'
            ? const []
            : [PatternItem.dash(10), PatternItem.gap(5)],
      ),
    };

    final showPickupToDropoff = routeType == 'to_dropoff' ||
        (order != null && isEnRouteToPickup(order.status));

    if (showPickupToDropoff &&
        hasValidCoordinates(pickupLat, pickupLng) &&
        hasValidCoordinates(dropoffLat, dropoffLng)) {
      final segmentPoints = await fetchRoadRoute(
        originLat: pickupLat,
        originLng: pickupLng,
        destLat: dropoffLat,
        destLng: dropoffLng,
        forceRefresh: false,
      );

      if (segmentPoints.length >= 2) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('pickup_to_dropoff'),
            points: segmentPoints,
            color: routeType == 'to_dropoff'
                ? Colors.grey
                : const Color(0xFF5F2D82).withValues(alpha: 0.45),
            width: routeType == 'to_dropoff' ? 2 : 3,
            geodesic: false,
            patterns: routeType == 'to_dropoff'
                ? [PatternItem.dot, PatternItem.gap(5)]
                : [PatternItem.dash(8), PatternItem.gap(8)],
          ),
        );
      }
    }

    return polylines;
  }

  static Set<Polyline> _buildPolylinesFromCache({required String routeType}) {
    if (_cachedActivePoints == null || _cachedActivePoints!.length < 2) {
      return {};
    }
    return {
      Polyline(
        polylineId: PolylineId('route_$routeType'),
        points: List<LatLng>.from(_cachedActivePoints!),
        color: routeType == 'to_pickup' ? Colors.blue : Colors.orange,
        width: 5,
        geodesic: false,
        patterns: routeType == 'to_pickup'
            ? const []
            : [PatternItem.dash(10), PatternItem.gap(5)],
      ),
    };
  }

  static String buildGoogleMapsNavigationUrl({
    required double destLat,
    required double destLng,
    double? originLat,
    double? originLng,
  }) {
    final destination = '$destLat,$destLng';
    if (originLat != null &&
        originLng != null &&
        hasValidCoordinates(originLat, originLng)) {
      return 'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destination&travelmode=driving';
    }
    return 'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving';
  }

  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    if (encoded.isEmpty) return points;

    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int byte;
      do {
        if (index >= encoded.length) break;
        byte = encoded.codeUnitAt(index++) - 63;
        result += (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final deltaLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;
      do {
        if (index >= encoded.length) break;
        byte = encoded.codeUnitAt(index++) - 63;
        result += (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final deltaLng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
