const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Formats a date-only value from the API for display: "April 24, 2001".
///
/// The backend sends a birthday as a full timestamp
/// ("2001-04-24T00:00:00.000000Z"), but a birthday has no time and no time
/// zone. The calendar date is read straight from the text instead of going
/// through `DateTime.parse(...).toLocal()`, which would show April 23 to anyone
/// west of UTC. Anything that is not an ISO date is returned unchanged.
String formatDateOnly(String raw) {
  final value = raw.trim();
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:$|[T\s])').firstMatch(value);
  if (match == null) return value;

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final daysInMonth = DateTime.utc(year, month + 1, 0).day;
  if (month < 1 || month > 12 || day < 1 || day > daysInMonth) return value;

  return '${_monthNames[month - 1]} $day, $year';
}
