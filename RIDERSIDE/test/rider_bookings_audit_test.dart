import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lezgo_rider/core/di/injection.dart';
import 'package:lezgo_rider/core/network/dio_client.dart';
import 'package:lezgo_rider/presentation/provider/auth/rider_auth_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_history_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_orders_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_wallet_provider.dart';
import 'package:lezgo_rider/presentation/widgets/main/riderside/bookings/rider_booking_detail_info.dart';
import 'package:lezgo_rider/presentation/widgets/main/riderside/bookings/rider_bookings_list.dart';
import 'package:lezgo_rider/presentation/widgets/main/riderside/bookings/rider_cancel_order_dialog.dart';
import 'package:lezgo_rider/presentation/widgets/main/riderside/bookings/rider_swipe_accept_button.dart';

class _Client implements DioClient {
  @override
  final Dio dio;
  _Client(this.dio);
  @override
  void initialize() {}
}

class _Auth extends RiderAuthNotifier {
  _Auth() {
    state = RiderAuthState(
      isLoggedIn: true,
      user: RiderUser(
        id: 7,
        name: 'Rider',
        email: 'rider@example.test',
        role: 'driver',
        driverProfileId: 10,
      ),
    );
  }
}

class _Orders extends StateNotifier<RiderOrdersState>
    implements RiderOrdersNotifier {
  _Orders(super.state);
  @override
  Future<void> loadOrders({bool silent = false}) async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Wallet extends StateNotifier<RiderWalletState>
    implements RiderWalletNotifier {
  _Wallet() : super(const RiderWalletState(balance: 500));
  @override
  Future<void> loadWallet({bool silent = false}) async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Map<String, dynamic> _order(int id, {String status = 'pending'}) => {
      'id': id,
      'service_id': 3,
      'status': status,
      'driver_id': status == 'pending' ? null : 10,
      'pickup_address': 'Store St',
      'dropoff_address': 'Home Ave',
      'estimated_fare': '50.00',
      'proof_images': [],
      'meta': [], // PHP encodes an empty array as []
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RiderSwipeAcceptButton', () {
    testWidgets('resets after a failed async accept so the rider can retry', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RiderSwipeAcceptButton(
              onAccepted: () async {
                taps++;
                throw Exception('Order already accepted by another driver.');
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Accept booking'));
      await tester.pumpAndSettle();

      expect(taps, 1);
      // Still offers the swipe label and the manual button again.
      expect(find.text('Swipe to get booking'), findsOneWidget);
      expect(find.text('Accept booking'), findsOneWidget);
      expect(find.text('Accepted'), findsNothing);

      await tester.tap(find.text('Accept booking'));
      await tester.pumpAndSettle();
      expect(taps, 2);
    });
  });

  group('RiderBookingsList', () {
    testWidgets('keeps showing bookings when an accept error is set', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final orders = _Orders(
        RiderOrdersState(
          availableOrders: [RiderOrder.fromJson(_order(5))],
          error: 'Order already accepted by another driver.',
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            riderAuthProvider.overrideWith((ref) => _Auth()),
            riderOrdersProvider.overrideWith((ref) => orders),
            riderWalletProvider.overrideWith((ref) => _Wallet()),
          ],
          child: const MaterialApp(home: Scaffold(body: RiderBookingsList())),
        ),
      );
      await tester.pump();

      expect(find.byType(RiderSwipeAcceptButton), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('shows the cached active order when a refresh failed', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final active = RiderOrder.fromJson(_order(9, status: 'accepted'));
      final orders = _Orders(
        RiderOrdersState(
          activeOrder: active,
          activeOrders: [active],
          error: 'No connection (showing cached active order)',
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            riderAuthProvider.overrideWith((ref) => _Auth()),
            riderOrdersProvider.overrideWith((ref) => orders),
            riderWalletProvider.overrideWith((ref) => _Wallet()),
          ],
          child: const MaterialApp(home: Scaffold(body: RiderBookingsList())),
        ),
      );
      await tester.pump();

      expect(find.text('Order #9'), findsOneWidget);
    });

    testWidgets('still shows the error panel when there is nothing to show', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final orders = _Orders(RiderOrdersState(error: 'Server unreachable'));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            riderAuthProvider.overrideWith((ref) => _Auth()),
            riderOrdersProvider.overrideWith((ref) => orders),
            riderWalletProvider.overrideWith((ref) => _Wallet()),
          ],
          child: const MaterialApp(home: Scaffold(body: RiderBookingsList())),
        ),
      );
      await tester.pump();

      expect(find.text('Server unreachable'), findsOneWidget);
    });
  });

  group('cancel order dialog', () {
    testWidgets('limits the reason to what the API accepts', (tester) async {
      SharedPreferences.setMockInitialValues({});
      String? result;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async =>
                      result = await showRiderCancelOrderDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'x' * 400);
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text.length, kRiderCancelReasonMaxLength);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(result!.length, 255);
    });
  });

  group('riderPhoneUri', () {
    test('keeps digits and a leading plus only', () {
      expect(riderPhoneUri('0912 345 6789').toString(), 'tel:09123456789');
      expect(riderPhoneUri('+63 912-345-6789').toString(), 'tel:+639123456789');
      expect(riderPhoneUri('(+63) 912 345 6789').toString(), 'tel:+639123456789');
    });
  });

  group('RiderHistoryNotifier', () {
    late Dio dio;
    late bool failOrders;
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      failOrders = true;
      dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, handler) {
            if (o.path.endsWith('/v1/orders') && !failOrders) {
              handler.resolve(
                Response(
                  requestOptions: o,
                  statusCode: 200,
                  data: {
                    'data': [_order(1, status: 'completed')],
                    'meta': {'last_page': 1},
                  },
                ),
              );
              return;
            }
            handler.reject(
              DioException(
                requestOptions: o,
                type: DioExceptionType.connectionError,
                error: 'offline',
              ),
            );
          },
        ),
      );
      getIt.registerSingleton<DioClient>(_Client(dio));
      container = ProviderContainer(
        overrides: [riderAuthProvider.overrideWith((ref) => _Auth())],
      );
    });

    tearDown(() async {
      container.dispose();
      await getIt.reset();
    });

    test('a later successful refresh clears an earlier load error', () async {
      final notifier = container.read(riderHistoryProvider.notifier);
      await notifier.loadHistory();
      expect(container.read(riderHistoryProvider).error, isNotNull);

      failOrders = false;
      await notifier.loadHistory(silent: true);
      final state = container.read(riderHistoryProvider);
      expect(state.error, isNull);
      expect(state.allBookings, hasLength(1));
    });

    test('a failed background refresh keeps the history already loaded', () async {
      failOrders = false;
      final notifier = container.read(riderHistoryProvider.notifier);
      await notifier.loadHistory();
      expect(container.read(riderHistoryProvider).allBookings, hasLength(1));

      failOrders = true;
      await notifier.loadHistory(silent: true);
      final state = container.read(riderHistoryProvider);
      expect(state.error, isNull);
      expect(state.allBookings, hasLength(1));
    });
  });
}
