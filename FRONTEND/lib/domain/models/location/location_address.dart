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
}
