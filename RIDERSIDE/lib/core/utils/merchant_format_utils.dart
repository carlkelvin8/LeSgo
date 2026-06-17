/// Utility functions for formatting merchant-related data
class MerchantFormatUtils {
  MerchantFormatUtils._();

  /// Format a number as Philippine Peso currency
  /// Example: 1500.50 -> "PHP 1,500.50"
  static String formatPeso(dynamic value) {
    if (value == null) return 'PHP 0.00';

    final amount = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;

    // Format with thousand separators
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Add thousand separators
    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }

    return 'PHP ${buffer.toString()}.$decimalPart';
  }

  /// Format a number as Philippine Peso currency without the "PHP" prefix
  /// Example: 1500.50 -> "1,500.50"
  static String formatPesoAmount(dynamic value) {
    if (value == null) return '0.00';

    final amount = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;

    // Format with thousand separators
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Add thousand separators
    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }

    return '${buffer.toString()}.$decimalPart';
  }

  /// Alias for formatPeso - used in analytics
  static String formatMerchantPeso(dynamic value) => formatPeso(value);
}

// Top-level function for convenience
String formatMerchantPeso(dynamic value) => MerchantFormatUtils.formatPeso(value);
String formatPeso(dynamic value) => MerchantFormatUtils.formatPeso(value);
