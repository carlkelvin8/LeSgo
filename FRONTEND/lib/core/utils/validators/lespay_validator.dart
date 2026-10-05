class LespayValidator {
  /// Validates amount for top-up and withdrawal
  static String? amount(String? value, {double? maxAmount}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an amount';
    }

    final amount = double.tryParse(value.trim());
    
    if (amount == null) {
      return 'Please enter a valid number';
    }

    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }

    if (amount < 10) {
      return 'Minimum amount is PHP 10.00';
    }

    if (amount > 100000) {
      return 'Maximum amount is PHP 100,000.00';
    }

    if (maxAmount != null && amount > maxAmount) {
      return 'Insufficient balance';
    }

    return null;
  }

  /// Validates top-up amount
  static String? topUpAmount(String? value) {
    return amount(value);
  }

  /// Validates withdrawal amount with balance check
  static String? withdrawAmount(String? value, double availableBalance) {
    return amount(value, maxAmount: availableBalance);
  }
}
