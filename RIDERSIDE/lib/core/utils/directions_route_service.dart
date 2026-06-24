import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../di/injection.dart';
import '../network/dio_client.dart';

/// Road-following routes via backend Google Directions proxy.
class DirectionsRouteService {
  DirectionsRouteService._();

  static Future<({
    List<LatLng> points,
    String? distanceText,
    String? durationText,
    int? distanceMeters,
    int? durationSeconds,
    String? error,
  })?> fetchRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    RiderTravelMode travelMode = RiderTravelMode.twoWheeler,
  }) async {
    try {
      final dio = getIt<DioClient>().dio;
      final response = await dio.get<Map<String, dynamic>>(
        '/v1/google-places/directions',
        queryParameters: {
          'origin': '$originLat,$originLng',
          'destination': '$destLat,$destLng',
          'mode': travelMode.apiValue,
        },
      );

      final data = _unwrapPayload(response.data);
      final status = data['status']?.toString() ?? '';

      if (status != 'OK') {
        if (travelMode != RiderTravelMode.driving) {
          return fetchRoute(
            originLat: originLat,
            originLng: originLng,
            destLat: destLat,
            destLng: destLng,
            travelMode: RiderTravelMode.driving,
          );
        }
        return (
          points: <LatLng>[],
          distanceText: null,
          durationText: null,
          distanceMeters: null,
          durationSeconds: null,
          error: status.isEmpty ? 'Route unavailable' : status,
        );
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        return (
          points: <LatLng>[],
          distanceText: null,
          durationText: null,
          distanceMeters: null,
          durationSeconds: null,
          error: 'No route found',
        );
      }

      final route = routes.first;
      final points = _parseGoogleDirectionsRoute(route);
      if (points.isEmpty) {
        return (
          points: <LatLng>[],
          distanceText: null,
          durationText: null,
          distanceMeters: null,
          durationSeconds: null,
          error: 'Invalid route data',
        );
      }

      String? distanceText;
      String? durationText;
      int? distanceMeters;
      int? durationSeconds;

      if (route is Map) {
        final legs = route['legs'] as List?;
        if (legs != null && legs.isNotEmpty) {
          final leg = legs.first as Map<String, dynamic>;
          final distance = leg['distance'] as Map<String, dynamic>?;
          final duration = leg['duration'] as Map<String, dynamic>?;
          distanceText = distance?['text']?.toString();
          durationText = duration?['text']?.toString();
          distanceMeters = (distance?['value'] as num?)?.toInt();
          durationSeconds = (duration?['value'] as num?)?.toInt();
        }
      }

      return (
        points: points,
        distanceText: distanceText,
        durationText: durationText,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        error: null,
      );
    } on DioException catch (e) {
      debugPrint('DirectionsRouteService error: ${e.message}');
      return (
        points: <LatLng>[],
        distanceText: null,
        durationText: null,
        distanceMeters: null,
        durationSeconds: null,
        error: 'Could not load route. Check your connection.',
      );
    } catch (e) {
      debugPrint('DirectionsRouteService error: $e');
      return (
        points: <LatLng>[],
        distanceText: null,
        durationText: null,
        distanceMeters: null,
        durationSeconds: null,
        error: 'Could not load route.',
      );
    }
  }

  static Map<String, dynamic> _unwrapPayload(Map<String, dynamic>? raw) {
    if (raw == null) return {};
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return raw;
  }

  static List<LatLng> _parseGoogleDirectionsRoute(dynamic route) {
    if (route is! Map) return const [];
    final routeMap = Map<String, dynamic>.from(route);

    final stepPoints = _parseStepsPolylines(routeMap['legs']);
    if (stepPoints.length >= 2) return stepPoints;

    final overview = routeMap['overview_polyline'];
    if (overview is Map) {
      final encoded = overview['points']?.toString();
      if (encoded != null && encoded.isNotEmpty) {
        return _decodePolyline(encoded);
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
            final decoded = _decodePolyline(encoded);
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

  static List<LatLng> _decodePolyline(String encoded) {
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

enum RiderTravelMode {
  twoWheeler('two_wheeler'),
  driving('driving');

  const RiderTravelMode(this.apiValue);
  final String apiValue;
}
