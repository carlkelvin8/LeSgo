class LoginRequest {
  final String email;
  final String password;
  final String? twoFactorCode;

  LoginRequest({
    required this.email,
    required this.password,
    this.twoFactorCode,
  });
}
