/// A merchant branch (pickup point). Each store has at least one, and
/// exactly one is primary.
class PartnerBranch {
  final int id;
  final String name;
  final String? phoneNumber;
  final String addressLine1;
  final String? addressLine2;
  final String? city;
  final String? region;
  final double? latitude;
  final double? longitude;
  final bool isPrimary;
  final bool isOpen;

  const PartnerBranch({
    required this.id,
    required this.name,
    this.phoneNumber,
    required this.addressLine1,
    this.addressLine2,
    this.city,
    this.region,
    this.latitude,
    this.longitude,
    this.isPrimary = false,
    this.isOpen = true,
  });

  String get fullAddress => [addressLine1, addressLine2, city, region]
      .where((part) => part != null && part.trim().isNotEmpty)
      .join(', ');

  bool get hasLocation => latitude != null && longitude != null;

  static double? _toDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  static bool _toBool(dynamic v, {required bool fallback}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return fallback;
  }

  factory PartnerBranch.fromJson(Map<String, dynamic> json) => PartnerBranch(
        id: int.parse(json['id'].toString()),
        name: (json['name'] ?? '').toString(),
        phoneNumber: json['phone_number']?.toString(),
        addressLine1: (json['address_line1'] ?? '').toString(),
        addressLine2: json['address_line2']?.toString(),
        city: json['city']?.toString(),
        region: json['region']?.toString(),
        latitude: _toDouble(json['latitude']),
        longitude: _toDouble(json['longitude']),
        isPrimary: _toBool(json['is_primary'], fallback: false),
        isOpen: _toBool(json['is_open'], fallback: true),
      );
}

/// Branch snapshot stored on an order under `meta.branch`.
class OrderBranchInfo {
  final int? id;
  final String name;
  final String? address;
  final String? phoneNumber;

  const OrderBranchInfo({
    this.id,
    required this.name,
    this.address,
    this.phoneNumber,
  });

  static OrderBranchInfo? fromMeta(dynamic meta) {
    if (meta is! Map) return null;
    final branch = meta['branch'];
    if (branch is! Map) return null;
    final name = branch['name']?.toString().trim() ?? '';
    if (name.isEmpty) return null;
    return OrderBranchInfo(
      id: int.tryParse(branch['id']?.toString() ?? ''),
      name: name,
      address: branch['address']?.toString(),
      phoneNumber: branch['phone_number']?.toString(),
    );
  }
}
