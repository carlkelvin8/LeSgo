class RiderRegistrationInfo {
  final String firstName;
  final String lastName;
  final String birthday;
  final String email;

  const RiderRegistrationInfo({
    required this.firstName,
    required this.lastName,
    required this.birthday,
    required this.email,
  });

  RiderRegistrationInfo copyWith({
    String? firstName,
    String? lastName,
    String? birthday,
    String? email,
  }) {
    return RiderRegistrationInfo(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthday: birthday ?? this.birthday,
      email: email ?? this.email,
    );
  }

  bool get isValid {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        birthday.isNotEmpty &&
        email.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'birthday': birthday,
      'email': email,
    };
  }

  factory RiderRegistrationInfo.fromJson(Map<String, dynamic> json) {
    return RiderRegistrationInfo(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      birthday: json['birthday'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  factory RiderRegistrationInfo.empty() {
    return const RiderRegistrationInfo(
      firstName: '',
      lastName: '',
      birthday: '',
      email: '',
    );
  }
}
