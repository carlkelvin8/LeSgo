import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/utils/merchant_order_ops_utils.dart';
import 'package:lezgo_rider/core/utils/merchant_order_amount_utils.dart';
import 'package:lezgo_rider/core/utils/merchant_payment_utils.dart';
import 'package:lezgo_rider/data/data_source/dto/merchant/order_dto.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_orders_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_prep_timer_provider.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // MERCHANT ORDER OPS UTILS
  // ═══════════════════════════════════════════════════════════════════════════
  group('MerchantOrderOpsUtils', () {
    test('isPending recognizes pending status only', () {
      expect(MerchantOrderOpsUtils.isPending('pending'), isTrue);
      expect(MerchantOrderOpsUtils.isPending('Pending'), isTrue);
      expect(MerchantOrderOpsUtils.isPending('PENDING'), isTrue);
      expect(MerchantOrderOpsUtils.isPending('accepted'), isFalse);
      expect(MerchantOrderOpsUtils.isPending('searching_driver'), isFalse);
    });

    test('canAccept only for pending orders', () {
      expect(MerchantOrderOpsUtils.canAccept('pending'), isTrue);
      expect(MerchantOrderOpsUtils.canAccept('searching_driver'), isFalse);
      expect(MerchantOrderOpsUtils.canAccept('completed'), isFalse);
    });

    test('canReject only for pending orders', () {
      expect(MerchantOrderOpsUtils.canReject('pending'), isTrue);
      expect(MerchantOrderOpsUtils.canReject('accepted'), isFalse);
    });

    test('canCancelAfterAccept for correct statuses', () {
      expect(MerchantOrderOpsUtils.canCancelAfterAccept('searching_driver'), isTrue);
      expect(MerchantOrderOpsUtils.canCancelAfterAccept('accepted'), isTrue);
      expect(MerchantOrderOpsUtils.canCancelAfterAccept('ready_for_pickup'), isTrue);
      expect(MerchantOrderOpsUtils.canCancelAfterAccept('picked_up'), isFalse);
      expect(MerchantOrderOpsUtils.canCancelAfterAccept('completed'), isFalse);
      expect(MerchantOrderOpsUtils.canCancelAfterAccept('pending'), isFalse);
    });

    test('canMarkReadyForPickup from searching/accepted only', () {
      expect(MerchantOrderOpsUtils.canMarkReadyForPickup('searching_driver'), isTrue);
      expect(MerchantOrderOpsUtils.canMarkReadyForPickup('accepted'), isTrue);
      expect(MerchantOrderOpsUtils.canMarkReadyForPickup('pending'), isFalse);
      expect(MerchantOrderOpsUtils.canMarkReadyForPickup('ready_for_pickup'), isFalse);
      expect(MerchantOrderOpsUtils.canMarkReadyForPickup('picked_up'), isFalse);
    });

    test('isRiderFlowStatus detects rider has taken over', () {
      expect(MerchantOrderOpsUtils.isRiderFlowStatus('picked_up'), isTrue);
      expect(MerchantOrderOpsUtils.isRiderFlowStatus('in_progress'), isTrue);
      expect(MerchantOrderOpsUtils.isRiderFlowStatus('driver_arrived_at_pickup'), isTrue);
      expect(MerchantOrderOpsUtils.isRiderFlowStatus('completed'), isTrue);
      expect(MerchantOrderOpsUtils.isRiderFlowStatus('searching_driver'), isFalse);
      expect(MerchantOrderOpsUtils.isRiderFlowStatus('pending'), isFalse);
    });

    test('showsPrepTimer for accepted/searching states', () {
      expect(MerchantOrderOpsUtils.showsPrepTimer('searching_driver'), isTrue);
      expect(MerchantOrderOpsUtils.showsPrepTimer('accepted'), isTrue);
      expect(MerchantOrderOpsUtils.showsPrepTimer('ready_for_pickup'), isFalse);
      expect(MerchantOrderOpsUtils.showsPrepTimer('picked_up'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // MERCHANT ORDER FILTER
  // ═══════════════════════════════════════════════════════════════════════════
  group('MerchantOrderFilter', () {
    final orders = [
      _makeOrder(status: 'pending'),
      _makeOrder(status: 'searching_driver'),
      _makeOrder(status: 'accepted'),
      _makeOrder(status: 'ready_for_pickup'),
      _makeOrder(status: 'picked_up'),
      _makeOrder(status: 'completed'),
      _makeOrder(status: 'cancelled'),
    ];

    test('all filter returns all orders', () {
      final result = filterMerchantOrders(orders, MerchantOrderFilter.all);
      expect(result.length, 7);
    });

    test('pending filter returns only pending', () {
      final result = filterMerchantOrders(orders, MerchantOrderFilter.pending);
      expect(result.length, 1);
      expect(result.first.status, 'pending');
    });

    test('pickUp filter returns searching_driver + accepted', () {
      final result = filterMerchantOrders(orders, MerchantOrderFilter.pickUp);
      expect(result.length, 2);
    });

    test('ready filter returns ready_for_pickup', () {
      final result = filterMerchantOrders(orders, MerchantOrderFilter.ready);
      expect(result.length, 1);
      expect(result.first.status, 'ready_for_pickup');
    });

    test('forDelivery filter returns picked_up', () {
      final result = filterMerchantOrders(orders, MerchantOrderFilter.forDelivery);
      expect(result.length, 1);
      expect(result.first.status, 'picked_up');
    });

    test('completed filter returns completed', () {
      final result = filterMerchantOrders(orders, MerchantOrderFilter.completed);
      expect(result.length, 1);
    });

    test('cancelled filter returns cancelled', () {
      final result = filterMerchantOrders(orders, MerchantOrderFilter.cancelled);
      expect(result.length, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // MERCHANT PREP TIMER
  // ═══════════════════════════════════════════════════════════════════════════
  group('MerchantPrepTimerEntry', () {
    test('isOverdue when past duration', () {
      final entry = MerchantPrepTimerEntry(
        orderId: 1,
        startedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        durationMinutes: 15,
      );
      expect(entry.isOverdue, isTrue);
    });

    test('not overdue when within duration', () {
      final entry = MerchantPrepTimerEntry(
        orderId: 2,
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        durationMinutes: 15,
      );
      expect(entry.isOverdue, isFalse);
    });

    test('remaining is negative when overdue', () {
      final entry = MerchantPrepTimerEntry(
        orderId: 3,
        startedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        durationMinutes: 15,
      );
      expect(entry.remaining.isNegative, isTrue);
    });

    test('displayLabel shows correct format', () {
      final entry = MerchantPrepTimerEntry(
        orderId: 4,
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        durationMinutes: 15,
      );
      // Should show remaining time like "10:xx"
      expect(entry.displayLabel, isNotEmpty);
      expect(entry.displayLabel.contains(':'), isTrue);
    });

    test('endsAt calculated correctly', () {
      final start = DateTime(2026, 7, 28, 10, 0, 0);
      final entry = MerchantPrepTimerEntry(
        orderId: 5,
        startedAt: start,
        durationMinutes: 15,
      );
      expect(entry.endsAt, DateTime(2026, 7, 28, 10, 15, 0));
    });

    test('toJson and fromJson roundtrip', () {
      final entry = MerchantPrepTimerEntry(
        orderId: 6,
        startedAt: DateTime(2026, 7, 28, 10, 0, 0),
        durationMinutes: 15,
      );
      final json = entry.toJson();
      final restored = MerchantPrepTimerEntry.fromJson(json);
      expect(restored.orderId, 6);
      expect(restored.durationMinutes, 15);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // MERCHANT PAYMENT UTILS
  // ═══════════════════════════════════════════════════════════════════════════
  group('MerchantPaymentUtils', () {
    test('methodLabel formats payment methods correctly', () {
      expect(MerchantPaymentUtils.methodLabel('cash'), 'Cash on Delivery');
      expect(MerchantPaymentUtils.methodLabel('wallet'), 'LesPay Wallet');
      expect(MerchantPaymentUtils.methodLabel('gcash'), 'GCash');
      expect(MerchantPaymentUtils.methodLabel('maya'), 'Maya');
    });

    test('statusLabel formats payment statuses', () {
      expect(MerchantPaymentUtils.statusLabel('paid'), 'Paid');
      expect(MerchantPaymentUtils.statusLabel('pending'), 'Pending');
      expect(MerchantPaymentUtils.statusLabel('failed'), 'Failed');
    });

    test('creditsMerchantWallet true for wallet + paid', () {
      expect(MerchantPaymentUtils.creditsMerchantWallet('wallet', 'paid'), isTrue);
    });

    test('creditsMerchantWallet false for cash', () {
      expect(MerchantPaymentUtils.creditsMerchantWallet('cash', 'paid'), isFalse);
    });

    test('creditsMerchantWallet false for wallet + pending', () {
      expect(MerchantPaymentUtils.creditsMerchantWallet('wallet', 'pending'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // MERCHANT ORDER AMOUNT UTILS
  // ═══════════════════════════════════════════════════════════════════════════
  group('MerchantOrderAmountUtils', () {
    test('isCompleted recognizes completed status', () {
      expect(MerchantOrderAmountUtils.isCompleted(_makeOrder(status: 'completed')), isTrue);
      expect(MerchantOrderAmountUtils.isCompleted(_makeOrder(status: 'pending')), isFalse);
    });

    test('isCancelled recognizes cancelled status', () {
      expect(MerchantOrderAmountUtils.isCancelled(_makeOrder(status: 'cancelled')), isTrue);
      expect(MerchantOrderAmountUtils.isCancelled(_makeOrder(status: 'completed')), isFalse);
    });

    test('foodEarnings calculates from partner_share', () {
      final order = _makeOrder(status: 'completed', partnerShare: 150.0);
      expect(MerchantOrderAmountUtils.foodEarnings(order), 150.0);
    });

    test('foodEarnings falls back to fareBreakdownSubtotal', () {
      final order = _makeOrder(
        status: 'completed',
        fareBreakdownSubtotal: 200.0,
      );
      expect(MerchantOrderAmountUtils.foodEarnings(order), 200.0);
    });

    test('foodEarnings falls back to metaOrderValue', () {
      final order = _makeOrder(
        status: 'completed',
        metaOrderValue: 300.0,
      );
      expect(MerchantOrderAmountUtils.foodEarnings(order), 300.0);
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEST HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

OrderDto _makeOrder({
  required String status,
  double? partnerShare,
  double? fareBreakdownSubtotal,
  double? metaOrderValue,
  double? totalFare,
  double? estimatedFare,
}) {
  return OrderDto(
    id: 1,
    userId: 10,
    serviceId: 3,
    referenceNumber: 'ORD-001',
    status: status,
    pickupAddress: 'Store',
    dropoffAddress: 'Customer',
    paymentMethod: 'cash',
    paymentStatus: status == 'completed' ? 'paid' : 'pending',
    createdAt: '2026-07-28T10:00:00Z',
    updatedAt: '2026-07-28T10:00:00Z',
    partnerShare: partnerShare,
    fareBreakdownSubtotal: fareBreakdownSubtotal,
    metaOrderValue: metaOrderValue,
    totalFare: totalFare,
    estimatedFare: estimatedFare,
  );
}
