class MerchantRegistrationInfo {
  final String restaurantName;
  final String ownerFirstName;
  final String ownerLastName;
  final String email;
  final String contactNumber;
  final String address;
  final String zipCode;

  const MerchantRegistrationInfo({
    required this.restaurantName,
    required this.ownerFirstName,
    required this.ownerLastName,
    required this.email,
    required this.contactNumber,
    required this.address,
    required this.zipCode,
  });

  bool get isValid =>
      restaurantName.isNotEmpty &&
      ownerFirstName.isNotEmpty &&
      ownerLastName.isNotEmpty &&
      email.isNotEmpty &&
      contactNumber.isNotEmpty &&
      address.isNotEmpty &&
      zipCode.isNotEmpty;

  MerchantRegistrationInfo copyWith({
    String? restaurantName,
    String? ownerFirstName,
    String? ownerLastName,
    String? email,
    String? contactNumber,
    String? address,
    String? zipCode,
  }) {
    return MerchantRegistrationInfo(
      restaurantName: restaurantName ?? this.restaurantName,
      ownerFirstName: ownerFirstName ?? this.ownerFirstName,
      ownerLastName: ownerLastName ?? this.ownerLastName,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      zipCode: zipCode ?? this.zipCode,
    );
  }

  factory MerchantRegistrationInfo.empty() {
    return const MerchantRegistrationInfo(
      restaurantName: '',
      ownerFirstName: '',
      ownerLastName: '',
      email: '',
      contactNumber: '',
      address: '',
      zipCode: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurantName': restaurantName,
      'ownerFirstName': ownerFirstName,
      'ownerLastName': ownerLastName,
      'email': email,
      'contactNumber': contactNumber,
      'address': address,
      'zipCode': zipCode,
    };
  }

  factory MerchantRegistrationInfo.fromJson(Map<String, dynamic> json) {
    return MerchantRegistrationInfo(
      restaurantName: json['restaurantName'] ?? '',
      ownerFirstName: json['ownerFirstName'] ?? '',
      ownerLastName: json['ownerLastName'] ?? '',
      email: json['email'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      address: json['address'] ?? '',
      zipCode: json['zipCode'] ?? '',
    );
  }

  @override
  String toString() {
    return 'MerchantRegistrationInfo(restaurantName: $restaurantName, ownerFirstName: $ownerFirstName, ownerLastName: $ownerLastName, email: $email, contactNumber: $contactNumber, address: $address, zipCode: $zipCode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MerchantRegistrationInfo &&
        other.restaurantName == restaurantName &&
        other.ownerFirstName == ownerFirstName &&
        other.ownerLastName == ownerLastName &&
        other.email == email &&
        other.contactNumber == contactNumber &&
        other.address == address &&
        other.zipCode == zipCode;
  }

  @override
  int get hashCode {
    return restaurantName.hashCode ^
        ownerFirstName.hashCode ^
        ownerLastName.hashCode ^
        email.hashCode ^
        contactNumber.hashCode ^
        address.hashCode ^
        zipCode.hashCode;
  }
}
