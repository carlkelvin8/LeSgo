import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';
import '../../auth/rider_auth_provider.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/rider_earnings_utils.dart';

final riderEarningsPeriodProvider = StateProvider<RiderEarningsPeriod>(
  (ref) => RiderEarningsPeriod.today,
);

final riderEarningsProvider = FutureProvider.autoDispose<RiderEarningsState>((
  ref,
) async {
  ref.watch(riderAuthProvider.select((auth) => auth.user?.id));
  final period = ref.watch(riderEarningsPeriodProvider);

  try {
    final data = await ApiService.getDriverEarnings(period: _periodKey(period));

    final summaryRaw = data['summary'] as Map<String, dynamic>? ?? {};
    final entriesRaw = data['entries'] as List<dynamic>? ?? [];

    final entries = entriesRaw.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return RiderEarningsEntry(
        orderId: (map['order_id'] as num?)?.toInt() ?? 0,
        serviceName: map['service_name']?.toString() ?? 'Order',
        earnings: (map['earnings'] as num?)?.toDouble() ?? 0,
        completedAt: map['completed_at'] != null
            ? DateTime.tryParse(map['completed_at'].toString())?.toLocal()
            : null,
      );
    }).toList();

    return RiderEarningsState(
      period: period,
      entries: entries,
      summary: RiderEarningsSummary(
        totalEarnings: (summaryRaw['total_earnings'] as num?)?.toDouble() ?? 0,
        completedTrips:
            (summaryRaw['completed_trips'] as num?)?.toInt() ?? entries.length,
        averagePerTrip:
            (summaryRaw['average_per_trip'] as num?)?.toDouble() ?? 0,
      ),
    );
  } catch (e) {
    AppLogger.error('Failed to load rider earnings', e);
    rethrow;
  }
});

class RiderEarningsState {
  final RiderEarningsPeriod period;
  final List<RiderEarningsEntry> entries;
  final RiderEarningsSummary summary;

  const RiderEarningsState({
    required this.period,
    required this.entries,
    required this.summary,
  });
}

String _periodKey(RiderEarningsPeriod period) {
  switch (period) {
    case RiderEarningsPeriod.today:
      return 'today';
    case RiderEarningsPeriod.week:
      return 'week';
    case RiderEarningsPeriod.month:
      return 'month';
    case RiderEarningsPeriod.all:
      return 'all';
  }
}
