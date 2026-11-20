import '../phone_utils.dart';

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

    // Validate what will actually be sent (E.164), e.g. "+63 0917..." becomes
    // "+63917..." and must still have exactly 10 digits after +63.
    final normalized = PhoneUtils.normalizePh(value);
    if (!RegExp(r'^\+63\d{10}$').hasMatch(normalized)) {
      return 'Enter a valid 10-digit mobile number after +63';
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
