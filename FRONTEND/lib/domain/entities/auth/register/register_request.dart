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
  final String idType;
  final String idNumber;
  final String validIdFrontPath;
  final String validIdBackPath;
  final String phoneNumber;
  final String phoneVerificationToken;
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
    this.idType = '',
    this.idNumber = '',
    this.validIdFrontPath = '',
    this.validIdBackPath = '',
    this.phoneNumber = '',
    this.phoneVerificationToken = '',
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
    String? idType,
    String? idNumber,
    String? validIdFrontPath,
    String? validIdBackPath,
    String? phoneNumber,
    String? phoneVerificationToken,
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
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      validIdFrontPath: validIdFrontPath ?? this.validIdFrontPath,
      validIdBackPath: validIdBackPath ?? this.validIdBackPath,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneVerificationToken:
          phoneVerificationToken ??
          (phoneNumber != null && phoneNumber != this.phoneNumber
              ? ''
              : this.phoneVerificationToken),
      address: address ?? this.address,
    );
  }

  bool get hasIdentityVerification =>
      selfiePath.trim().isNotEmpty &&
      idType.trim().isNotEmpty &&
      idNumber.trim().isNotEmpty &&
      validIdFrontPath.trim().isNotEmpty &&
      validIdBackPath.trim().isNotEmpty;
}
