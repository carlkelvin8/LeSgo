class LestransportValidator {
  /// Validates sender name
  static String? senderName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter sender name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  /// Validates contact number for LesTransport
  static String? contactNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter contact number';
    }
    
    final cleanNumber = value.trim().replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check if it starts with +63 or 0
    if (!cleanNumber.startsWith('+63') && !cleanNumber.startsWith('0')) {
      return 'Phone number must start with +63 or 0';
    }
    
    // Check length
    if (cleanNumber.startsWith('+63')) {
      if (cleanNumber.length != 13) {
        return 'Phone number must be 11 digits after +63';
      }
    } else if (cleanNumber.startsWith('0')) {
      if (cleanNumber.length != 11) {
        return 'Phone number must be 11 digits';
      }
    }
    
    return null;
  }

  /// Validates sender address
  static String? senderAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter sender address';
    }
    if (value.trim().length < 10) {
      return 'Address must be at least 10 characters';
    }
    return null;
  }

  /// Validates branch address for padala option
  static String? branchAddress(String? value, {required bool isRequired}) {
    if (!isRequired) {
      return null;
    }
    
    if (value == null || value.trim().isEmpty) {
      return 'Please enter branch address';
    }
    if (value.trim().length < 5) {
      return 'Branch address must be at least 5 characters';
    }
    return null;
  }
}
