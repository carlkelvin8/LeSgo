import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/utils/history_grouping.dart';

void main() {
  final now = DateTime(2026, 11, 22, 15, 0);

  test('day labels', () {
    expect(HistoryGrouping.dayLabel(DateTime(2026, 11, 22, 1), now), 'Today');
    expect(HistoryGrouping.dayLabel(DateTime(2026, 11, 21, 23), now), 'Yesterday');
    expect(HistoryGrouping.dayLabel(DateTime(2026, 11, 18), now), 'Wednesday, Nov 18');
    expect(HistoryGrouping.dayLabel(DateTime(2025, 12, 31), now), 'Dec 31, 2025');
  });

  test('month labels', () {
    expect(HistoryGrouping.monthLabel(DateTime(2026, 11, 1), now), 'This month');
    expect(HistoryGrouping.monthLabel(DateTime(2026, 9, 30), now), 'September');
    expect(HistoryGrouping.monthLabel(DateTime(2025, 3, 5), now), 'March 2025');
  });

  test('grouping keeps order and puts undated items under their own heading', () {
    final items = ['2026-11-22T10:00:00', '2026-11-22T08:00:00', '2026-11-21T20:00:00', 'oops'];
    final groups = HistoryGrouping.group<String>(
      items,
      HistoryGrouping.parse,
      (d) => HistoryGrouping.dayLabel(d, now),
    );
    expect(groups.map((g) => g.label), ['Today', 'Yesterday', 'Date unavailable']);
    expect(groups.first.items.length, 2);
  });
}
