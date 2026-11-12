import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_logger.dart';

/// Trip analytics provider for detailed trip insights
final riderTripAnalyticsProvider = StateNotifierProvider.autoDispose<RiderTripAnalyticsNotifier, RiderTripAnalyticsState>(
  (ref) => RiderTripAnalyticsNotifier(),
);

class RiderTripAnalyticsNotifier extends StateNotifier<RiderTripAnalyticsState> {
  RiderTripAnalyticsNotifier() : super(const RiderTripAnalyticsState()) {
    // The screen's ref.listen never fires for the initial state, so load here.
    Future.microtask(() {
      if (mounted) loadTripAnalytics();
    });
  }

  Future<void> loadTripAnalytics({String period = 'week'}) async {
    state = state.copyWith(isLoading: true, clearError: true, period: period);
    try {
      // /v1/drivers/me/trips/analytics does not exist (404); build the same
      // figures from the real earnings endpoint.
      final data = await ApiService.getDriverEarnings(period: period);
      if (!mounted) return;
      state = buildTripAnalyticsState(data, period).copyWith(isLoading: false);
    } catch (e) {
      AppLogger.error('Failed to load trip analytics', e);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load analytics',
      );
    }
  }

  Future<void> refreshAnalytics() async {
    await loadTripAnalytics(period: state.period);
  }
}

class RiderTripAnalyticsState {
  final String bestEarningDay;
  final double bestEarningDayAmount;
  final String peakHour;
  final double avgEarningsPerTrip;
  final double totalDistanceTraveled;
  final int totalTrips;
  final double totalEarnings;
  final List<HourlyBreakdown> hourlyBreakdown;
  final List<DailyBreakdown> dailyBreakdown;
  final bool isLoading;
  final String? error;
  final String period;

  const RiderTripAnalyticsState({
    this.bestEarningDay = '',
    this.bestEarningDayAmount = 0.0,
    this.peakHour = '',
    this.avgEarningsPerTrip = 0.0,
    this.totalDistanceTraveled = 0.0,
    this.totalTrips = 0,
    this.totalEarnings = 0.0,
    this.hourlyBreakdown = const [],
    this.dailyBreakdown = const [],
    this.isLoading = false,
    this.error,
    this.period = 'week',
  });

  String get bestEarningDayFormatted => 'PHP ${bestEarningDayAmount.toStringAsFixed(2)}';
  String get bestEarningDayDisplay =>
      bestEarningDay.isEmpty ? '—' : bestEarningDay;
  String get peakHourDisplay => peakHour.isEmpty ? '—' : peakHour;
  String get avgEarningsPerTripFormatted => 'PHP ${avgEarningsPerTrip.toStringAsFixed(2)}';
  String get totalDistanceFormatted => '${totalDistanceTraveled.toStringAsFixed(1)} km';
  String get totalEarningsFormatted => 'PHP ${totalEarnings.toStringAsFixed(2)}';

  RiderTripAnalyticsState copyWith({
    String? bestEarningDay,
    double? bestEarningDayAmount,
    String? peakHour,
    double? avgEarningsPerTrip,
    double? totalDistanceTraveled,
    int? totalTrips,
    double? totalEarnings,
    List<HourlyBreakdown>? hourlyBreakdown,
    List<DailyBreakdown>? dailyBreakdown,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? period,
  }) {
    return RiderTripAnalyticsState(
      bestEarningDay: bestEarningDay ?? this.bestEarningDay,
      bestEarningDayAmount: bestEarningDayAmount ?? this.bestEarningDayAmount,
      peakHour: peakHour ?? this.peakHour,
      avgEarningsPerTrip: avgEarningsPerTrip ?? this.avgEarningsPerTrip,
      totalDistanceTraveled: totalDistanceTraveled ?? this.totalDistanceTraveled,
      totalTrips: totalTrips ?? this.totalTrips,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      hourlyBreakdown: hourlyBreakdown ?? this.hourlyBreakdown,
      dailyBreakdown: dailyBreakdown ?? this.dailyBreakdown,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      period: period ?? this.period,
    );
  }
}

