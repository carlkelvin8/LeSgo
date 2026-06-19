class AddressValidator {
  static String? houseNumberStreet(String? value) {
    // Make this optional since GPS can't determine exact house number
    if (value == null || value.trim().isEmpty) {
      return null; // Allow empty
    }
    if (value.trim().length < 3) {
      return 'Address must be at least 3 characters';
    }
    return null;
  }

  static String? subdivisionBarangay(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your subdivision or barangay';
    }
    if (value.trim().length < 2) {
      return 'This field must be at least 2 characters';
    }
    return null;
  }

  static String? cityProvince(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your city/municipality and province';
    }
    if (value.trim().length < 3) {
      return 'This field must be at least 3 characters';
    }
    return null;
  }

  static String? zipCode(String? value) {
    // Make zip code optional - GPS locations might not have accurate zip codes
    if (value == null || value.trim().isEmpty) {
      return null; // Allow empty
    }
    
    final cleanValue = value.trim().replaceAll(' ', '');
    
    if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
      return 'Zip code must contain only numbers';
    }
    
    if (cleanValue.length != 4) {
      return 'Zip code must be 4 digits';
    }
    
    return null;
  }

  static String? landmark(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    
    if (value.trim().length < 3) {
      return 'Landmark must be at least 3 characters';
    }
    
    return null;
  }

 
  static String? validateFullAddress({
    required String? houseNumber,
    required String? subdivision,
    required String? city,
    required String? zipCode,
  }) {
    if (houseNumberStreet(houseNumber) != null) {
      return 'Please complete your house number and street';
    }
    if (subdivisionBarangay(subdivision) != null) {
      return 'Please complete your subdivision/barangay';
    }
    if (cityProvince(city) != null) {
      return 'Please complete your city/municipality and province';
    }
    if (AddressValidator.zipCode(zipCode) != null) {
      return 'Please provide a valid zip code';
    }
    return null;
  }
}
