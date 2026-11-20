class LocationAddress {
  final String? houseNumberStreet;
  final String? subdivisionBarangay;
  final String? cityProvince;
  final String? zipCode;
  final String? landmark;
  final bool isDefault;

  LocationAddress({
    this.houseNumberStreet,
    this.subdivisionBarangay,
    this.cityProvince,
    this.zipCode,
    this.landmark,
    this.isDefault = false,
  });

  LocationAddress copyWith({
    String? houseNumberStreet,
    String? subdivisionBarangay,
    String? cityProvince,
    String? zipCode,
    String? landmark,
    bool? isDefault,
  }) {
    return LocationAddress(
      houseNumberStreet: houseNumberStreet ?? this.houseNumberStreet,
      subdivisionBarangay: subdivisionBarangay ?? this.subdivisionBarangay,
      cityProvince: cityProvince ?? this.cityProvince,
      zipCode: zipCode ?? this.zipCode,
      landmark: landmark ?? this.landmark,
      isDefault: isDefault ?? this.isDefault,
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
    return parts.join(', ');
  }
}
