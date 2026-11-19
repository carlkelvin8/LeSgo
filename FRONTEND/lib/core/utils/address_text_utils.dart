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

/// Joins address parts with ", ", skipping null/blank parts and comma
/// segments already present in the text so far (case-insensitive). Branch rows
/// often repeat the city or province inside `address_line1`
/// ("Claveria, Cagayan" + city "Claveria"), which would otherwise print
/// "Claveria, Cagayan, Claveria, Cagayan Valley".
///
/// A part that is itself a comma list is split, so only its new segments are
/// added: ["Claveria, Cagayan", "Claveria", "Cagayan Valley"] becomes
/// "Claveria, Cagayan, Cagayan Valley".
String joinAddressParts(Iterable<Object?> parts) {
  final segments = <String>[];
  final seen = <String>{};
  for (final part in parts) {
    if (part == null) continue;
    for (final raw in part.toString().split(',')) {
      final segment = raw.trim();
      if (segment.isEmpty) continue;
      if (seen.add(segment.toLowerCase())) segments.add(segment);
    }
  }
  return segments.join(', ');
}
