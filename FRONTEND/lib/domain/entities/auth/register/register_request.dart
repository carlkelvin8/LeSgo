import 'address_request.dart';

class RegisterRequest {
  final String firstName;
  final String lastName;
  final String birthday;
  final String email;
  final String password;
  final String confirmPassword;
  final String referralCode;
  final bool termsAccepted;
  final String selfiePath;
  final String phoneNumber;
  final Address? address;

  RegisterRequest({
    this.firstName = '',
    this.lastName = '',
    this.birthday = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.referralCode = '',
    this.termsAccepted = false,
    this.selfiePath = '',
    this.phoneNumber = '',
    this.address,
  });

  RegisterRequest copyWith({
    String? firstName,
    String? lastName,
    String? birthday,
    String? email,
    String? password,
    String? confirmPassword,
    String? referralCode,
    bool? termsAccepted,
    String? selfiePath,
    String? phoneNumber,
    Address? address,
  }) {
    return RegisterRequest(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthday: birthday ?? this.birthday,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      referralCode: referralCode ?? this.referralCode,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      selfiePath: selfiePath ?? this.selfiePath,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
    );
  }
}
