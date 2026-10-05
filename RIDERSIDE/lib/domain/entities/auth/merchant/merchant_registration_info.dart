class MerchantRegistrationInfo {
  final String restaurantName;
  final String ownerFirstName;
  final String ownerLastName;
  final String email;
  final String contactNumber;
  final String address;
  final String zipCode;
  final double? latitude;
  final double? longitude;
  final String password;
  final String confirmPassword;

  const MerchantRegistrationInfo({
    required this.restaurantName,
    required this.ownerFirstName,
    required this.ownerLastName,
    required this.email,
    required this.contactNumber,
    required this.address,
    required this.zipCode,
    this.latitude,
    this.longitude,
    required this.password,
    required this.confirmPassword,
  });

  bool get hasPinLocation => latitude != null && longitude != null;

  bool get isValid =>
      restaurantName.isNotEmpty &&
      ownerFirstName.isNotEmpty &&
      ownerLastName.isNotEmpty &&
      email.isNotEmpty &&
      contactNumber.isNotEmpty &&
      address.isNotEmpty &&
      zipCode.isNotEmpty &&
      hasPinLocation &&
      password.isNotEmpty &&
      confirmPassword.isNotEmpty &&
      password == confirmPassword;

  MerchantRegistrationInfo copyWith({
    String? restaurantName,
    String? ownerFirstName,
    String? ownerLastName,
    String? email,
    String? contactNumber,
    String? address,
    String? zipCode,
    double? latitude,
    double? longitude,
    String? password,
    String? confirmPassword,
  }) {
    return MerchantRegistrationInfo(
      restaurantName: restaurantName ?? this.restaurantName,
      ownerFirstName: ownerFirstName ?? this.ownerFirstName,
      ownerLastName: ownerLastName ?? this.ownerLastName,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      zipCode: zipCode ?? this.zipCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
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
      password: '',
      confirmPassword: '',
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
      'password': password,
      'password_confirmation': confirmPassword,
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
      password: json['password'] ?? '',
      confirmPassword: json['password_confirmation'] ?? '',
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
        other.zipCode == zipCode &&
        other.password == password &&
        other.confirmPassword == confirmPassword;
  }

  @override
  int get hashCode {
    return restaurantName.hashCode ^
        ownerFirstName.hashCode ^
        ownerLastName.hashCode ^
        email.hashCode ^
        contactNumber.hashCode ^
        address.hashCode ^
        zipCode.hashCode ^
        password.hashCode ^
        confirmPassword.hashCode;
  }
}
