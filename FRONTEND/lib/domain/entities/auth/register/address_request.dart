class Address {
  final String houseNumber;
  final String streetName;
  final String subdivision;
  final String barangay;
  final String city;
  final String municipality;
  final String province;
  final String zipCode;
  final String landmark;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  Address({
    this.houseNumber = '',
    this.streetName = '',
    this.subdivision = '',
    this.barangay = '',
    this.city = '',
    this.municipality = '',
    this.province = '',
    this.zipCode = '',
    this.landmark = '',
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  Address copyWith({
    String? houseNumber,
    String? streetName,
    String? subdivision,
    String? barangay,
    String? city,
    String? municipality,
    String? province,
    String? zipCode,
    String? landmark,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) {
    return Address(
      houseNumber: houseNumber ?? this.houseNumber,
      streetName: streetName ?? this.streetName,
      subdivision: subdivision ?? this.subdivision,
      barangay: barangay ?? this.barangay,
      city: city ?? this.city,
      municipality: municipality ?? this.municipality,
      province: province ?? this.province,
      zipCode: zipCode ?? this.zipCode,
      landmark: landmark ?? this.landmark,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  String get fullAddress {
    final parts = [
      if (houseNumber.isNotEmpty) houseNumber,
      if (streetName.isNotEmpty) streetName,
      if (subdivision.isNotEmpty) subdivision,
      if (barangay.isNotEmpty) barangay,
      if (city.isNotEmpty) city,
      if (province.isNotEmpty) province,
      if (zipCode.isNotEmpty) zipCode,
    ];
    return parts.join(', ');
  }

  /// Secondary delivery details use the existing saved-address API field.
  String get deliveryDetails => [
    subdivision.trim(),
    barangay.trim(),
    if (landmark.trim().isNotEmpty) 'Landmark: ${landmark.trim()}',
  ].where((part) => part.isNotEmpty).join(', ');

  bool get isComplete {
    // Allow empty zipCode if we have coordinates (GPS-based address)
    // zipCode is optional for locations selected via map
    return (houseNumber.isNotEmpty || streetName.isNotEmpty) &&
        barangay.isNotEmpty &&
        city.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'houseNumber': houseNumber,
      'streetName': streetName,
      'subdivision': subdivision,
      'barangay': barangay,
      'city': city,
      'municipality': municipality,
      'province': province,
      'zipCode': zipCode,
      'landmark': landmark,
      'isDefault': isDefault,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      houseNumber: json['houseNumber'] ?? '',
      streetName: json['streetName'] ?? '',
      subdivision: json['subdivision'] ?? '',
      barangay: json['barangay'] ?? '',
      city: json['city'] ?? '',
      municipality: json['municipality'] ?? '',
      province: json['province'] ?? '',
      zipCode: json['zipCode'] ?? '',
      landmark: json['landmark'] ?? '',
      isDefault: json['isDefault'] ?? false,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }
}
