/// Centralized validation utilities for form fields
/// Provides consistent validation across the app with helpful error messages
class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  /// Email validation
  /// Returns error message if invalid, null if valid
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Philippine phone number validation
  /// Accepts formats: 09XXXXXXXXX, +639XXXXXXXXX, 639XXXXXXXXX
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces, dashes, and parentheses
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Philippine phone formats:
    // 09XXXXXXXXX (11 digits)
    // +639XXXXXXXXX (13 digits)
    // 639XXXXXXXXX (12 digits)
    final phoneRegex = RegExp(r'^(09|\+639|639)\d{9}$');

    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Please enter a valid Philippine phone number';
    }

    return null;
  }

  /// Email or Phone validation
  /// Automatically detects which format and validates accordingly
  static String? emailOrPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email or phone number is required';
    }

    // Check if it looks like an email (contains @)
    if (value.contains('@')) {
      return email(value);
    }

    // Otherwise treat as phone number
    return phone(value);
  }

  /// Strong password validation
  /// Requirements:
  /// - At least 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one number
  /// - At least one special character
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (value.length > 64) {
      return 'Password must not exceed 64 characters';
    }

    // Check for uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  /// Password confirmation validation
  /// Checks if password and confirmation match
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Name validation (for first name, last name, etc.)
  /// Allows letters, spaces, hyphens, and apostrophes
  static String? name(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    if (value.length > 100) {
      return '$fieldName must not exceed 100 characters';
    }

    // Only letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Generic required field validation
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Number validation with optional min/max constraints
  static String? number(
    String? value, {
    String fieldName = 'This field',
    double? min,
    double? max,
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }

    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      return '$fieldName must not exceed $max';
    }

    return null;
  }

  /// Price validation (0 to 999,999.99)
  static String? price(String? value) {
    return number(
      value,
      fieldName: 'Price',
      min: 0,
      max: 999999.99,
    );
  }

  /// URL validation
  static String? url(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'URL is required' : null;
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  /// Address validation
  static String? address(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }

    if (value.trim().length < 10) {
      return 'Please enter a complete address';
    }

    if (value.length > 500) {
      return 'Address is too long (max 500 characters)';
    }

    return null;
  }

  /// Date validation
  static String? date(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }

    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  /// Age validation (must be 18+)
  static String? age(DateTime? birthDate) {
    if (birthDate == null) {
      return 'Birth date is required';
    }

    final age = DateTime.now().difference(birthDate).inDays ~/ 365;

    if (age < 18) {
      return 'You must be at least 18 years old';
    }

    if (age > 120) {
      return 'Please enter a valid birth date';
    }

    return null;
  }

  /// Minimum length validation
  static String? minLength(String? value, int min, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < min) {
      return '$fieldName must be at least $min characters';
    }

    return null;
  }

  /// Maximum length validation
  static String? maxLength(String? value, int max, {String fieldName = 'This field'}) {
    if (value == null) return null;

    if (value.length > max) {
      return '$fieldName must not exceed $max characters';
    }

    return null;
  }

  /// Length range validation
  static String? lengthRange(
    String? value,
    int min,
    int max, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < min || value.length > max) {
      return '$fieldName must be between $min and $max characters';
    }

    return null;
  }

  /// OTP validation (6 digits)
  static String? otp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }

    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }

    return null;
  }

  /// Credit card number validation (basic)
  static String? creditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }

    final cleaned = value.replaceAll(RegExp(r'\s'), '');

    if (cleaned.length < 13 || cleaned.length > 19) {
      return 'Please enter a valid card number';
    }

    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Card number must contain only digits';
    }

    return null;
  }

  /// CVV validation
  static String? cvv(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }

    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return 'CVV must be 3 or 4 digits';
    }

    return null;
  }

  /// Expiry date validation (MM/YY format)
  static String? expiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }

    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Format must be MM/YY';
    }

    final parts = value.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || month < 1 || month > 12) {
      return 'Invalid month';
    }

    if (year == null) {
      return 'Invalid year';
    }

    // Check if card is expired
    final now = DateTime.now();
    final expiryYear = 2000 + year;
    final expiryDate = DateTime(expiryYear, month + 1, 0);

    if (expiryDate.isBefore(now)) {
      return 'Card has expired';
    }

    return null;
  }
}
