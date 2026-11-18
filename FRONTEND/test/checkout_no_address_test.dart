import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/data/data_source/order_remote_datasource.dart';
import 'package:lesgo/data/data_source/partner_remote_datasource.dart';
import 'package:lesgo/data/data_source/voucher_remote_datasource.dart';
import 'package:lesgo/presentation/provider/main/booking/checkout_provider.dart';
import 'package:lesgo/presentation/provider/main/profile/profile_provider.dart';
import 'package:lesgo/presentation/widgets/booking/leseat/checkout/delivery_address_section.dart';
import 'package:lesgo/presentation/widgets/orders/cancel_order_dialog.dart';

class _Orders implements OrderRemoteDataSource {
  int estimateCalls = 0;
  @override
  Future<double?> getFareEstimateRaw({
    required int serviceId,
    required int estimatedDistanceM,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String? vehicleType,
  }) async {
    estimateCalls++;
    return 55;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Partners implements PartnerRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Vouchers implements VoucherRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profile extends ProfileNotifier {
  @override
  Future<void> loadProfile() async {}
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('DeliveryAddressSection', () {
    testWidgets('prompts to add an address instead of showing a made-up label',
        (tester) async {
      await tester.pumpWidget(_app(DeliveryAddressSection(address: '', onTap: () {})));

      expect(find.text('Add a delivery address'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('whitespace-only counts as missing', (tester) async {
      await tester.pumpWidget(_app(DeliveryAddressSection(address: '   ', onTap: () {})));

      expect(find.text('Add a delivery address'), findsOneWidget);
    });

    testWidgets('shows the saved address with an Edit action', (tester) async {
      await tester.pumpWidget(
        _app(DeliveryAddressSection(address: 'Centro I, Claveria', onTap: () {})),
      );

      expect(find.text('Centro I, Claveria'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Add a delivery address'), findsNothing);
    });
  });

  group('CancelOrderDialog', () {
    Future<void> open(WidgetTester tester, void Function(String?) onResult) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => onResult(
                  await showDialog<String>(
                    context: context,
                    builder: (_) => const CancelOrderDialog(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks for a reason inside the dialog when none is chosen',
        (tester) async {
      String? result = 'unset';
      await open(tester, (r) => result = r);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel Order'));
      await tester.pump();

      expect(find.byKey(const ValueKey('cancel-reason-error')), findsOneWidget);
      expect(find.text('Please select a reason for cancellation'), findsOneWidget);
      expect(result, 'unset', reason: 'dialog must stay open');
    });

    testWidgets('the "Other" error disappears as soon as the customer types',
        (tester) async {
      await open(tester, (_) {});

      await tester.tap(find.text('Other'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel Order'));
      await tester.pump();
      expect(find.text('Please specify your reason'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Delivery too slow');
      await tester.pump();
      expect(find.text('Please specify your reason'), findsNothing);
      expect(find.byKey(const ValueKey('cancel-reason-error')), findsNothing);
    });

    testWidgets('clears the error once a reason is picked and returns it',
        (tester) async {
      String? result = 'unset';
      await open(tester, (r) => result = r);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel Order'));
      await tester.pump();
      await tester.tap(find.text('Changed my mind'));
      await tester.pump();
      expect(find.byKey(const ValueKey('cancel-reason-error')), findsNothing);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel Order'));
      await tester.pumpAndSettle();
      expect(result, 'Changed my mind');
    });
  });

  group('CheckoutNotifier without a saved address', () {
    late _Orders orders;
    late ProviderContainer container;

    setUp(() {
      orders = _Orders();
      getIt.registerSingleton<OrderRemoteDataSource>(orders);
      getIt.registerSingleton<PartnerRemoteDataSource>(_Partners());
      getIt.registerSingleton<VoucherRemoteDataSource>(_Vouchers());
      container = ProviderContainer(
        overrides: [profileProvider.overrideWith((_) => _Profile())],
      );
    });

    tearDown(() {
      container.dispose();
      getIt.reset();
    });

    test('has no delivery label, no fee and an explicit missing-address error',
        () async {
      await container.read(checkoutProvider.notifier).initializeFromCart('Jollibee');
      final state = container.read(checkoutProvider);

      expect(state.order, isNotNull);
      expect(state.order!.deliveryAddress, isEmpty,
          reason: 'must not invent a "Brgy 6" fallback label');
      expect(state.hasValidDropoffLocation, isFalse);
      expect(state.hasValidDeliveryFee, isFalse);
      expect(state.fareError, kMissingDeliveryAddressMessage);
      expect(orders.estimateCalls, 0, reason: 'no fare request without coordinates');
    });

    test('keeps the same explicit error when the fee is retried', () async {
      final notifier = container.read(checkoutProvider.notifier);
      await notifier.initializeFromCart('Jollibee');
      await notifier.refreshDeliveryFee();

      expect(container.read(checkoutProvider).fareError, kMissingDeliveryAddressMessage);
      expect(orders.estimateCalls, 0);
    });
  });
}
