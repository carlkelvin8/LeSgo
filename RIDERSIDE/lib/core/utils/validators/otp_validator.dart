class OtpValidator {
  /// Validates phone number format (Philippine format)
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final cleanNumber = value.replaceAll(RegExp(r'[^\d+]'), '');

    // Check if it starts with +63 or 09
    if (cleanNumber.startsWith('+63')) {
      if (cleanNumber.length < 13) {
        return 'Phone number must be at least 10 digits';
      }
    } else if (cleanNumber.startsWith('09')) {
      if (cleanNumber.length < 11) {
        return 'Phone number must be at least 10 digits';
      }
    } else {
      return 'Phone number must start with +63 or 09';
    }

    return null;
  }

  /// Validates OTP code
  static String? otpCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP code is required';
    }

    if (value.length != 4) {
      return 'OTP code must be 4 digits';
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'OTP code must contain only numbers';
    }

    return null;
  }

  /// Checks if OTP is complete (for split OTP inputs)
  static bool isOtpComplete(List<String> otpDigits) {
    if (otpDigits.length != 4) return false;
    return otpDigits.every((digit) => digit.isNotEmpty);
  }

  /// Validates a single OTP digit
  static String? otpDigit(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Allow empty for individual digits
    }

    if (value.length > 1) {
      return 'Only one digit allowed';
    }

    if (!RegExp(r'^\d$').hasMatch(value)) {
      return 'Must be a number';
    }

    return null;
  }
}
