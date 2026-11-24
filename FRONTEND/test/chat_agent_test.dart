import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/services/chat_agent.dart';
import 'package:lesgo/core/services/gemini_customer_service.dart';
import 'package:lesgo/data/data_source/dto/order/order_dto.dart';
import 'package:lesgo/data/data_source/dto/order/orders_response_dto.dart';
import 'package:lesgo/data/data_source/dto/wallet/wallet_dto.dart';
import 'package:lesgo/data/data_source/order_remote_datasource.dart';
import 'package:lesgo/data/data_source/wallet_remote_datasource.dart';
import 'package:lesgo/domain/entities/support/ibow_expression.dart';
import 'package:lesgo/presentation/provider/main/support/customer_service_chat_provider.dart';
import 'package:lesgo/presentation/screens/main/support/customer_service_chat_screen.dart';
import 'package:lesgo/presentation/widgets/support/ibow_orbit_avatar.dart';

OrderDto _order(int id, String status, {int service = 3, double fare = 100}) =>
    OrderDto.fromJson({
      'id': id,
      'customer_id': 1,
      'service_id': service,
      'pickup_address': 'Somewhere, Claveria',
      'pickup_lat': 18.6,
      'pickup_lng': 121.0,
      'pickup_contact_name': 'a',
      'pickup_contact_phone': '09171234567',
      'dropoff_address': 'Elsewhere, Claveria',
      'dropoff_lat': 18.61,
      'dropoff_lng': 121.01,
      'dropoff_contact_name': 'b',
      'dropoff_contact_phone': '09179999999',
      'discount_amount': 0,
      'status': status,
      'estimated_distance_m': 1000,
      'estimated_fare': fare,
      'payment_method': 'cash',
      'payment_status': 'paid',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'lesbuy_items': [
        {
          'id': 1,
          'order_id': id,
          'menu_item_id': 2,
          'name': '1-pc Chickenjoy',
          'quantity': 2,
          'estimated_price': '89.00',
        },
      ],
    });

class _Orders implements OrderRemoteDataSource {
  _Orders(this.orders);
  final List<OrderDto> orders;
  final cancelled = <int>[];
  final reordered = <int>[];
  bool failCancel = false;

  @override
  Future<OrdersResponseDto> getOrders({
    String? status,
    String? paymentStatus,
    int? serviceId,
    int perPage = 20,
    int page = 1,
  }) async => OrdersResponseDto(success: true, data: orders);

  @override
  Future<OrderResponseDto> cancelOrder(int orderId, String reason) async {
    if (failCancel) throw Exception('server said no');
    cancelled.add(orderId);
    return OrderResponseDto(success: true, data: orders.first);
  }

