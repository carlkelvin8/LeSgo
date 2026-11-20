import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_earnings_insights_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_mission_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_payout_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_performance_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_rating_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_trip_analytics_provider.dart';
import 'package:lezgo_rider/core/utils/rider_earnings_utils.dart';

void main() {
  group('rating distribution parsing', () {
    test('accepts object, list, string counts and empty []', () {
      expect(parseRatingDistribution({'1': 0, '2': '1', '3': 2, '4': 3, '5': 4}),
          {1: 0, 2: 1, 3: 2, 4: 3, 5: 4});
      expect(parseRatingDistribution([1, 2, 3, 4, 5]),
          {1: 1, 2: 2, 3: 3, 4: 4, 5: 5});
      expect(parseRatingDistribution([]).values.every((v) => v == 0), isTrue);
      expect(parseRatingDistribution(null).length, 5);
    });
  });

  group('RiderMission.fromJson', () {
    test('tolerates string numbers, int booleans and zero goal', () {
      final m = RiderMission.fromJson({
        'id': '7',
        'title': 'Ride 5',
        'current_progress': '3',
        'goal_target': 0,
        'progress': '60.5',
        'reward_amount': '20',
        'is_completed': 1,
        'reward_claimed': '0',
      });
      expect(m.id, 7);
      expect(m.currentProgress, 3);
      expect(m.goalTarget, 1);
      expect(m.progress, 60.5);
      expect(m.rewardAmount, 20);
      expect(m.isCompleted, isTrue);
      expect(m.rewardClaimed, isFalse);
    });
  });

  group('performance response (real route /analytics/drivers/performance)', () {
    test('reads the own-driver row from a list', () {
      final s = parsePerformanceResponse({
        'success': true,
        'data': [
          {
            'rating': '4.8',
            'total_orders': 10,
            'completed_orders': 8,
            'completion_rate': 80,
          }
        ],
      }, const RiderPerformanceState());
      expect(s.customerRating, 4.8);
      expect(s.completionRate, 80);
      expect(s.acceptedOrders, 10);
      expect(s.cancellations, 2);
    });

    test('empty [] data leaves defaults instead of throwing', () {
      final s = parsePerformanceResponse(
          {'success': true, 'data': []}, const RiderPerformanceState());
      expect(s.completionRate, 0);
    });
  });

  group('trip analytics from earnings payload', () {
    test('computes totals, best day and peak hour', () {
      final s = buildTripAnalyticsState({
        'summary': {
          'total_earnings': 300,
          'completed_trips': 3,
          'average_per_trip': 100,
        },
        'entries': [
          {'earnings': 50, 'completed_at': '2026-11-02T10:00:00'},
          {'earnings': 50, 'completed_at': '2026-11-02T18:30:00'},
          {'earnings': '200', 'completed_at': '2026-11-03T18:10:00'},
        ],
      }, 'week');
      expect(s.totalTrips, 3);
      expect(s.totalEarnings, 300);
      expect(s.avgEarningsPerTrip, 100);
      expect(s.peakHour, '6 PM');
      expect(s.bestEarningDayAmount, 200);
      expect(s.dailyBreakdown.length, 2);
    });

    test('empty [] entries/summary do not throw', () {
      final s = buildTripAnalyticsState({'summary': [], 'entries': []}, 'week');
      expect(s.totalTrips, 0);
      expect(s.peakHourDisplay, '—');
    });
  });

  test('peakHourLabel picks highest earning hour', () {
    final at = DateTime(2026, 11, 2, 0, 15);
    expect(
      peakHourLabel([
        RiderEarningsEntry(
            orderId: 1, serviceName: 'x', earnings: 10, completedAt: at),
      ]),
      '12 AM',
    );
    expect(peakHourLabel(const []), isNull);
  });

  group('PayoutRecord.fromJson', () {
    test('parses string amounts and missing account', () {
      final p = PayoutRecord.fromJson({
        'id': 1,
        'amount': '150.50',
        'status': 'pending',
        'payment_method': 'gcash',
        'account_number': '',
        'requested_at': '2026-11-02T10:00:00Z',
      });
      expect(p.amount, 150.5);
      expect(p.isPending, isTrue);
    });
  });
}