class HourlyBreakdown {
  final String hour;
  final double earnings;
  final int trips;

  const HourlyBreakdown({
    required this.hour,
    required this.earnings,
    required this.trips,
  });

  factory HourlyBreakdown.fromJson(Map<String, dynamic> json) {
    return HourlyBreakdown(
      hour: json['hour']?.toString() ?? '',
      earnings: (json['earnings'] as num?)?.toDouble() ?? 0.0,
      trips: json['trips'] as int? ?? 0,
    );
  }
}

class DailyBreakdown {
  final String day;
  final double earnings;
  final int trips;
  final double distance;

  const DailyBreakdown({
    required this.day,
    required this.earnings,
    required this.trips,
    required this.distance,
  });

  factory DailyBreakdown.fromJson(Map<String, dynamic> json) {
    return DailyBreakdown(
      day: json['day']?.toString() ?? '',
      earnings: (json['earnings'] as num?)?.toDouble() ?? 0.0,
      trips: json['trips'] as int? ?? 0,
      distance: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

double _taNum(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

/// Builds trip analytics from a `/v1/drivers/me/earnings` payload
/// (`summary` + `entries`; `entries` may arrive as an empty `[]`).
@visibleForTesting
RiderTripAnalyticsState buildTripAnalyticsState(
  Map<String, dynamic> data,
  String period,
) {
  final summary = data['summary'] is Map ? data['summary'] as Map : const {};
  final entries = data['entries'] is List
      ? (data['entries'] as List).whereType<Map>().toList()
      : <Map>[];

  final byHour = <int, List<double>>{};
  final byDay = <DateTime, List<double>>{};
  var entryTotal = 0.0;
  for (final e in entries) {
    final earnings = _taNum(e['earnings']);
    entryTotal += earnings;
    final at = DateTime.tryParse(e['completed_at']?.toString() ?? '')?.toLocal();
    if (at == null) continue;
    (byHour[at.hour] ??= []).add(earnings);
    (byDay[DateTime(at.year, at.month, at.day)] ??= []).add(earnings);
  }

  final totalTrips = summary['completed_trips'] != null
      ? _taNum(summary['completed_trips']).toInt()
      : entries.length;
  final totalEarnings = summary['total_earnings'] != null
      ? _taNum(summary['total_earnings'])
      : entryTotal;
  final avg = summary['average_per_trip'] != null
      ? _taNum(summary['average_per_trip'])
      : (totalTrips > 0 ? totalEarnings / totalTrips : 0.0);

  double sum(List<double> l) => l.fold(0.0, (a, b) => a + b);
  String hourLabel(int h) {
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12 ${h < 12 ? 'AM' : 'PM'}';
  }

  final hourly = (byHour.keys.toList()..sort())
      .map((h) => HourlyBreakdown(
            hour: hourLabel(h),
            earnings: sum(byHour[h]!),
            trips: byHour[h]!.length,
          ))
      .toList();
  final days = byDay.keys.toList()..sort();
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final daily = days
      .map((d) => DailyBreakdown(
            day: '${names[d.weekday - 1]} ${d.month}/${d.day}',
            earnings: sum(byDay[d]!),
            trips: byDay[d]!.length,
            distance: 0,
          ))
      .toList();

  var bestDay = '';
  var bestDayAmount = 0.0;
  for (final d in daily) {
    if (d.earnings > bestDayAmount) {
      bestDayAmount = d.earnings;
      bestDay = d.day;
    }
  }
  var peakHour = '';
  var peakEarn = 0.0;
  for (final h in hourly) {
    if (h.earnings > peakEarn) {
      peakEarn = h.earnings;
      peakHour = h.hour;
    }
  }

  return RiderTripAnalyticsState(
    bestEarningDay: bestDay,
    bestEarningDayAmount: bestDayAmount,
    peakHour: peakHour,
    avgEarningsPerTrip: avg,
    totalDistanceTraveled: 0,
    totalTrips: totalTrips,
    totalEarnings: totalEarnings,
    hourlyBreakdown: hourly,
    dailyBreakdown: daily,
    period: period,
  );
}
