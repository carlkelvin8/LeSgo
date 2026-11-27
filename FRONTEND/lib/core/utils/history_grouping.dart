import 'package:intl/intl.dart';

/// A run of list items that share a date heading ("Today", "November 2026").
class DateGroup<T> {
  const DateGroup(this.label, this.items);
  final String label;
  final List<T> items;
}

/// Date headings and grouping for the Transactions and Order History lists.
class HistoryGrouping {
  HistoryGrouping._();

  static DateTime? parse(String? raw) =>
      DateTime.tryParse(raw ?? '')?.toLocal();

  /// "Today", "Yesterday", "Monday, Nov 17", or "Nov 17, 2025" for older years.
  static String dayLabel(DateTime d, DateTime now) {
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (d.year == now.year) return DateFormat('EEEE, MMM d').format(d);
    return DateFormat('MMM d, yyyy').format(d);
  }

  /// "This month", "October", or "October 2025" for older years.
  static String monthLabel(DateTime d, DateTime now) {
    if (d.year == now.year && d.month == now.month) return 'This month';
    if (d.year == now.year) return DateFormat('MMMM').format(d);
    return DateFormat('MMMM yyyy').format(d);
  }

  /// Groups consecutive items that get the same label, keeping their order
  /// (the lists arrive newest first). Items without a date go under
  /// [unknownLabel].
  static List<DateGroup<T>> group<T>(
    List<T> items,
    DateTime? Function(T) dateOf,
    String Function(DateTime) labelOf, {
    String unknownLabel = 'Date unavailable',
  }) {
    final groups = <DateGroup<T>>[];
    for (final item in items) {
      final d = dateOf(item);
      final label = d == null ? unknownLabel : labelOf(d);
      if (groups.isNotEmpty && groups.last.label == label) {
        groups.last.items.add(item);
      } else {
        groups.add(DateGroup<T>(label, [item]));
      }
    }
    return groups;
  }
}
