import '../../data/data_source/dto/order/order_dto.dart';
import 'media_url_utils.dart';

class DriverInfo {
  final String name;
  final String? phone;
  final String? vehicleNumber;
  final String? vehicleType;
  final String? photoUrl;
  final double? rating;

  const DriverInfo({
    required this.name,
    this.phone,
    this.vehicleNumber,
    this.vehicleType,
    this.photoUrl,
    this.rating,
  });

  static DriverInfo? fromOrder(OrderDto order) {
    final profile = order.driverProfile;
    if (profile == null && order.driverId == null) return null;
    return fromDriverProfile(
      profile,
      fallbackDriverId: order.driverId,
      vehicleType: order.vehicleType,
    );
  }

  static DriverInfo? fromDriverProfile(
    DriverProfileDto? profile, {
    int? fallbackDriverId,
    String? vehicleType,
  }) {
    if (profile == null) {
      if (fallbackDriverId == null) return null;
      return DriverInfo(name: 'Driver #$fallbackDriverId');
    }

    final user = profile.user;
    final name = user?.name.trim();
    final resolvedName = (name != null && name.isNotEmpty)
        ? name
        : 'Driver #${profile.id}';

    return DriverInfo(
      name: resolvedName,
      phone: user?.phoneNumber,
      vehicleNumber: _firstNonEmpty([
        profile.plateNumber,
        profile.vehiclePlate,
      ]),
      vehicleType: vehicleType,
      photoUrl: _resolvePhotoUrl(user?.profilePhotoUrl, user?.profilePicture),
      rating: profile.rating,
    );
  }

  static DriverInfo? fromDriverProfileMap(Map<String, dynamic>? profile) {
    if (profile == null) return null;

    final userRaw = profile['user'];
    final user = userRaw is Map
        ? Map<String, dynamic>.from(userRaw)
        : null;

    final name = user?['name']?.toString().trim();
    final profileId = profile['id'];
    final resolvedName = (name != null && name.isNotEmpty)
        ? name
        : 'Driver #${profileId ?? ''}';

    return DriverInfo(
      name: resolvedName,
      phone: user?['phone_number']?.toString(),
      vehicleNumber: _firstNonEmpty([
        profile['plate_number']?.toString(),
        profile['vehicle_plate']?.toString(),
        profile['vehicle_number']?.toString(),
      ]),
      vehicleType: profile['vehicle_type']?.toString(),
      photoUrl: _resolvePhotoUrl(
        user?['profile_photo_url']?.toString(),
        user?['profile_picture']?.toString(),
        user?['avatar']?.toString(),
      ),
      rating: _parseRating(profile['rating']),
    );
  }

  static String? _resolvePhotoUrl(String? primary, String? secondary, [String? tertiary]) {
    for (final candidate in [primary, secondary, tertiary]) {
      final resolved = MediaUrlUtils.resolve(candidate);
      if (resolved != null && resolved.isNotEmpty) {
        return resolved;
      }
    }
    return null;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  static double? _parseRating(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
