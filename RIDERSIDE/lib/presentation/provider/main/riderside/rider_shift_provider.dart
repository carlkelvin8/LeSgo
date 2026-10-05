import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_logger.dart';

class RiderShiftSummary {
  final int totalTrips;
  final double totalEarnings;
  final double totalDistanceKm;
  final Duration shiftDuration;
  final double averageEarningsPerTrip;
  final int cancelledTrips;

  const RiderShiftSummary({
    this.totalTrips = 0,
    this.totalEarnings = 0,
    this.totalDistanceKm = 0,
    this.shiftDuration = Duration.zero,
    this.averageEarningsPerTrip = 0,
    this.cancelledTrips = 0,
  });
}

final riderShiftProvider = Provider<RiderShiftNotifier>((_) {
  return RiderShiftNotifier();
});

class RiderShiftNotifier {
  static const _shiftStartKey = 'rider_shift_start';

  const RiderShiftNotifier();

  Future<void> recordShiftStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_shiftStartKey, DateTime.now().millisecondsSinceEpoch);
    AppLogger.debug('Shift start recorded');
  }

  Future<DateTime?> getShiftStart() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_shiftStartKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> clearShiftStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shiftStartKey);
  }

  Future<RiderShiftSummary> calculateSummary() async {
    final shiftStart = await getShiftStart();
    if (shiftStart == null) {
      return const RiderShiftSummary();
    }

    final shiftEnd = DateTime.now();
    final duration = shiftEnd.difference(shiftStart);

    try {
      final data = await ApiService.getDriverEarnings(period: 'today');
      final summaryRaw = data['summary'] as Map<String, dynamic>? ?? {};
      final entriesRaw = data['entries'] as List<dynamic>? ?? [];

      int trips = (summaryRaw['completed_trips'] as num?)?.toInt() ?? 0;
      double earnings = (summaryRaw['total_earnings'] as num?)?.toDouble() ?? 0;
      double avgPerTrip = (summaryRaw['average_per_trip'] as num?)?.toDouble() ?? 0;

      double totalKm = 0;
      int cancelled = 0;
      for (final item in entriesRaw) {
        final map = item as Map<String, dynamic>?;
        if (map != null) {
          totalKm += (map['distance_km'] as num?)?.toDouble() ?? 0;
        }
      }

      try {
        final ordersRaw = await ApiService.getOrders(perPage: 50);
        for (final item in ordersRaw) {
          final order = item as Map<String, dynamic>?;
          if (order != null && order['status'] == 'cancelled') {
            cancelled++;
          }
        }
      } catch (_) {}

      if (trips == 0 && entriesRaw.isNotEmpty) {
        trips = entriesRaw.length;
      }
      if (avgPerTrip == 0 && trips > 0) {
        avgPerTrip = earnings / trips;
      }

      return RiderShiftSummary(
        totalTrips: trips,
        totalEarnings: earnings,
        totalDistanceKm: totalKm,
        shiftDuration: duration,
        averageEarningsPerTrip: avgPerTrip,
        cancelledTrips: cancelled,
      );
    } catch (e) {
      AppLogger.error('Failed to calculate shift summary', e);
      return RiderShiftSummary(shiftDuration: duration);
    }
  }
}
