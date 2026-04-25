class OtpValidator {
  /// Validates phone number format
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }


    final cleanNumber = value.replaceAll(RegExp(r'[^\d+]'), '');


    if (!cleanNumber.startsWith('+63')) {
      return 'Phone number must start with +63';
    }

    if (cleanNumber.length < 13) {
      return 'Phone number must be at least 10 digits';
    }

    return null;
  }


  static String? otpCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP code is required';
    }

    if (value.length != 6) {
      return 'OTP code must be 6 digits';
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'OTP code must contain only numbers';
    }

    return null;
  }

  static bool isOtpComplete(List<String> otpDigits) {
    if (otpDigits.length != 6) return false;
    return otpDigits.every((digit) => digit.isNotEmpty);
  }
}
