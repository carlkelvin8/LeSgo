import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/state/user_session_epoch.dart';
import 'package:lesgo/data/data_source/dto/order/order_dto.dart';
import 'package:lesgo/data/data_source/dto/order/orders_response_dto.dart';
import 'package:lesgo/data/data_source/dto/wallet/wallet_dto.dart';
import 'package:lesgo/data/data_source/order_remote_datasource.dart';
import 'package:lesgo/data/data_source/referral_remote_datasource.dart';
import 'package:lesgo/data/data_source/wallet_remote_datasource.dart';
import 'package:lesgo/domain/entities/transactions/transaction.dart';
import 'package:lesgo/presentation/provider/main/profile/profile_provider.dart';
import 'package:lesgo/presentation/provider/main/referral/referral_provider.dart';
import 'package:lesgo/presentation/provider/main/transactions/transactions_provider.dart';

OrderDto _order(int id, String status, {String method = 'wallet'}) =>
    OrderDto.fromJson({
      'id': id,
      'customer_id': 1,
      'service_id': 1,
      'pickup_address': 'A',
      'pickup_lat': 14.0,
      'pickup_lng': 121.0,
      'pickup_contact_name': 'a',
      'pickup_contact_phone': '1',
      'dropoff_address': 'B',
      'dropoff_lat': 14.1,
      'dropoff_lng': 121.1,
      'dropoff_contact_name': 'b',
      'dropoff_contact_phone': '2',
      'discount_amount': 0,
      'status': status,
      'estimated_distance_m': 1000,
      'estimated_fare': 100,
      'payment_method': method,
      'payment_status': 'paid',
      'created_at': '2026-01-0${id}T10:00:00Z',
    });

class _Orders implements OrderRemoteDataSource {
  bool failList = false;
  bool failReorder = false;
  int reorderCalls = 0;
  Completer<void>? reorderGate;
  List<OrderDto> orders = [_order(1, 'completed')];

  @override
  Future<OrdersResponseDto> getOrders({
    String? status,
    String? paymentStatus,
    int? serviceId,
    int perPage = 20,
    int page = 1,
  }) async {
    if (failList) throw Exception('orders down');
    return OrdersResponseDto(success: true, data: orders);
  }

