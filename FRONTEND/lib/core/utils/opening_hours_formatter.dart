/// Formats partner `opening_hours` payloads from the API for display.
class OpeningHoursFormatter {
  OpeningHoursFormatter._();

  static const _dayOrder = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const _dayShort = {
    'monday': 'Mon',
    'tuesday': 'Tue',
    'wednesday': 'Wed',
    'thursday': 'Thu',
    'friday': 'Fri',
    'saturday': 'Sat',
    'sunday': 'Sun',
  };

  /// Returns a human-readable hours string, or null when unavailable.
  static String? format(dynamic raw) {
    if (raw == null) return null;

    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }

    if (raw is List) {
      final parts = raw
          .map((e) => e?.toString().trim())
          .where((e) => e != null && e.isNotEmpty)
          .cast<String>()
          .toList();
      return parts.isEmpty ? null : parts.join(' • ');
    }

    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw);

    if (map['display'] != null && map['display'].toString().trim().isNotEmpty) {
      return map['display'].toString().trim();
    }
    if (map['summary'] != null && map['summary'].toString().trim().isNotEmpty) {
      return map['summary'].toString().trim();
    }

    final today = _formatToday(map);
    if (today != null) return today;

    final scheduleLines = <String>[];
    for (final day in _dayOrder) {
      final line = _formatDay(day, map[day] ?? map[day.substring(0, 3)]);
      if (line != null) scheduleLines.add('${_dayShort[day]} $line');
    }

    if (scheduleLines.isEmpty) {
      for (final entry in map.entries) {
        if (entry.value is Map || entry.value is String) {
          final line = _formatDay(entry.key, entry.value);
          if (line != null) {
            scheduleLines.add('${entry.key}: $line');
          }
        }
      }
    }

    return scheduleLines.isEmpty ? null : scheduleLines.join(' • ');
  }

  static String? _formatToday(Map<String, dynamic> map) {
    final now = DateTime.now();
    final dayKey = _dayOrder[now.weekday - 1];
    final todayValue = map[dayKey] ?? map[dayKey.substring(0, 3)];
    final line = _formatDay(dayKey, todayValue);
    if (line == null) return null;
    return 'Today (${_dayShort[dayKey]}): $line';
  }

  static String? _formatDay(String day, dynamic value) {
    if (value == null) return null;

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    if (value is Map) {
      final dayMap = Map<String, dynamic>.from(value);
      final closed = dayMap['closed'] == true ||
          dayMap['is_closed'] == true ||
          dayMap['isClosed'] == true;
      if (closed) return 'Closed';

      final open = _time(dayMap['open'] ?? dayMap['opens_at'] ?? dayMap['open_time']);
      final close =
          _time(dayMap['close'] ?? dayMap['closes_at'] ?? dayMap['close_time']);
      if (open != null && close != null) return '$open – $close';
      if (open != null) return 'Opens $open';
      if (close != null) return 'Closes $close';
    }

    return null;
  }

  static String? _time(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;

    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(text)) {
      return _to12Hour(text);
    }
    return text;
  }

  static String _to12Hour(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:${minute.toString().padLeft(2, '0')} $period';
  }
}
