/// Strips a leading Google Plus Code (e.g. "9JGQ+2X, ") from a geocoded address.
String stripPlusCode(String address) {
  final stripped =
      address.replaceFirst(RegExp(r'^[A-Z0-9]{4,}\+[A-Z0-9]{2,}[,\s]*'), '');
  return stripped.isEmpty ? address : stripped.trim();
}
