import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/utils/rider_earnings_utils.dart';

class RiderEarningsDayData {
  final DateTime date;
  final double earnings;
  final int trips;

  const RiderEarningsDayData({
    required this.date,
    required this.earnings,
    required this.trips,
  });
}

class RiderEarningsInsightsState {
  final List<RiderEarningsDayData> dailyEarnings;
  final double totalEarnings;
  final double averageEarningsPerDay;
  final double averageEarningsPerTrip;
  final double averageEarningsPerHour;
  final int totalTrips;
  final double totalHoursOnline;
  final String bestDay;
  final String bestHourRange;
  final double projectedEarnings;
  final double previousPeriodEarnings;
  final double percentageChange;

  const RiderEarningsInsightsState({
    this.dailyEarnings = const [],
    this.totalEarnings = 0,
    this.averageEarningsPerDay = 0,
    this.averageEarningsPerTrip = 0,
    this.averageEarningsPerHour = 0,
    this.totalTrips = 0,
    this.totalHoursOnline = 0,
    this.bestDay = '--',
    this.bestHourRange = '--',
    this.projectedEarnings = 0,
    this.previousPeriodEarnings = 0,
    this.percentageChange = 0,
  });
}

final riderEarningsInsightsProvider =
    FutureProvider.autoDispose<RiderEarningsInsightsState>((ref) async {
  final monthData = await ApiService.getDriverEarnings(period: 'month');
  final entries = _parseEntries(monthData);
  final summaryRaw = monthData['summary'] as Map<String, dynamic>? ?? {};

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dayBuckets = <DateTime, _DayAggregate>{};

  for (int i = 29; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
    dayBuckets[date] = _DayAggregate();
  }

  for (final entry in entries) {
    final completedAt = entry.completedAt;
    if (completedAt == null) continue;

    final day = DateTime(
      completedAt.year,
      completedAt.month,
      completedAt.day,
    );
    final bucket = dayBuckets[day];
    if (bucket == null) continue;

    bucket.earnings += entry.earnings;
    bucket.trips += 1;
  }

  final dailyEarnings = dayBuckets.entries
      .map(
        (entry) => RiderEarningsDayData(
          date: entry.key,
          earnings: entry.value.earnings,
          trips: entry.value.trips,
        ),
      )
      .toList();

  final totalEarnings =
      (summaryRaw['total_earnings'] as num?)?.toDouble() ??
      dailyEarnings.fold<double>(0, (sum, day) => sum + day.earnings);
  final totalTrips = (summaryRaw['completed_trips'] as num?)?.toInt() ??
      dailyEarnings.fold<int>(0, (sum, day) => sum + day.trips);

  final daysWithData =
      dailyEarnings.where((day) => day.earnings > 0 || day.trips > 0).length;
  final divisor = daysWithData > 0 ? daysWithData : dailyEarnings.length;

  final avgPerDay = totalEarnings / divisor;
  final avgPerTrip = totalTrips > 0 ? totalEarnings / totalTrips : 0.0;
  const minutesPerTrip = 25.0;
  final totalHoursOnline = (totalTrips * minutesPerTrip) / 60;
  final avgPerHour =
      totalHoursOnline > 0 ? totalEarnings / totalHoursOnline : 0.0;

  final currentWeekEarnings = dailyEarnings
      .sublist(dailyEarnings.length - 7)
      .fold<double>(0, (sum, day) => sum + day.earnings);
  final previousPeriodEarnings = dailyEarnings
      .sublist(dailyEarnings.length - 14, dailyEarnings.length - 7)
      .fold<double>(0, (sum, day) => sum + day.earnings);
  final percentageChange = previousPeriodEarnings > 0
      ? ((currentWeekEarnings - previousPeriodEarnings) /
              previousPeriodEarnings) *
          100
      : 0.0;

  final projectedEarnings = avgPerDay * 7;

  var bestDay = '--';
  var bestHourRange = '--';

  final dayTotals = <int, double>{};
  for (final day in dailyEarnings) {
    if (day.earnings <= 0) continue;
    final weekday = day.date.weekday;
    dayTotals[weekday] = (dayTotals[weekday] ?? 0) + day.earnings;
  }
  if (dayTotals.isNotEmpty) {
    final bestWeekday = dayTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    bestDay = _weekdayName(bestWeekday);
  }

  try {
    final analyticsResponse = await ApiService.dio.get(
      '/v1/drivers/me/trips/analytics',
      queryParameters: {'period': 'month'},
    );
    final analytics =
        (analyticsResponse.data['data'] ?? analyticsResponse.data)
            as Map<String, dynamic>;

    final peakHour = analytics['peak_hour']?.toString().trim();
    if (peakHour != null && peakHour.isNotEmpty) {
      bestHourRange = peakHour;
    }

    final analyticsBestDay = analytics['best_earning_day']?.toString().trim();
    if (analyticsBestDay != null && analyticsBestDay.isNotEmpty) {
      bestDay = analyticsBestDay;
    }
  } catch (_) {
    // Trip analytics is optional; weekday totals above are the fallback.
  }

  return RiderEarningsInsightsState(
    dailyEarnings: dailyEarnings,
    totalEarnings: totalEarnings,
    averageEarningsPerDay: avgPerDay,
    averageEarningsPerTrip: avgPerTrip,
    averageEarningsPerHour: avgPerHour,
    totalTrips: totalTrips,
    totalHoursOnline: totalHoursOnline,
    bestDay: bestDay,
    bestHourRange: bestHourRange,
    projectedEarnings: projectedEarnings,
    previousPeriodEarnings: previousPeriodEarnings,
    percentageChange: percentageChange,
  );
});

List<RiderEarningsEntry> _parseEntries(Map<String, dynamic> data) {
  final entriesRaw = data['entries'] as List<dynamic>? ?? [];
  return entriesRaw
      .whereType<Map>()
      .map((item) {
        final map = Map<String, dynamic>.from(item);
        return RiderEarningsEntry(
          orderId: (map['order_id'] as num?)?.toInt() ?? 0,
          serviceName: map['service_name']?.toString() ?? 'Order',
          earnings: (map['earnings'] as num?)?.toDouble() ?? 0,
          completedAt: map['completed_at'] != null
              ? DateTime.tryParse(map['completed_at'].toString())?.toLocal()
              : null,
        );
      })
      .toList();
}

String _weekdayName(int weekday) {
  const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return names[weekday - 1];
}

class _DayAggregate {
  double earnings = 0;
  int trips = 0;
}
