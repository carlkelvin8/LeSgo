import '../../domain/models/rider_order.dart';
import 'rider_commission_utils.dart';

enum RiderEarningsPeriod { today, week, month, all }

class RiderEarningsSummary {
  final double totalEarnings;
  final int completedTrips;
  final double averagePerTrip;

  const RiderEarningsSummary({
    required this.totalEarnings,
    required this.completedTrips,
    required this.averagePerTrip,
  });
}

class RiderEarningsEntry {
  final int orderId;
  final String serviceName;
  final double earnings;
  final DateTime? completedAt;

  const RiderEarningsEntry({
    required this.orderId,
    required this.serviceName,
    required this.earnings,
    this.completedAt,
  });
}

class RiderEarningsUtils {
  RiderEarningsUtils._();

  static DateTime? parseOrderDate(Map<String, dynamic> order) {
    for (final key in ['completed_at', 'updated_at', 'created_at']) {
      final raw = order[key];
      if (raw is String && raw.isNotEmpty) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return parsed.toLocal();
      }
    }
    return null;
  }

  static bool isInPeriod(DateTime date, RiderEarningsPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case RiderEarningsPeriod.today:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case RiderEarningsPeriod.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final weekStart = DateTime(start.year, start.month, start.day);
        return !date.isBefore(weekStart);
      case RiderEarningsPeriod.month:
        return date.year == now.year && date.month == now.month;
      case RiderEarningsPeriod.all:
        return true;
    }
  }

  static double earningsForOrder(
    Map<String, dynamic> order, {
    String? packageTier,
    double? commissionRate,
  }) {
    final riderOrder = RiderOrder.fromJson(order);
    if (commissionRate != null && commissionRate > 0) {
      return riderOrder.displayShippingFee * commissionRate;
    }
    return riderOrder.estimatedEarningsFor(packageTier);
  }

  static RiderEarningsSummary summarize(
    List<RiderEarningsEntry> entries,
  ) {
    if (entries.isEmpty) {
      return const RiderEarningsSummary(
        totalEarnings: 0,
        completedTrips: 0,
        averagePerTrip: 0,
      );
    }
    final total = entries.fold<double>(0, (sum, e) => sum + e.earnings);
    return RiderEarningsSummary(
      totalEarnings: total,
      completedTrips: entries.length,
      averagePerTrip: total / entries.length,
    );
  }

  static String periodLabel(RiderEarningsPeriod period) {
    switch (period) {
      case RiderEarningsPeriod.today:
        return 'Today';
      case RiderEarningsPeriod.week:
        return 'This Week';
      case RiderEarningsPeriod.month:
        return 'This Month';
      case RiderEarningsPeriod.all:
        return 'All Time';
    }
  }
}
