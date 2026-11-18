/// Open Location Code ("plus code") such as `J36M+FR5`: 4-8 characters from the
/// code alphabet, a plus sign, then 2-3 more, optionally followed by a comma.
final RegExp _leadingPlusCode = RegExp(
  r'^[23456789CFGHJMPQRVWX]{4,8}\+[23456789CFGHJMPQRVWX]{2,3}\s*,?\s*',
  caseSensitive: false,
);

/// Google sometimes returns a plus code as the first part of a formatted
/// address ("J36M+FR5, Belado Avenue, Centro III"). It is meaningless to a
/// customer, so drop it. If the plus code is all there is, keep it rather than
/// showing an empty address.
String stripPlusCode(String address) {
  final cleaned = address.replaceFirst(_leadingPlusCode, '').trim();
  return cleaned.isEmpty ? address : cleaned;
}