  @override
  Future<OrderResponseDto> reorderOrder(int orderId) async {
    reorderCalls++;
    await reorderGate?.future;
    if (failReorder) throw Exception('nope');
    return OrderResponseDto(success: true, data: orders.first);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Wallet implements WalletRemoteDataSource {
  bool fail = false;
  @override
  Future<List<WalletTransactionDto>> getMyTransactions({String? type}) async {
    if (fail) throw Exception('wallet down');
    return [
      WalletTransactionDto(
        id: 9,
        walletId: 1,
        type: 'credit',
        amount: 50,
        createdAt: '2026-01-05T10:00:00Z',
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Referral implements ReferralRemoteDataSource {
  int calls = 0;
  @override
  Future<ReferralDashboardDto> getDashboard() async {
    calls++;
    return ReferralDashboardDto.fromJson({
      'referral_code': 'ABC',
      'points_earned': 0,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profile extends ProfileNotifier {
  @override
  Future<void> loadProfile() async {}
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late _Orders orders;
  late _Wallet wallet;

  setUp(() {
    orders = _Orders();
    wallet = _Wallet();
    getIt.registerSingleton<OrderRemoteDataSource>(orders);
    getIt.registerSingleton<WalletRemoteDataSource>(wallet);
  });
  tearDown(getIt.reset);

  Future<ProviderContainer> make() async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.listen(transactionsProvider, (_, __) {});
    await _settle();
    return c;
  }

  group('load', () {
    test('both sources fail sets a mapped error', () async {
      orders.failList = true;
      wallet.fail = true;
      final c = await make();
      final s = c.read(transactionsProvider);
      expect(s.error, isNotNull);
      expect(s.error, isNot(contains('Exception')));
      expect(s.transactions, isEmpty);
    });

    test('one source failing keeps the other and flags partial', () async {
      wallet.fail = true;
      final c = await make();
      var s = c.read(transactionsProvider);
      expect(s.error, isNull);
      expect(s.partialLoadFailed, isTrue);
      expect(s.transactions.length, 1);

      orders.failList = true;
      wallet.fail = false;
      await c.read(transactionsProvider.notifier).refreshTransactions();
      s = c.read(transactionsProvider);
      expect(s.partialLoadFailed, isTrue);
      expect(s.transactions.single.isWallet, isTrue);
    });

    test('both ok has no flag', () async {
      final c = await make();
      final s = c.read(transactionsProvider);
      expect(s.partialLoadFailed, isFalse);
      expect(s.transactions.length, 2);
    });
  });

  group('reorder', () {
    test('returns true on success', () async {
      final c = await make();
      final n = c.read(transactionsProvider.notifier);
      expect(await n.reorderTransaction('1'), isTrue);
    });

    test('throws on failure without touching state.error or list', () async {
      final c = await make();
      final n = c.read(transactionsProvider.notifier);
      orders.failReorder = true;
      await expectLater(n.reorderTransaction('1'), throwsException);
      final s = c.read(transactionsProvider);
      expect(s.error, isNull);
      expect(s.transactions.length, 2);
    });

    test('second tap while in flight is ignored', () async {
      final c = await make();
      final n = c.read(transactionsProvider.notifier);
      orders.reorderGate = Completer<void>();
      final first = n.reorderTransaction('1');
      expect(await n.reorderTransaction('1'), isFalse);
      orders.reorderGate!.complete();
      expect(await first, isTrue);
      expect(orders.reorderCalls, 1);
    });

    test('wallet rows are ignored', () async {
      final c = await make();
      final n = c.read(transactionsProvider.notifier);
      expect(await n.reorderTransaction('w-9'), isFalse);
      expect(orders.reorderCalls, 0);
    });
  });

  group('status mapping', () {
    test('uses OrderStatusConstants', () {
      TransactionStatus m(String s) => TransactionsNotifier.mapOrderStatus(s);
      expect(m('completed'), TransactionStatus.completed);
      expect(m('cancelled'), TransactionStatus.cancelled);
      expect(m('failed'), TransactionStatus.cancelled);
      expect(m('in_progress'), TransactionStatus.pending);
      expect(m('driver_arrived_at_pickup'), TransactionStatus.pending);
      expect(m('scheduled'), TransactionStatus.pending);
      expect(m('something_new'), TransactionStatus.cancelled);
    });

    test('order keeps its real payment method', () async {
      final c = await make();
      final t = c
          .read(transactionsProvider)
          .transactions
          .firstWhere((t) => t.isOrder);
      expect(t.paymentMethod, 'wallet');
    });
  });

  group('referral', () {
    ProviderContainer makeReferral(_Referral ds) {
      getIt.registerSingleton<ReferralRemoteDataSource>(ds);
      final c = ProviderContainer(
        overrides: [profileProvider.overrideWith((_) => _Profile())],
      );
      addTearDown(c.dispose);
      c.listen(referralDashboardProvider, (_, __) {});
      return c;
    }

    test('dashboard refetches when session epoch changes', () async {
      final ds = _Referral();
      final c = makeReferral(ds);
      await _settle();
      expect(ds.calls, 1);
      c.read(userSessionEpochProvider.notifier).state++;
      await _settle();
      expect(ds.calls, 2);
    });

    test('points earned is not backfilled from the profile', () async {
      final c = makeReferral(_Referral());
      await _settle();
      expect(c.read(referralDashboardProvider).pointsEarned, 0);
    });

    test('date and status formatting', () {
      const iso = '2026-03-04T23:30:00Z';
      final expected = DateTime.parse(iso).toLocal();
      final out = formatReferralRewardDate(iso);
      expect(out, isNot(contains('T')));
      expect(out, contains('${expected.day}'));
      expect(out, contains('2026'));
      expect(formatReferralRewardDate('garbage'), 'garbage');
      expect(capitalizeReferralStatus('pending'), 'Pending');
      expect(capitalizeReferralStatus('PAID'), 'Paid');
    });
  });
}
