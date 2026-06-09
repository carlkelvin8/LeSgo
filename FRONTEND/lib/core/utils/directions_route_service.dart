import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/api_constants.dart';
import '../di/injection.dart';
import '../network/dio_client.dart';

/// Fetches road-following routes via the backend Google Directions proxy.
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
  }) async {
    if (!ApiConstants.isGoogleMapsConfigured) {
      return (
        points: <LatLng>[],
        distanceText: null,
        durationText: null,
        distanceMeters: null,
        durationSeconds: null,
        error: 'Maps not configured',
      );
    }

    try {
      final dio = getIt<DioClient>().dio;
      final response = await dio.get<Map<String, dynamic>>(
        '/v1/google-places/directions',
        queryParameters: {
          'origin': '$originLat,$originLng',
          'destination': '$destLat,$destLng',
        },
      );

      final data = _unwrapPayload(response.data);
      final status = data['status']?.toString() ?? '';

      if (status != 'OK') {
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

      final route = routes.first as Map<String, dynamic>;
      final encoded = route['overview_polyline']?['points']?.toString();
      if (encoded == null || encoded.isEmpty) {
        return (
          points: <LatLng>[],
          distanceText: null,
          durationText: null,
          distanceMeters: null,
          durationSeconds: null,
          error: 'Invalid route data',
        );
      }

      final points = decodePolyline(encoded);
      if (points.isEmpty) {
        return (
          points: <LatLng>[],
          distanceText: null,
          durationText: null,
          distanceMeters: null,
          durationSeconds: null,
          error: 'Empty route',
        );
      }

      String? distanceText;
      String? durationText;
      int? distanceMeters;
      int? durationSeconds;

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

  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    if (encoded.isEmpty) return points;

    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int b;
      do {
        if (index >= encoded.length) break;
        b = encoded.codeUnitAt(index++) - 63;
        result += (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        if (index >= encoded.length) break;
        b = encoded.codeUnitAt(index++) - 63;
        result += (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
