import '../../../core/utils/ph_address.dart';

class LocationAddress {
  final String? houseNumberStreet;
  final String? subdivisionBarangay;
  final String? cityProvince;
  final String? zipCode;
  final String? landmark;
  final bool isDefault;

  /// The detailed pieces (block, lot, street, subdivision, barangay, city,
  /// province, ZIP) when known, so the address can be re-edited exactly.
  final PhAddress? details;

  LocationAddress({
    this.houseNumberStreet,
    this.subdivisionBarangay,
    this.cityProvince,
    this.zipCode,
    this.landmark,
    this.isDefault = false,
    this.details,
  });

  /// Builds the address from detailed parts. The older single-line fields are
  /// filled too so everything that reads them keeps working.
  factory LocationAddress.fromPh(PhAddress p, {bool isDefault = false}) {
    String? n(String s) => s.trim().isEmpty ? null : s.trim();
    final brgy = p.barangay.trim().isEmpty
        ? null
        : PhAddress(barangay: p.barangay).line2;
    return LocationAddress(
      houseNumberStreet: n(p.line1),
      subdivisionBarangay: brgy,
      cityProvince: n(
        [
          p.city.trim(),
          p.province.trim(),
        ].where((e) => e.isNotEmpty).join(', '),
      ),
      zipCode: n(p.zip),
      landmark: n(p.landmark),
      isDefault: isDefault,
      details: p,
    );
  }

  /// The detailed pieces, rebuilt from the older single-line fields when this
  /// address was not created from details.
  PhAddress get asPh {
    final d = details;
    if (d != null) return d;
    final cityParts = (cityProvince ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    var barangay = (subdivisionBarangay ?? '').trim();
    barangay = barangay.replaceFirst(
      RegExp(r'^(barangay|brgy\.?)\s*', caseSensitive: false),
      '',
    );
    return PhAddress(
      street: (houseNumberStreet ?? '').trim(),
      barangay: barangay,
      city: cityParts.isNotEmpty ? cityParts.first : '',
      province: cityParts.length > 1 ? cityParts.sublist(1).join(', ') : '',
      zip: (zipCode ?? '').trim(),
      landmark: (landmark ?? '').trim().startsWith('Coordinates:')
          ? ''
          : (landmark ?? '').trim(),
    );
  }

  LocationAddress copyWith({
    String? houseNumberStreet,
    String? subdivisionBarangay,
    String? cityProvince,
    String? zipCode,
    String? landmark,
    bool? isDefault,
    PhAddress? details,
  }) {
    return LocationAddress(
      houseNumberStreet: houseNumberStreet ?? this.houseNumberStreet,
      subdivisionBarangay: subdivisionBarangay ?? this.subdivisionBarangay,
      cityProvince: cityProvince ?? this.cityProvince,
      zipCode: zipCode ?? this.zipCode,
      landmark: landmark ?? this.landmark,
      isDefault: isDefault ?? this.isDefault,
      details: details ?? this.details,
    );
  }

  /// Human-readable address. Used wherever an address is sent to the API or
  /// shown as text, so it must never fall back to "Instance of ...".
  @override
  String toString() {
    final parts = <String>[
      for (final p in [houseNumberStreet, subdivisionBarangay, cityProvince])
        if (p != null && p.trim().isNotEmpty) p.trim(),
    ];
    final text = parts.join(', ');
    final zip = zipCode?.trim() ?? '';
    // Append the ZIP once, only when it isn't already in the text.
    if (zip.isNotEmpty && text.isNotEmpty && !text.contains(zip)) {
      return '$text $zip';
    }
    return text;
  }
}
