import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/api_service.dart';
import '../../domain/models/rider_order.dart';
import '../../presentation/provider/main/riderside/rider_orders_provider.dart';

/// Shared rider navigation helpers — routes, polylines, external maps links.
class RiderRouteUtils {
  RiderRouteUtils._();

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

  static List<LatLng> parseRoutePoints(Map<String, dynamic>? routeData) {
    if (routeData == null) return const [];

    final data = routeData['data'] is Map
        ? Map<String, dynamic>.from(routeData['data'] as Map)
        : routeData;

    final encoded = data['encoded_polyline'] ?? data['overview_polyline'];
    if (encoded is String && encoded.isNotEmpty) {
      return decodePolyline(encoded);
    }

    final polyline = data['polyline'];
    if (polyline is String && polyline.isNotEmpty) {
      return decodePolyline(polyline);
    }
    if (polyline is List) {
      final points = <LatLng>[];
      for (final point in polyline) {
        if (point is! Map) continue;
        final lat = point['lat'];
        final lng = point['lng'];
        if (lat is num && lng is num) {
          points.add(LatLng(lat.toDouble(), lng.toDouble()));
        }
      }
      return points;
    }

    return const [];
  }

  static Future<Set<Polyline>> buildNavigationPolylines({
    required RiderOrder order,
    required double riderLat,
    required double riderLng,
  }) async {
    final target = navigationTarget(order);
    final origin = LatLng(riderLat, riderLng);

    if (!hasValidCoordinates(
          target.destination.latitude,
          target.destination.longitude,
        )) {
      return {};
    }

    var points = <LatLng>[];
    try {
      final routeData = await ApiService.getRoute(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destLat: target.destination.latitude,
        destLng: target.destination.longitude,
      );
      points = parseRoutePoints(routeData);
    } catch (_) {}

    if (points.isEmpty) {
      points = [origin, target.destination];
    }

    final polylines = <Polyline>{
      Polyline(
        polylineId: PolylineId('route_${target.routeType}'),
        points: points,
        color: target.routeType == 'to_pickup' ? Colors.blue : Colors.orange,
        width: 5,
        patterns: target.routeType == 'to_pickup'
            ? const []
            : [PatternItem.dash(10), PatternItem.gap(5)],
      ),
    };

    if (target.routeType == 'to_dropoff' &&
        hasValidCoordinates(order.pickupLat, order.pickupLng)) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('pickup_to_dropoff'),
          points: [
            LatLng(order.pickupLat, order.pickupLng),
            target.destination,
          ],
          color: Colors.grey,
          width: 2,
          patterns: [PatternItem.dot, PatternItem.gap(5)],
        ),
      );
    }

    return polylines;
  }

  static Future<Set<Polyline>> buildNavigationPolylinesForBooking({
    required String? status,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required double riderLat,
    required double riderLng,
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

    var points = <LatLng>[];
    try {
      final routeData = await ApiService.getRoute(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destLat: target.destination.latitude,
        destLng: target.destination.longitude,
      );
      points = parseRoutePoints(routeData);
    } catch (_) {}

    if (points.isEmpty) {
      points = [origin, target.destination];
    }

    final routeType =
        isEnRouteToPickup(status) ? 'to_pickup' : 'to_dropoff';

    final polylines = <Polyline>{
      Polyline(
        polylineId: PolylineId('route_$routeType'),
        points: points,
        color: routeType == 'to_pickup' ? Colors.blue : Colors.orange,
        width: 5,
      ),
    };

    if (hasValidCoordinates(pickupLat, pickupLng) &&
        hasValidCoordinates(dropoffLat, dropoffLng)) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('pickup_to_dropoff'),
          points: [
            LatLng(pickupLat, pickupLng),
            LatLng(dropoffLat, dropoffLng),
          ],
          color: const Color(0xFF5F2D82).withValues(alpha: 0.45),
          width: 3,
          patterns: [PatternItem.dash(8), PatternItem.gap(8)],
        ),
      );
    }

    return polylines;
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
