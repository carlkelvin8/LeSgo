import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

/// Fetches road-following routes via the backend Google Directions proxy.
class DirectionsRouteService {
  DirectionsRouteService._();

  static Future<({
    List<LatLng> points,
    String? distanceText,
    String? durationText,
    int? distanceMeters,
    int? durationSeconds,
  })?> fetchRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    if (!ApiConstants.isGoogleMapsConfigured) return null;

    final origin = '$originLat,$originLng';
    final destination = '$destLat,$destLng';
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/v1/google-places/directions'
      '?origin=$origin&destination=$destination',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final encoded = route['overview_polyline']?['points']?.toString();
      if (encoded == null || encoded.isEmpty) return null;

      final points = decodePolyline(encoded);
      if (points.isEmpty) return null;

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
      );
    } catch (_) {
      return null;
    }
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
