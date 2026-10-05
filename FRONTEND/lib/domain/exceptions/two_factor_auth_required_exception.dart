class TwoFactorAuthRequiredException implements Exception {
  final String message;

  const TwoFactorAuthRequiredException(this.message);

  @override
  String toString() => message;
}
