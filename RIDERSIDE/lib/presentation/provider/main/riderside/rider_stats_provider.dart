import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_logger.dart';

/// Quick stats dashboard data
final riderStatsProvider = FutureProvider.autoDispose<RiderStatsState>((ref) async {
  try {
    // Fetch today's earnings
    final todayEarnings = await ApiService.getDriverEarnings(period: 'today');
    final todayTotal = (todayEarnings['summary']?['total_earnings'] as num?)?.toDouble() ?? 0.0;
    final todayTrips = (todayEarnings['summary']?['completed_trips'] as num?)?.toInt() ?? 0;

    // Fetch weekly trend
    final weekEarnings = await ApiService.getDriverEarnings(period: 'week');
    final weekEntries = (weekEarnings['entries'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // Group by day for trend
    final dailyTotals = <int, double>{};
    for (final entry in weekEntries) {
      final completedAt = entry['completed_at']?.toString();
      if (completedAt != null) {
        try {
          final date = DateTime.parse(completedAt).toLocal();
          final dayOfWeek = date.weekday;
          dailyTotals[dayOfWeek] = (dailyTotals[dayOfWeek] ?? 0.0) + 
              ((entry['earnings'] as num?)?.toDouble() ?? 0.0);
        } catch (_) {}
      }
    }

    // Calculate online hours (this would need additional tracking)
    // For now, estimate based on completed trips
    final onlineHours = _estimateOnlineHours(todayTrips);

    // Weekly total
    final weekTotal = weekEntries.fold<double>(
      0.0,
      (sum, entry) => sum + ((entry['earnings'] as num?)?.toDouble() ?? 0.0),
    );

    return RiderStatsState(
      todayEarnings: todayTotal,
      todayTrips: todayTrips,
      onlineHours: onlineHours,
      weeklyEarnings: weekTotal,
      dailyTrendData: dailyTotals,
      isLoaded: true,
    );
  } catch (e) {
    AppLogger.error('Failed to load rider stats', e);
    return RiderStatsState(
      todayEarnings: 0,
      todayTrips: 0,
      onlineHours: 0,
      weeklyEarnings: 0,
      dailyTrendData: {},
      isLoaded: false,
      error: e.toString(),
    );
  }
});

/// Estimate online hours based on completed trips
/// Rough estimate: 20-30 minutes per trip
double _estimateOnlineHours(int completedTrips) {
  const minutesPerTrip = 25.0;
  return (completedTrips * minutesPerTrip) / 60;
}

class RiderStatsState {
  final double todayEarnings;
  final int todayTrips;
  final double onlineHours;
  final double weeklyEarnings;
  final Map<int, double> dailyTrendData;
  final bool isLoaded;
  final String? error;

  const RiderStatsState({
    required this.todayEarnings,
    required this.todayTrips,
    required this.onlineHours,
    required this.weeklyEarnings,
    required this.dailyTrendData,
    required this.isLoaded,
    this.error,
  });

  String get todayEarningsFormatted => 'PHP ${todayEarnings.toStringAsFixed(2)}';
  String get weeklyEarningsFormatted => 'PHP ${weeklyEarnings.toStringAsFixed(2)}';
  String get onlineHoursFormatted => '${onlineHours.toStringAsFixed(1)} hrs';

  /// Get percentage change from previous day (if available)
  double? get dailyTrendPercent {
    if (dailyTrendData.isEmpty) return null;
    final today = DateTime.now().weekday;
    final yesterday = today == 1 ? 7 : today - 1;
    
    final todayVal = dailyTrendData[today] ?? 0.0;
    final yesterdayVal = dailyTrendData[yesterday] ?? 0.0;
    
    if (yesterdayVal == 0) return null;
    return ((todayVal - yesterdayVal) / yesterdayVal) * 100;
  }

  String get trendStatus {
    final percent = dailyTrendPercent;
    if (percent == null || percent.isNaN) return '—';
    if (percent > 0) return '+${percent.toStringAsFixed(1)}%';
    return '${percent.toStringAsFixed(1)}%';
  }
}