  @override
  Future<OrderResponseDto> reorderOrder(int orderId) async {
    reordered.add(orderId);
    return OrderResponseDto(success: true, data: orders.first);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Wallet implements WalletRemoteDataSource {
  @override
  Future<WalletDto> getMyWallet() async => WalletDto(
    id: 1,
    userId: 1,
    balance: 5000,
    currency: 'PHP',
    createdAt: '2026-01-01T00:00:00Z',
    updatedAt: '2026-01-01T00:00:00Z',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ChatAgent _agent(List<OrderDto> orders, [_Orders? ds]) =>
    ChatAgent(ChatAgentTools(orders: ds ?? _Orders(orders), wallet: _Wallet()));

void main() {
  group('ChatAgent (no cloud model needed)', () {
    test(
      'reports real order status and never shows ids or contact details',
      () async {
        final reply = await _agent([
          _order(5309, 'in_transit', service: 1),
        ]).handle('Where is my order?');
        expect(reply, isNotNull);
        expect(reply!.text, contains('LesGo'));
        expect(reply.text.toLowerCase(), contains('on the way'));
        expect(reply.text, isNot(contains('5309')));
        expect(reply.text, isNot(contains('0917')));
        expect(reply.mood, IbowExpression.happy);
      },
    );

    test('with nothing active it says so instead of inventing one', () async {
      final reply = await _agent([
        _order(1, 'completed'),
      ]).handle('track my order');
      expect(reply!.text, contains("don't have any active orders"));
    });

    test(
      'cancel only offers a button; nothing is cancelled until it is tapped',
      () async {
        final ds = _Orders([_order(77, 'pending')]);
        final reply = await _agent([], ds).handle('please cancel my order');

        expect(reply!.actions, hasLength(1));
        expect(reply.actions.single.kind, AgentActionKind.cancelOrder);
        expect(reply.actions.single.label, 'Yes, cancel it');
        expect(reply.actions.single.detail, contains('₱'));
        expect(reply.actions.single.detail, isNot(contains('77')));
        expect(
          ds.cancelled,
          isEmpty,
          reason: 'asking must not cancel anything',
        );

        final done = await reply.actions.single.execute();
        expect(ds.cancelled, [77]);
        expect(done, contains('cancelled'));
      },
    );

    test('cannot cancel what is already finished', () async {
      final reply = await _agent([
        _order(1, 'completed'),
        _order(2, 'cancelled'),
      ]).handle('cancel');
      expect(reply!.actions, isEmpty);
      expect(reply.mood, IbowExpression.sad);
    });

    test('order again proposes the latest completed order', () async {
      final ds = _Orders([_order(9, 'in_transit'), _order(8, 'completed')]);
      final reply = await _agent([], ds).handle('order again');
      expect(reply!.actions.single.kind, AgentActionKind.reorder);
      expect(ds.reordered, isEmpty);
      await reply.actions.single.execute();
      expect(ds.reordered, [8]);
    });

    test('a named service reorders only its own completed order', () async {
      final orders = [
        _order(9, 'completed', service: 3),
        _order(8, 'completed', service: 5),
      ];
      final ds = _Orders(orders);
      final agent = _agent(orders, ds);
      final reply = await agent.handle('Reorder LesTransport');

      expect(ds.reordered, isEmpty);
      expect(reply!.actions.single.detail, contains('LesTransport'));
      await reply.actions.single.execute();
      expect(ds.reordered, [8]);

      final missing = await agent.handle('Reorder LesRide');
      expect(missing!.actions, isEmpty);
      expect(missing.links.single.label, 'Open LesRide');
    });

    test('wallet balance comes from the account', () async {
      final reply = await _agent([]).handle('what is my lespay balance?');
      expect(reply!.text, contains('₱5,000.00'));
      expect(reply.links.single.label, 'Open LesPay');
    });

    test('booking requests become buttons to the right screens', () async {
      final reply = await _agent([]).handle('I want to book a ride');
      expect(reply!.links.map((l) => l.label), ['Open LesRide']);
    });

    test('new orders can start checkout for every booking service', () async {
      final agent = _agent([]);
      final all = await agent.handle('Place an order');
      expect(all!.links.map((link) => link.label), [
        'Open LesRide',
        'Open LesGo',
        'Open LesEat',
        'Open LesBuy',
        'Open LesTransport',
      ]);
      expect(all.actions, isEmpty);

      for (final service in [
        'LesRide',
        'LesGo',
        'LesEat',
        'LesBuy',
        'LesTransport',
      ]) {
        final reply = await agent.handle('Place an order with $service');
        expect(reply!.links.single.label, 'Open $service');
      }
      final cargo = await agent.handle('Book a cargo delivery');
      expect(cargo!.links.single.label, 'Open LesTransport');
    });

    test('unrelated questions fall through to the normal answers', () async {
      expect(await _agent([]).handle('how are you'), isNull);
    });

    test('a server failure is reported kindly', () async {
      final ds = _Orders([_order(1, 'pending')])..failCancel = true;
      final reply = await _agent([], ds).handle('cancel');
      await expectLater(reply!.actions.single.execute(), throwsException);
    });
  });

  group('chat provider actions', () {
    CustomerServiceChatNotifier make(_Orders ds) => CustomerServiceChatNotifier(
      GeminiCustomerService(agent: _agent([], ds)),
    );

    test('confirming runs the action and IBOW celebrates', () async {
      final ds = _Orders([_order(31, 'pending')]);
      final n = make(ds);
      await n.sendMessage('cancel my order');
      final msg = n.state.messages.last;
      expect(msg.actions, hasLength(1));
      expect(msg.mood, IbowExpression.surprised);

      await n.runAction(msg.id, msg.actions.single);
      expect(ds.cancelled, [31]);
      expect(
        n.state.statusOf(msg.id, msg.actions.single.id),
        AgentActionStatus.done,
      );
      expect(n.state.messages.last.mood, IbowExpression.love);
      n.dispose();
    });

    test('"Not now" leaves the order alone', () async {
      final ds = _Orders([_order(32, 'pending')]);
      final n = make(ds);
      await n.sendMessage('cancel my order');
      final msg = n.state.messages.last;
      n.dismissActions(msg.id);
      expect(ds.cancelled, isEmpty);
      expect(
        n.state.statusOf(msg.id, msg.actions.single.id),
        AgentActionStatus.dismissed,
      );
      n.dispose();
    });

    test('a failed action returns to ready and IBOW looks sad', () async {
      final ds = _Orders([_order(33, 'pending')])..failCancel = true;
      final n = make(ds);
      await n.sendMessage('cancel my order');
      final msg = n.state.messages.last;
      await n.runAction(msg.id, msg.actions.single);
      expect(
        n.state.statusOf(msg.id, msg.actions.single.id),
        AgentActionStatus.ready,
      );
      expect(n.state.messages.last.mood, IbowExpression.sad);
      n.dispose();
    });
  });

  group('expressions', () {
    test('mood tags are parsed and stripped', () {
      final r = splitMoodTag('[mood:happy] Your food is on the way!');
      expect(r.mood, IbowExpression.happy);
      expect(r.text, 'Your food is on the way!');
      expect(splitMoodTag('No tag here').mood, isNull);
      expect(splitMoodTag('[mood:nonsense] hi').mood, isNull);
    });

    test('a face is guessed from the words when there is no tag', () {
      expect(guessExpression("Sorry, I couldn't do that"), IbowExpression.sad);
      expect(
        guessExpression('All set, your order is placed'),
        IbowExpression.happy,
      );
      expect(
        guessExpression('The fare depends on distance'),
        IbowExpression.neutral,
      );
    });

    testWidgets('every face draws and animates without errors', (tester) async {
      for (final e in IbowExpression.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(child: IbowOrbitAvatar(size: 160, expression: e)),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 1400));
      }
      // Switching expressions plays the reaction.
      await tester.pumpWidget(
        const MaterialApp(home: Center(child: IbowOrbitAvatar(size: 160))),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: IbowOrbitAvatar(size: 160, expression: IbowExpression.love),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: IbowOrbitAvatar(size: 160, expression: IbowExpression.sad),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull);
    });
  });

  group('chat screen', () {
    Future<_Orders> openChat(WidgetTester tester, List<OrderDto> orders) async {
      // The test font is much wider than the app font; give the app bar room.
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ds = _Orders(orders);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerServiceChatProvider.overrideWith(
              (ref) => CustomerServiceChatNotifier(
                GeminiCustomerService(agent: _agent([], ds)),
              ),
            ),
          ],
          child: const MaterialApp(home: CustomerServiceChatScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      return ds;
    }

    testWidgets(
      'tapping a suggestion shows a confirm card; "Not now" dismisses it',
      (tester) async {
        final ds = await openChat(tester, [_order(41, 'pending')]);

        await tester.tap(find.text('Cancel my order'));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('Yes, cancel it'), findsOneWidget);
        expect(find.textContaining('Cancel your LesEat order'), findsOneWidget);
        expect(
          find.textContaining('41'),
          findsNothing,
          reason: 'no order ids in the chat',
        );

        await tester.tap(find.text('Not now'));
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('Dismissed'), findsOneWidget);
        expect(ds.cancelled, isEmpty);
      },
    );

    testWidgets('the Yes button cancels through the API and says so', (
      tester,
    ) async {
      final ds = await openChat(tester, [_order(42, 'pending')]);

      await tester.tap(find.text('Cancel my order'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('Yes, cancel it'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      expect(ds.cancelled, [42]);
      expect(find.text('Done'), findsOneWidget);
      expect(find.textContaining('was cancelled'), findsOneWidget);
    });

    testWidgets('reading a reply aloud sends it to device speech', (
      tester,
    ) async {
      const channel = MethodChannel('flutter_tts');
      final spoken = <String>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'speak') spoken.add(call.arguments as String);
        return 1;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      await openChat(tester, []);
      await tester.tap(find.byTooltip('Read Ibow reply aloud'));
      await tester.pump();
      expect(spoken.single, contains('IBOW'));
    });

    testWidgets('Place an order offers all five services', (tester) async {
      await openChat(tester, []);
      await tester.tap(find.text('Place an order'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      for (final service in [
        'LesRide',
        'LesGo',
        'LesEat',
        'LesBuy',
        'LesTransport',
      ]) {
        expect(find.text('Open $service'), findsOneWidget);
      }
    });
  });
}
