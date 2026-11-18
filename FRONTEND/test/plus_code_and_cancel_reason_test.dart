import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/utils/address_text_utils.dart';
import 'package:lesgo/data/data_source/dto/order/orders_response_dto.dart';
import 'package:lesgo/data/data_source/order_remote_datasource.dart';
import 'package:lesgo/presentation/provider/main/booking/driver_finding_provider.dart';

class _Response implements OrderResponseDto {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Orders implements OrderRemoteDataSource {
  int? cancelledId;
  String? cancelReason;
  bool fail = false;

  @override
  Future<OrderResponseDto> cancelOrder(int orderId, String reason) async {
    if (fail) throw StateError('offline');
    cancelledId = orderId;
    cancelReason = reason;
    return _Response();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('stripPlusCode', () {
    test('drops a leading plus code and keeps the readable address', () {
      expect(stripPlusCode('J36M+FR5, Belado Avenue, Centro III'), 'Belado Avenue, Centro III');
      expect(stripPlusCode('J34M+W7J, Claveria, Cagayan'), 'Claveria, Cagayan');
    });

    test('handles short codes and extra spaces', () {
      expect(stripPlusCode('FRQ5+2P  ,  Claveria'), 'Claveria');
      expect(stripPlusCode('FRQ5+2P Claveria'), 'Claveria');
    });

    test('leaves normal addresses untouched', () {
      for (final a in [
        'Centro I, Claveria, Cagayan Valley',
        '12 Mabini St, Claveria',
        'Block 5+Lot 3, Subdivision', // "+" inside, not an Open Location Code
        'Mabini+Rizal Street',
      ]) {
        expect(stripPlusCode(a), a, reason: a);
      }
    });

    test('keeps the code when it is the only thing there is', () {
      expect(stripPlusCode('J36M+FR5'), 'J36M+FR5');
      expect(stripPlusCode('J36M+FR5,'), 'J36M+FR5,');
    });
  });

  group('driver finding cancel', () {
    late _Orders orders;

    setUp(() {
      orders = _Orders();
      getIt.registerSingleton<OrderRemoteDataSource>(orders);
    });

    tearDown(getIt.reset);

    test('sends the reason the customer picked', () async {
      final ok = await DriverFindingNotifier().cancelOrder('9', reason: 'Changed my mind');

      expect(ok, isTrue);
      expect(orders.cancelledId, 9);
      expect(orders.cancelReason, 'Changed my mind');
    });

    test('still defaults to a generic reason for callers that give none', () async {
      await DriverFindingNotifier().cancelOrder('9');

      expect(orders.cancelReason, 'Cancelled by customer');
    });

    test('reports failure without throwing', () async {
      orders.fail = true;
      final notifier = DriverFindingNotifier();

      expect(await notifier.cancelOrder('9', reason: 'x'), isFalse);
      expect(notifier.state.error, isNotNull);
    });
  });
}
