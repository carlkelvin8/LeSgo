class LoginValidator {
  // Mirrors what the API accepts: local part may contain + % etc., and the
  // TLD may be any length (".company", ".photography"). The previous pattern
  // rejected "name+tag@gmail.com" and TLDs longer than 4 characters.
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*\.[a-zA-Z]{2,}$',
  );

  /// Validates email address (surrounding whitespace added by keyboards or
  /// paste is ignored; callers trim before sending).
  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Please enter your email';
    }

    if (!_emailPattern.hasMatch(text)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  /// Validates email or phone number
  static String? emailOrPhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Please enter your email or phone';
    }

    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');

    if (!_emailPattern.hasMatch(text) && !phoneRegex.hasMatch(text)) {
      return 'Please enter a valid email or phone number';
    }

    return null;
  }

  /// Sign-in password: only require that something was typed. The API is the
  /// source of truth for credentials; enforcing a minimum length here locked
  /// out existing accounts whose password is shorter than the sign-up rule.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  /// Validates password
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    
    return null;
  }

  /// Validates strong password (with uppercase, lowercase, number requirement)
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  /// Validates phone number
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    
    // Philippine mobile numbers: 09xx-xxx-xxxx or +639xx-xxx-xxxx
    final cleanNumber = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it's a valid Philippine number
    if (cleanNumber.startsWith('+63')) {
      if (cleanNumber.length != 13) {
        return 'Please enter a valid phone number';
      }
    } else if (cleanNumber.startsWith('09')) {
      if (cleanNumber.length != 11) {
        return 'Please enter a valid phone number';
      }
    } else {
      return 'Phone number must start with +63 or 09';
    }
    
    return null;
  }

  /// Validates confirm password matches original
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Generic required field validator
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return 'Please enter ${fieldName ?? 'this field'}';
    }
    
    return null;
  }

  /// Validates minimum length
  static String? minLength(String? value, int length, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return 'Please enter ${fieldName ?? 'this field'}';
    }
    
    if (value.length < length) {
      return '${fieldName ?? 'This field'} must be at least $length characters';
    }
    
    return null;
  }

  /// Validates maximum length
  static String? maxLength(String? value, int length, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return 'Please enter ${fieldName ?? 'this field'}';
    }
    
    if (value.length > length) {
      return '${fieldName ?? 'This field'} must not exceed $length characters';
    }
    
    return null;
  }
}
