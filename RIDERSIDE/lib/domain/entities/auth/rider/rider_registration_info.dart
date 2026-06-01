class RiderRegistrationInfo {
  final String firstName;
  final String lastName;
  final String birthday;
  final String email;
  final String password;
  final String confirmPassword;
  final String licenseNumber;
  final String? licenseExpiryDate;

  const RiderRegistrationInfo({
    required this.firstName,
    required this.lastName,
    required this.birthday,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.licenseNumber,
    this.licenseExpiryDate,
  });

  RiderRegistrationInfo copyWith({
    String? firstName,
    String? lastName,
    String? birthday,
    String? email,
    String? password,
    String? confirmPassword,
    String? licenseNumber,
    String? licenseExpiryDate,
  }) {
    return RiderRegistrationInfo(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthday: birthday ?? this.birthday,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
    );
  }

  bool get isValid {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        birthday.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        password == confirmPassword &&
        licenseNumber.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'birthday': birthday,
      'email': email,
      'licenseNumber': licenseNumber,
      if (licenseExpiryDate != null) 'licenseExpiryDate': licenseExpiryDate,
    };
  }

  factory RiderRegistrationInfo.fromJson(Map<String, dynamic> json) {
    return RiderRegistrationInfo(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      birthday: json['birthday'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: '',
      confirmPassword: '',
      licenseNumber: json['licenseNumber'] as String? ?? '',
      licenseExpiryDate: json['licenseExpiryDate'] as String?,
    );
  }

  factory RiderRegistrationInfo.empty() {
    return const RiderRegistrationInfo(
      firstName: '',
      lastName: '',
      birthday: '',
      email: '',
      password: '',
      confirmPassword: '',
      licenseNumber: '',
    );
  }
}
