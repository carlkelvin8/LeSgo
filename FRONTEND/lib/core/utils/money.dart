import 'package:intl/intl.dart';

/// One place for how peso amounts look in the UI, so every screen shows
/// "₱1,234.50" instead of a mix of "PHP", "Php" and "₱".
///
/// Don't use this for PDF receipts (the PDF font has no ₱ glyph) or for text
/// sent to the backend.
class Money {
  Money._();

  static const String symbol = '₱';

  static final NumberFormat _two = NumberFormat('#,##0.00');
  static final NumberFormat _zero = NumberFormat('#,##0');

  /// "₱1,234.50". Pass `decimals: 0` for whole-peso prices such as menu items.
  static String format(num amount, {int decimals = 2}) {
    final fmt = decimals == 0 ? _zero : _two;
    return '$symbol${fmt.format(amount)}';
  }

  /// Like [format] but always shows the sign: "+₱60.00" / "-₱60.00".
  static String signed(num amount, {int decimals = 2}) {
    final sign = amount < 0 ? '-' : '+';
    return '$sign${format(amount.abs(), decimals: decimals)}';
  }
}
