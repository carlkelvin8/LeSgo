import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/utils/lesgo_status_text.dart';
import 'package:lesgo/data/data_source/dto/order/order_dto.dart';
import 'package:lesgo/data/data_source/dto/order/orders_response_dto.dart';
import 'package:lesgo/data/data_source/order_remote_datasource.dart';
import 'package:lesgo/presentation/provider/main/booking/driver_finding_provider.dart';
import 'package:lesgo/presentation/provider/main/booking/lesgo_location_provider.dart';
import 'package:lesgo/presentation/provider/main/booking/lesgo_provider.dart';

OrderResponseDto _order(String status, {int? driverId}) {
  return OrderResponseDto(
    success: true,
    data: OrderDto.fromJson({
      'id': 1,
      'customer_id': 1,
      'service_id': 1,
      'pickup_address': 'a',
      'pickup_lat': 18.6,
      'pickup_lng': 121.0,
      'pickup_contact_name': 'n',
      'pickup_contact_phone': 'p',
      'dropoff_address': 'b',
      'dropoff_lat': 18.6,
      'dropoff_lng': 121.0,
      'dropoff_contact_name': 'n',
      'dropoff_contact_phone': 'p',
      'discount_amount': 0,
      'status': status,
      'estimated_distance_m': 1000,
      'estimated_fare': 50,
      'payment_method': 'cash',
      'payment_status': 'pending',
      'driver_id': driverId,
      'created_at': '2026-01-01T00:00:00Z',
    }),
  );
}

class _FakeOrders implements OrderRemoteDataSource {
  _FakeOrders(this.next);
  OrderResponseDto Function() next;
  int getCalls = 0;

  @override
  Future<OrderResponseDto> getOrder(int id) async {
    getCalls++;
    return next();
  }

  @override
  Future<OrderResponseDto> cancelOrder(int orderId, String reason) async =>
      _order('cancelled');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('LesgoLocationState.copyWith clearDistance', () {
    test('clears distance and duration, plain null does not', () {
      final s = LesgoLocationState(distanceInKm: 3.2, durationInSeconds: 600);
      expect(s.copyWith(distanceInKm: null).distanceInKm, 3.2);
      final cleared = s.copyWith(clearDistance: true);
      expect(cleared.distanceInKm, isNull);
      expect(cleared.durationInSeconds, isNull);
    });
  });

  group('LesgoBookingRules', () {
    test('weight parsing and validation', () {
      expect(LesgoBookingRules.parseWeightKg('5 kg'), 5);
      expect(LesgoBookingRules.parseWeightKg('2.5'), 2.5);
      expect(LesgoBookingRules.parseWeightKg('0'), isNull);
      expect(LesgoBookingRules.parseWeightKg('101'), isNull);
      expect(LesgoBookingRules.parseWeightKg('abc'), isNull);
      expect(LesgoBookingRules.parseWeightKg('-3'), isNull);
      expect(LesgoBookingRules.isWeightValid(''), isTrue);
      expect(LesgoBookingRules.isWeightValid('100'), isTrue);
      expect(LesgoBookingRules.isWeightValid('150'), isFalse);
    });

    test('notes combine and cap at 500', () {
      expect(LesgoBookingRules.buildNotes('', ' '), isNull);
      expect(LesgoBookingRules.buildNotes('gate', 'ring'),
          'Pickup: gate\nDropoff: ring');
      expect(LesgoBookingRules.buildNotes('x' * 600, '')!.length, 500);
    });
  });

  group('LesgoStatusText', () {
    test('uses real server statuses', () {
      expect(LesgoStatusText.title('driver_arrived_at_pickup'), 'Driver Arrived');
      expect(LesgoStatusText.title('in_progress'), 'On The Way');
      expect(LesgoStatusText.title('weird_new_status'), 'Weird New Status');
      expect(LesgoStatusText.title(null), 'Updating');
    });
  });

  group('DriverFindingRules', () {
    test('found for any active status with a driver', () {
      expect(DriverFindingRules.isDriverFound('pending', 3), isFalse);
      expect(DriverFindingRules.isDriverFound('accepted', null), isFalse);
      for (final s in [
        'accepted',
        'driver_arrived_at_pickup',
        'in_progress',
        'picked_up',
      ]) {
        expect(DriverFindingRules.isDriverFound(s, 3), isTrue, reason: s);
      }
      expect(DriverFindingRules.isDriverFound('cancelled', 3), isFalse);
      expect(DriverFindingRules.isCancelled('cancelled'), isTrue);
    });
  });

  group('DriverFindingNotifier', () {
    test('cancelOrder stops the poll loop', () async {
      final fake = _FakeOrders(() => _order('pending'));
      final n = DriverFindingNotifier(
        orderDataSource: fake,
        pollInterval: const Duration(milliseconds: 10),
      );
      final run = n.startFindingDriver('1', 'LesGo');
      await Future<void>.delayed(const Duration(milliseconds: 35));
      expect(await n.cancelOrder('1'), isTrue);
      final callsAtCancel = fake.getCalls;
      await run;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(fake.getCalls, callsAtCancel);
      expect(n.state.isSearching, isFalse);
      expect(n.state.error, isNull);
    });

    test('in_progress order with driver is found and state resets per start',
        () async {
      final fake = _FakeOrders(() => _order('in_progress', driverId: 7));
      final n = DriverFindingNotifier(
        orderDataSource: fake,
        pollInterval: const Duration(milliseconds: 5),
      );
      await n.startFindingDriver('1', 'LesGo');
      expect(n.state.driverFound, isTrue);
      expect(n.state.driverId, '7');

      fake.next = () => _order('cancelled');
      await n.startFindingDriver('2', 'LesGo');
      expect(n.state.driverFound, isFalse);
      expect(n.state.driverId, isNull);
      expect(n.state.error, 'Order was cancelled.');
    });
  });
}
