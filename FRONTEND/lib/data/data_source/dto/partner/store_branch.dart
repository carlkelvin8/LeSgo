import '../../../../core/utils/booking_geo_utils.dart';

/// A store branch the customer can order from. Each branch is its own
/// pickup point, so it decides the delivery distance and fee.
class StoreBranch {
  final int id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final bool isPrimary;
  final bool isOpen;

  const StoreBranch({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.isPrimary = false,
    this.isOpen = true,
  });

  bool get hasLocation => BookingGeoUtils.hasValidCoords(latitude, longitude);

  /// Straight-line distance from this branch to a point, in meters.
  int? distanceTo(double lat, double lng) {
    if (!hasLocation) return null;
    return BookingGeoUtils.distanceMeters(
      lat1: latitude!,
      lng1: longitude!,
      lat2: lat,
      lng2: lng,
    );
  }

  static double? _toDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  static bool _toBool(dynamic v, {required bool fallback}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return fallback;
  }

  factory StoreBranch.fromJson(Map<String, dynamic> json) {
    final address = [
      json['address_line1'],
      json['address_line2'],
      json['city'],
      json['region'],
    ]
        .where((p) => p != null && p.toString().trim().isNotEmpty)
        .join(', ');
    return StoreBranch(
      id: int.parse(json['id'].toString()),
      name: (json['name'] ?? 'Branch').toString(),
      address: address,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      isPrimary: _toBool(json['is_primary'], fallback: false),
      isOpen: _toBool(json['is_open'], fallback: true),
    );
  }

  /// Open branches with a map pin, nearest to [lat],[lng] first.
  static List<StoreBranch> orderableNearest(
    List<StoreBranch> branches,
    double lat,
    double lng,
  ) {
    final usable = branches.where((b) => b.isOpen && b.hasLocation).toList();
    usable.sort((a, b) => a.distanceTo(lat, lng)!.compareTo(b.distanceTo(lat, lng)!));
    return usable;
  }
}
