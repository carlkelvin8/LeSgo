/// Helpers for Philippine mobile numbers.
class PhoneUtils {
  PhoneUtils._();

  /// Converts any common way of typing a PH mobile number to E.164
  /// (`+639171234567`): no spaces or dashes, no duplicated leading zero.
  ///
  /// Accepts `+63 917 123 4567`, `+63 0917...`, `0917...`, `63917...`, `917...`.
  /// Returns an empty string for empty input.
  static String normalizePh(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';

    if (digits.startsWith('63')) {
      digits = digits.substring(2);
    }
    // A local number written with its trunk prefix ("0917...", or "+63 0917...").
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    // Only the "+63 " prefix of an untouched field: treat as empty.
    if (digits.isEmpty) return '';
    return '+63$digits';
  }
}
