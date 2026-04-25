class ProfileValidator {
  /// Validates profile name fields
  static String? name(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return '$fieldName must not exceed 50 characters';
    }
    
    // Check if contains only letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  /// Validates address fields
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

    if (value.trim().length > 200) {
      return 'Address must not exceed 200 characters';
    }

    return null;
  }

  /// Validates referral code (optional field)
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

    // Length check (6-10 characters)
    if (cleanCode.length < 6 || cleanCode.length > 10) {
      return 'Referral code must be 6-10 characters';
    }

    return null;
  }

  /// Validates bio/description fields
  static String? bio(String? value, {int maxLength = 500}) {
    // Bio is optional
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (value.trim().length > maxLength) {
      return 'Bio must not exceed $maxLength characters';
    }

    return null;
  }

  /// Validates vehicle plate number
  static String? plateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Plate number is required';
    }

    final cleanPlate = value.trim().toUpperCase();
    
    // Philippine plate format: ABC 1234 or ABC1234
    final plateRegex = RegExp(r'^[A-Z0-9\s-]+$');
    if (!plateRegex.hasMatch(cleanPlate)) {
      return 'Please enter a valid plate number';
    }

    if (cleanPlate.length < 5 || cleanPlate.length > 10) {
      return 'Plate number must be 5-10 characters';
    }

    return null;
  }

  /// Validates license number
  static String? licenseNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'License number is required';
    }

    final cleanLicense = value.trim().toUpperCase();
    
    // Philippine license format: N##-##-######
    if (cleanLicense.length < 5 || cleanLicense.length > 15) {
      return 'Please enter a valid license number';
    }

    return null;
  }
}
