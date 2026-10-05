class RegisterValidator {
  /// Validates first name
  static String? firstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'First name is required';
    }

    if (value.trim().length < 2) {
      return 'First name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'First name must not exceed 50 characters';
    }

    // Check if contains only letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'First name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Validates last name
  static String? lastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Last name is required';
    }

    if (value.trim().length < 2) {
      return 'Last name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'Last name must not exceed 50 characters';
    }

    // Check if contains only letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Last name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Validates birthday/date of birth
  static String? birthday(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Birthday is required';
    }

    // Check if the format is valid (MM/DD/YYYY or YYYY-MM-DD)
    final dateRegex1 = RegExp(r'^\d{2}/\d{2}/\d{4}$'); // MM/DD/YYYY
    final dateRegex2 = RegExp(r'^\d{4}-\d{2}-\d{2}$'); // YYYY-MM-DD

    if (!dateRegex1.hasMatch(value.trim()) &&
        !dateRegex2.hasMatch(value.trim())) {
      return 'Please enter a valid date (MM/DD/YYYY or YYYY-MM-DD)';
    }

    try {
      DateTime date;
      if (dateRegex1.hasMatch(value.trim())) {
        // Parse MM/DD/YYYY
        final parts = value.trim().split('/');
        date = DateTime(
          int.parse(parts[2]),
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      } else {
        // Parse YYYY-MM-DD
        date = DateTime.parse(value.trim());
      }

      // Check if the date is in the past
      final now = DateTime.now();
      if (date.isAfter(now)) {
        return 'Birthday cannot be in the future';
      }

      // Check if the person is at least 18 years old
      final age = now.year - date.year;
      final hasHadBirthdayThisYear =
          now.month > date.month ||
          (now.month == date.month && now.day >= date.day);

      if (age < 18 || (age == 18 && !hasHadBirthdayThisYear)) {
        return 'You must be at least 18 years old';
      }

      // Check if the person is not older than 100 years
      if (age > 100) {
        return 'Please enter a valid birthday';
      }

      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  /// Validates email address
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    // RFC 5322 simplified email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates phone number
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Philippines mobile number format: 09xxxxxxxxx or 639xxxxxxxxx or +639xxxxxxxxx
    // Allow spaces, dashes, parentheses
    final cleanValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleanValue.length < 10) {
      return 'Phone number is too short';
    }

    final phoneRegex = RegExp(r'^(09|\+639|639)\d{9}$');

    if (!phoneRegex.hasMatch(cleanValue)) {
      if (cleanValue.startsWith('9') && cleanValue.length == 10) {
        // Accept 10 digit if it starts with 9 (implied 09 or +639) - adjusts to UI usually adding prefix
        return null;
      }
      return 'Please enter a valid PH mobile number';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? licenseNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Driver license number is required';
    }
    if (value.trim().length < 5) {
      return 'Enter a valid license number';
    }
    return null;
  }
}
