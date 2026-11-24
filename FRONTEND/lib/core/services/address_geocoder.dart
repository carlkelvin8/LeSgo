import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../utils/ph_address.dart';

/// One place that turns a map pin into a detailed Philippine address.
///
/// It asks Google for every result near the pin (the first one is usually just
/// the city), merges them, and falls back to the device geocoder. Block and lot
/// are filled in when Google knows them; the customer completes the rest in
/// the address details form.
class AddressGeocoder {
  AddressGeocoder({
    Future<http.Response> Function(Uri uri)? get,
    Future<List<Placemark>> Function(double lat, double lng)? placemarks,
    bool? hasApiKey,

    /// When true, a failing device geocoder throws instead of returning null,
    /// for callers that show an error to the customer.
    this.strict = false,
  }) : _get = get ?? ((uri) => http.get(uri)),
       _placemarks = placemarks ?? placemarkFromCoordinates,
       _hasApiKey = hasApiKey;

  final Future<http.Response> Function(Uri uri) _get;
  final Future<List<Placemark>> Function(double lat, double lng) _placemarks;
  final bool? _hasApiKey;
  final bool strict;

  static final _cache = <String, PhAddress>{};

  static String _key(LatLng l) =>
      '${l.latitude.toStringAsFixed(5)},${l.longitude.toStringAsFixed(5)}';

  /// Returns null when nothing could be resolved at all.
  Future<PhAddress?> reverse(LatLng location) async {
    final cached = _cache[_key(location)];
    if (cached != null) return cached;

    PhAddress? best;
    if (_hasApiKey ?? ApiConstants.isGoogleMapsConfigured) {
      best = await _google(location);
    }
    if (best == null || best.isEmpty) {
      final device = await _device(location);
      if (device != null && !device.isEmpty) best = device;
    }
    if (best != null && !best.isEmpty) _cache[_key(location)] = best;
    return best;
  }

  Future<PhAddress?> _google(LatLng location) async {
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '${location.latitude},${location.longitude}',
        'language': 'en',
        'region': 'ph',
        'key': ApiConstants.googleMapsApiKey,
      });
      final response = await _get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body);
      if (data is! Map || data['status'] != 'OK') return null;
      final results = data['results'];
      if (results is! List || results.isEmpty) return null;
      return PhAddressParser.fromGoogleResults(results);
    } catch (_) {
      return null;
    }
  }

  Future<PhAddress?> _device(LatLng location) async {
    try {
      final marks = await _placemarks(
        location.latitude,
        location.longitude,
      ).timeout(const Duration(seconds: 10));
      if (marks.isEmpty) return null;

      String pick(String? Function(Placemark p) f) {
        for (final p in marks) {
          final v = f(p)?.trim();
          if (v != null && v.isNotEmpty) return v;
        }
        return '';
      }

      final city = pick((p) => p.locality ?? p.subAdministrativeArea);
      var street = pick((p) => p.thoroughfare ?? p.street);
      var block = '';
      var lot = '';
      if (street.isNotEmpty) {
        final f = PhAddressParser.extractBlockLot(street);
        block = f.block;
        lot = f.lot;
        street = f.rest;
      }
      var barangay = pick((p) => p.subLocality);
      if (barangay == city) barangay = '';
      return PhAddress(
        block: block,
        lot: lot,
        houseNumber: pick((p) => p.subThoroughfare),
        street: street,
        barangay: barangay,
        city: city,
        province: pick((p) => p.administrativeArea),
        zip: pick((p) => p.postalCode),
      );
    } catch (_) {
      if (strict) rethrow;
      return null;
    }
  }
}
