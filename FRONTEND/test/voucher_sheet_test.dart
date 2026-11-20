import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/utils/voucher_service_utils.dart';
import 'package:lesgo/data/data_source/dto/voucher/available_vouchers_response_dto.dart';
import 'package:lesgo/data/data_source/dto/voucher/voucher_dto.dart';
import 'package:lesgo/data/data_source/voucher_remote_datasource.dart';
import 'package:lesgo/presentation/widgets/booking/leseat/checkout/voucher_bottom_sheet.dart';

Map<String, dynamic> _voucher(
  String code, {
  Object? services = 'absent',
  String minOrder = '₱100',
  bool eligible = true,
  String? reason,
}) => {
  'code': code,
  'title': 'Title $code',
  'description': 'desc $code',
  'discount_text': 'x',
  'min_order': minOrder,
  'eligible': eligible,
  if (reason != null) 'reason': reason,
  if (services != 'absent') 'applicable_services': services,
};

class _Vouchers implements VoucherRemoteDataSource {
  _Vouchers(this.items);
  final List<Map<String, dynamic>> items;
  int? requestedService;

  @override
  Future<AvailableVouchersResponseDto> getAvailableVouchers({int? serviceId}) async {
    requestedService = serviceId;
    return AvailableVouchersResponseDto.fromJson({
      'success': true,
      'message': 'ok',
      'data': items,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('VoucherDto applicable_services', () {
    test('absent key stays unknown, null means every service, list is kept', () {
      expect(VoucherDto.fromJson(_voucher('A')).applicableServices, isNull);
      expect(VoucherDto.fromJson(_voucher('B', services: null)).applicableServices, isEmpty);
      expect(VoucherDto.fromJson(_voucher('C', services: [1, '2'])).applicableServices, [1, 2]);
    });

    test('reason is parsed', () {
      expect(VoucherDto.fromJson(_voucher('A', eligible: false, reason: 'Expired')).reason, 'Expired');
    });
  });

  group('isVoucherForService', () {
    test('uses the API service list when present', () {
      final freeDel = VoucherDto.fromJson(_voucher('FREEDEL', services: [1, 2]));
      expect(isVoucherForService(freeDel, BookingServiceIds.lesgo), isTrue);
      expect(isVoucherForService(freeDel, BookingServiceIds.leseat), isFalse);
    });

    test('an unrestricted voucher works for every service (no name guessing)', () {
      final save20 = VoucherDto.fromJson(_voucher('SAVE20', services: null));
      for (final id in [1, 2, 3, 4]) {
        expect(isVoucherForService(save20, id), isTrue, reason: 'service $id');
      }
    });

    test('older backends without the field still fall back to the name heuristic', () {
      final lunch = VoucherDto.fromJson(_voucher('LUNCHFREE'));
      expect(isVoucherForService(lunch, BookingServiceIds.leseat), isTrue);
      expect(isVoucherForService(lunch, BookingServiceIds.lesride), isFalse);
    });
  });

  group('showVoucherBottomSheet', () {
    late _Vouchers source;

    setUp(() {
      source = _Vouchers([
        _voucher('SAVE20', services: null, minOrder: '₱150', eligible: false, reason: 'Expired'),
        _voucher('FREEDEL', services: [1, 2], minOrder: '₱200'),
        _voucher('RIDE20', services: [2]),
        _voucher('LUNCHFREE', services: [3], minOrder: '₱150'),
        _voucher('PAYBACK', services: null, minOrder: '₱200'),
      ]);
      getIt.registerSingleton<VoucherRemoteDataSource>(source);
    });

    tearDown(getIt.reset);

    Future<String?> open(WidgetTester tester, {double? orderValue}) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? picked = 'unset';
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => picked = await showVoucherBottomSheet(
                  context,
                  serviceId: BookingServiceIds.leseat,
                  orderValue: orderValue,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return picked;
    }

    testWidgets('hides vouchers that do not apply to this service', (tester) async {
      await open(tester, orderValue: 233);

      expect(source.requestedService, BookingServiceIds.leseat);
      expect(find.text('LUNCHFREE'), findsOneWidget);
      expect(find.text('SAVE20'), findsOneWidget);
      expect(find.text('PAYBACK'), findsOneWidget);
      expect(find.text('FREEDEL'), findsNothing);
      expect(find.text('RIDE20'), findsNothing);
    });

    testWidgets('explains why a voucher cannot be used', (tester) async {
      await open(tester, orderValue: 178);

      expect(find.byKey(const ValueKey('voucher-hint-SAVE20')), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Add ₱22 more to use this voucher'), findsOneWidget);
      expect(find.byKey(const ValueKey('voucher-hint-LUNCHFREE')), findsNothing);
    });

    testWidgets('a voucher below its minimum cannot be picked, a valid one can',
        (tester) async {
      String? picked = 'unset';
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => picked = await showVoucherBottomSheet(
                  context,
                  serviceId: BookingServiceIds.leseat,
                  orderValue: 178,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('PAYBACK'));
      await tester.pumpAndSettle();
      expect(picked, 'unset', reason: 'PAYBACK needs 200, order is 178: sheet stays open');

      await tester.tap(find.text('LUNCHFREE'));
      await tester.pumpAndSettle();
      expect(picked, 'LUNCHFREE');
    });
  });
}
