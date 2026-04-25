class ProfileValidator {
  /// Validates profile name fields
  static String? name(String? value, {bool isRequired = false}) {
    if (!isRequired && (value == null || value.trim().isEmpty)) {
      return null; // Optional field
    }
    
    if (isRequired && (value == null || value.trim().isEmpty)) {
      return 'Please enter your name';
    }

    if (value!.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    // Only letters, spaces, hyphens, and apostrophes
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Validates profile address fields
  static String? address(String? value, {bool isRequired = false}) {
    if (!isRequired && (value == null || value.trim().isEmpty)) {
      return null; // Optional field
    }
    
    if (isRequired && (value == null || value.trim().isEmpty)) {
      return 'Please enter your address';
    }

    if (value!.trim().length < 5) {
      return 'Address must be at least 5 characters';
    }

    return null;
  }

  /// Validates referral code
  static String? referralCode(String? value) {
    // Referral code is optional
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final cleanCode = value.trim().toUpperCase();
    
    // Must be alphanumeric
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(cleanCode)) {
      return 'Referral code can only contain letters and numbers';
    }

    // Length check (assuming 6-10 characters)
    if (cleanCode.length < 6 || cleanCode.length > 10) {
      return 'Referral code must be 6-10 characters';
    }

    return null;
  }
}
