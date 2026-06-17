import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_logger.dart';

/// Trip analytics provider for detailed trip insights
final riderTripAnalyticsProvider = StateNotifierProvider.autoDispose<RiderTripAnalyticsNotifier, RiderTripAnalyticsState>(
  (ref) => RiderTripAnalyticsNotifier(),
);

class RiderTripAnalyticsNotifier extends StateNotifier<RiderTripAnalyticsState> {
  RiderTripAnalyticsNotifier() : super(const RiderTripAnalyticsState());

  Future<void> loadTripAnalytics({String period = 'week'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.dio.get('/v1/drivers/me/trips/analytics', queryParameters: {
        'period': period,
      });
      
      final data = response.data['data'] ?? response.data;

      final bestEarningDay = data['best_earning_day'] ?? '';
      final bestEarningDayAmount = (data['best_earning_day_amount'] as num?)?.toDouble() ?? 0.0;
      final peakHour = data['peak_hour'] ?? '';
      final avgEarningsPerTrip = (data['avg_earnings_per_trip'] as num?)?.toDouble() ?? 0.0;
      final totalDistanceTraveled = (data['total_distance_km'] as num?)?.toDouble() ?? 0.0;
      final totalTrips = data['total_trips'] as int? ?? 0;
      final totalEarnings = (data['total_earnings'] as num?)?.toDouble() ?? 0.0;

      // Parse hourly breakdown
      final hourlyList = (data['hourly_breakdown'] as List?)
          ?.whereType<Map>()
          .map((e) => HourlyBreakdown.fromJson(Map<String, dynamic>.from(e)))
          .toList() ?? [];

      // Parse daily breakdown
      final dailyList = (data['daily_breakdown'] as List?)
          ?.whereType<Map>()
          .map((e) => DailyBreakdown.fromJson(Map<String, dynamic>.from(e)))
          .toList() ?? [];

      state = state.copyWith(
        bestEarningDay: bestEarningDay,
        bestEarningDayAmount: bestEarningDayAmount,
        peakHour: peakHour,
        avgEarningsPerTrip: avgEarningsPerTrip,
        totalDistanceTraveled: totalDistanceTraveled,
        totalTrips: totalTrips,
        totalEarnings: totalEarnings,
        hourlyBreakdown: hourlyList,
        dailyBreakdown: dailyList,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('Failed to load trip analytics', e);
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
    this.bestEarningDay = 'Monday',
    this.bestEarningDayAmount = 0.0,
    this.peakHour = '18:00',
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
