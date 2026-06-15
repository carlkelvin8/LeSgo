import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class RiderEarningsInsightsNotifier
    extends StateNotifier<RiderEarningsInsightsState> {
  RiderEarningsInsightsNotifier() : super(const RiderEarningsInsightsState()) {
    _generateSampleData();
  }

  void _generateSampleData() {
    final now = DateTime.now();
    final daily = <RiderEarningsDayData>[];

    double totalEarnings = 0;
    int totalTrips = 0;
    double totalHours = 0;

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final baseEarnings = 400.0 + (i % 7) * 50.0 + (i % 3) * 30.0;
      final trips = 3 + (i % 5);
      final dayEarnings = baseEarnings + (trips * 20.0);
      daily.add(RiderEarningsDayData(
        date: date,
        earnings: dayEarnings,
        trips: trips,
      ));
      totalEarnings += dayEarnings;
      totalTrips += trips;
      totalHours += 4.0 + (trips * 0.5);
    }

    final avgPerDay = totalEarnings / 30;
    final avgPerTrip = totalTrips > 0 ? totalEarnings / totalTrips : 0.0;
    final avgPerHour = totalHours > 0 ? totalEarnings / totalHours : 0.0;

    final currentWeekEarnings = daily
        .sublist(daily.length - 7)
        .fold<double>(0, (sum, d) => sum + d.earnings);
    final prevWeekEarnings = daily
        .sublist(daily.length - 14, daily.length - 7)
        .fold<double>(0, (sum, d) => sum + d.earnings);
    final change = prevWeekEarnings > 0
        ? ((currentWeekEarnings - prevWeekEarnings) / prevWeekEarnings) * 100
        : 0.0;

    final dayTotals = <int, double>{};
    for (final d in daily) {
      final day = d.date.weekday;
      dayTotals[day] = (dayTotals[day] ?? 0) + d.earnings;
    }
    final bestDayNum = dayTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final proj = (totalEarnings / 30) * 7 + currentWeekEarnings;

    state = RiderEarningsInsightsState(
      dailyEarnings: daily,
      totalEarnings: totalEarnings,
      averageEarningsPerDay: avgPerDay,
      averageEarningsPerTrip: avgPerTrip,
      averageEarningsPerHour: avgPerHour,
      totalTrips: totalTrips,
      totalHoursOnline: totalHours,
      bestDay: _dayName(bestDayNum),
      bestHourRange: '9 AM - 12 PM',
      projectedEarnings: proj,
      previousPeriodEarnings: prevWeekEarnings,
      percentageChange: change,
    );
  }

  String _dayName(int day) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[day - 1];
  }
}

final riderEarningsInsightsProvider = StateNotifierProvider<
    RiderEarningsInsightsNotifier, RiderEarningsInsightsState>(
  (ref) => RiderEarningsInsightsNotifier(),
);
