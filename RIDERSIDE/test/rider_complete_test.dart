import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/utils/rider_commission_utils.dart';
import 'package:lezgo_rider/core/utils/rider_wallet_policy.dart';
import 'package:lezgo_rider/core/utils/booking_workflow.dart';
import 'package:lezgo_rider/core/utils/merchant_order_ops_utils.dart';
import 'package:lezgo_rider/domain/entities/rider_booking.dart';
import 'package:lezgo_rider/domain/models/rider_order.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_orders_state.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // RIDER COMMISSION TESTS
  // ═══════════════════════════════════════════════════════════════════════════
  group('RiderCommissionUtils', () {
    test('basic tier = 70% rate', () {
      expect(RiderCommissionUtils.rateForPackage('basic'), 0.70);
    });

    test('advance tier = 80% rate', () {
      expect(RiderCommissionUtils.rateForPackage('advance'), 0.80);
      expect(RiderCommissionUtils.rateForPackage('advanced'), 0.80);
    });

    test('pro tier = 90% rate', () {
      expect(RiderCommissionUtils.rateForPackage('pro'), 0.90);
      expect(RiderCommissionUtils.rateForPackage('pro_rider'), 0.90);
    });

    test('null/empty tier defaults to basic', () {
      expect(RiderCommissionUtils.rateForPackage(null), 0.70);
      expect(RiderCommissionUtils.rateForPackage(''), 0.70);
    });

    test('earningsFromShipping uses driverShare when available', () {
      final earnings = RiderCommissionUtils.earningsFromShipping(
        shippingFee: 100,
        driverShare: 85,
        packageTier: 'basic',
      );
      expect(earnings, 85); // Uses driverShare, not calculated
    });

    test('earningsFromShipping calculates from rate when no driverShare', () {
      final earnings = RiderCommissionUtils.earningsFromShipping(
        shippingFee: 100,
        driverShare: null,
        packageTier: 'advance',
      );
      expect(earnings, 80); // 100 * 0.80
    });

    test('earningsFromShipping with zero driverShare falls back to rate', () {
      final earnings = RiderCommissionUtils.earningsFromShipping(
        shippingFee: 50,
        driverShare: 0,
        packageTier: 'pro',
      );
      expect(earnings, 45); // 50 * 0.90
    });

    test('normalizePackageTier handles edge cases', () {
      expect(RiderCommissionUtils.normalizePackageTier('BASIC'), 'basic');
      expect(RiderCommissionUtils.normalizePackageTier(' Pro '), 'pro');
      expect(RiderCommissionUtils.normalizePackageTier('professional'), 'pro');
      expect(RiderCommissionUtils.normalizePackageTier('employee'), 'employee');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WALLET POLICY TESTS
  // ═══════════════════════════════════════════════════════════════════════════
  group('RiderWalletPolicy', () {
    test('can accept with sufficient balance', () {
      expect(RiderWalletPolicy.canAcceptBooking(11.0), isTrue);
      expect(RiderWalletPolicy.canAcceptBooking(100.0), isTrue);
      expect(RiderWalletPolicy.canAcceptBooking(1000.0), isTrue);
    });

    test('cannot accept with insufficient balance', () {
      expect(RiderWalletPolicy.canAcceptBooking(10.0), isFalse);
      expect(RiderWalletPolicy.canAcceptBooking(5.0), isFalse);
      expect(RiderWalletPolicy.canAcceptBooking(0.0), isFalse);
      expect(RiderWalletPolicy.canAcceptBooking(-5.0), isFalse);
    });

    test('shows top-up warning below minimum', () {
      expect(RiderWalletPolicy.shouldShowTopUpWarning(10.0), isTrue);
      expect(RiderWalletPolicy.shouldShowTopUpWarning(5.0), isTrue);
      expect(RiderWalletPolicy.shouldShowTopUpWarning(11.0), isFalse);
      expect(RiderWalletPolicy.shouldShowTopUpWarning(50.0), isFalse);
    });

    test('acceptBlockedMessage is empty when can accept', () {
      expect(RiderWalletPolicy.acceptBlockedMessage(100.0), '');
    });

    test('acceptBlockedMessage has content when blocked', () {
      final msg = RiderWalletPolicy.acceptBlockedMessage(5.0);
      expect(msg, isNotEmpty);
      expect(msg, contains('5.00'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOKING WORKFLOW STATUS MAPPING TESTS
  // ═══════════════════════════════════════════════════════════════════════════
  group('BookingWorkflow', () {
    group('mapApiStatus - LesRide (serviceId=2)', () {
      test('accepted → pending', () {
        expect(BookingWorkflow.mapApiStatus('accepted', 2), BookingStatus.pending);
      });

      test('driver_arrived_at_pickup → forPickUp', () {
        expect(BookingWorkflow.mapApiStatus('driver_arrived_at_pickup', 2), BookingStatus.forPickUp);
      });

      test('in_progress → inProgress', () {
        expect(BookingWorkflow.mapApiStatus('in_progress', 2), BookingStatus.inProgress);
      });

      test('picked_up → forDelivery', () {
        expect(BookingWorkflow.mapApiStatus('picked_up', 2), BookingStatus.forDelivery);
      });

      test('completed → delivered', () {
        expect(BookingWorkflow.mapApiStatus('completed', 2), BookingStatus.delivered);
      });

      test('cancelled → cancelled', () {
        expect(BookingWorkflow.mapApiStatus('cancelled', 2), BookingStatus.cancelled);
      });
    });

    group('mapApiStatus - LesEat (serviceId=3)', () {
      test('ready_for_pickup → forPickUp', () {
        expect(BookingWorkflow.mapApiStatus('ready_for_pickup', 3), BookingStatus.forPickUp);
      });

      test('picked_up → forDelivery', () {
        expect(BookingWorkflow.mapApiStatus('picked_up', 3), BookingStatus.forDelivery);
      });
    });

    group('mapApiStatus - LesBuy (serviceId=4)', () {
      test('accepted → inProgress', () {
        expect(BookingWorkflow.mapApiStatus('accepted', 4), BookingStatus.inProgress);
      });

      test('picked_up → forDelivery', () {
        expect(BookingWorkflow.mapApiStatus('picked_up', 4), BookingStatus.forDelivery);
      });
    });

    test('isActiveApiStatus recognizes all active statuses', () {
      expect(BookingWorkflow.isActiveApiStatus('accepted'), isTrue);
      expect(BookingWorkflow.isActiveApiStatus('ready_for_pickup'), isTrue);
      expect(BookingWorkflow.isActiveApiStatus('driver_arrived_at_pickup'), isTrue);
      expect(BookingWorkflow.isActiveApiStatus('in_progress'), isTrue);
      expect(BookingWorkflow.isActiveApiStatus('picked_up'), isTrue);
    });

    test('isActiveApiStatus rejects terminal/pending statuses', () {
      expect(BookingWorkflow.isActiveApiStatus('pending'), isFalse);
      expect(BookingWorkflow.isActiveApiStatus('completed'), isFalse);
      expect(BookingWorkflow.isActiveApiStatus('cancelled'), isFalse);
      expect(BookingWorkflow.isActiveApiStatus(null), isFalse);
    });

    test('isTerminal recognizes completed and cancelled', () {
      expect(BookingWorkflow.isTerminal('completed'), isTrue);
      expect(BookingWorkflow.isTerminal('cancelled'), isTrue);
      expect(BookingWorkflow.isTerminal('accepted'), isFalse);
      expect(BookingWorkflow.isTerminal('picked_up'), isFalse);
    });

    test('isHistoryEligible includes completed/cancelled orders', () {
      expect(BookingWorkflow.isHistoryEligible({'status': 'completed'}), isTrue);
      expect(BookingWorkflow.isHistoryEligible({'status': 'cancelled'}), isTrue);
    });

    test('isHistoryEligible includes active assigned orders', () {
      expect(
        BookingWorkflow.isHistoryEligible({'status': 'accepted', 'driver_id': 1}),
        isTrue,
      );
      expect(
        BookingWorkflow.isHistoryEligible({'status': 'picked_up', 'driver_id': 1}),
        isTrue,
      );
    });

    test('isHistoryEligible excludes unassigned pending', () {
      expect(
        BookingWorkflow.isHistoryEligible({'status': 'pending'}),
        isFalse,
      );
      expect(
        BookingWorkflow.isHistoryEligible({'status': 'searching_driver'}),
        isFalse,
      );
    });

    test('nextActions returns arrival action from accepted', () {
      final actions = BookingWorkflow.nextActions(
        apiStatus: 'accepted',
        category: BookingCategory.lesRide,
      );
      expect(actions, isNotEmpty);
      expect(actions.first.targetStatus, BookingStatus.driverHasArrived);
    });

    test('nextActions returns pickup from driver_arrived', () {
      final actions = BookingWorkflow.nextActions(
        apiStatus: 'driver_arrived_at_pickup',
        category: BookingCategory.lesEat,
      );
      expect(actions, isNotEmpty);
      expect(actions.first.targetStatus, BookingStatus.forDelivery);
    });

    test('nextActions returns complete from picked_up', () {
      final actions = BookingWorkflow.nextActions(
        apiStatus: 'picked_up',
        category: BookingCategory.lesRide,
      );
      expect(actions, isNotEmpty);
      expect(actions.first.targetStatus, BookingStatus.delivered);
    });

    test('nextActions empty for terminal statuses', () {
      expect(
        BookingWorkflow.nextActions(apiStatus: 'completed', category: BookingCategory.lesRide),
        isEmpty,
      );
      expect(
        BookingWorkflow.nextActions(apiStatus: 'cancelled', category: BookingCategory.lesBuy),
        isEmpty,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RIDER ORDER MODEL TESTS
  // ═══════════════════════════════════════════════════════════════════════════
  group('RiderOrder', () {
    test('fromJson parses minimal order', () {
      final order = RiderOrder.fromJson({
        'id': 42,
        'service_id': 1,
        'status': 'pending',
        'pickup_address': '123 Main St',
        'pickup_lat': 8.4542,
        'pickup_lng': 124.6319,
        'dropoff_address': '456 Oak Ave',
        'dropoff_lat': 8.4600,
        'dropoff_lng': 124.6400,
        'estimated_fare': 65.0,
        'estimated_distance_m': 3200,
        'payment_method': 'cash',
      });

      expect(order.id, 42);
      expect(order.serviceId, 1);
      expect(order.status, 'pending');
      expect(order.pickupAddress, '123 Main St');
      expect(order.pickupLat, 8.4542);
      expect(order.estimatedFare, 65.0);
      expect(order.distanceKm, closeTo(3.2, 0.01));
      expect(order.serviceName, 'LesGo');
      expect(order.paymentMethod, 'cash');
    });

    test('fromJson extracts driver_id from direct field', () {
      final order = RiderOrder.fromJson({
        'id': 1,
        'service_id': 2,
        'status': 'accepted',
        'pickup_address': 'A',
        'pickup_lat': 0,
        'pickup_lng': 0,
        'dropoff_address': 'B',
        'dropoff_lat': 0,
        'dropoff_lng': 0,
        'estimated_fare': 40,
        'estimated_distance_m': 1000,
        'payment_method': 'wallet',
        'driver_id': 5,
      });

      expect(order.driverId, 5);
    });

    test('fromJson extracts driver_id from driver_profile', () {
      final order = RiderOrder.fromJson({
        'id': 2,
        'service_id': 3,
        'status': 'accepted',
        'pickup_address': 'A',
        'pickup_lat': 0,
        'pickup_lng': 0,
        'dropoff_address': 'B',
        'dropoff_lat': 0,
        'dropoff_lng': 0,
        'estimated_fare': 40,
        'estimated_distance_m': 1000,
        'payment_method': 'cash',
        'driver_profile': {'id': 7, 'user_id': 10},
      });

      expect(order.driverId, 7);
    });

    test('fromJson parses lesbuy_items', () {
      final order = RiderOrder.fromJson({
        'id': 3,
        'service_id': 4,
        'status': 'pending',
        'pickup_address': 'Store',
        'pickup_lat': 0,
        'pickup_lng': 0,
        'dropoff_address': 'Customer',
        'dropoff_lat': 0,
        'dropoff_lng': 0,
        'estimated_fare': 50,
        'estimated_distance_m': 2000,
        'payment_method': 'cash',
        'lesbuy_items': [
          {'name': 'Burger', 'quantity': 2, 'estimated_price': 120},
          {'name': 'Fries', 'quantity': 1, 'estimated_price': 65},
        ],
      });

      expect(order.parsedItems.length, 2);
      expect(order.parsedItems[0], contains('Burger'));
      expect(order.itemsTotal, closeTo(305.0, 0.01)); // 2*120 + 1*65
    });

    test('fromJson extracts customer contact from user field', () {
      final order = RiderOrder.fromJson({
        'id': 4,
        'service_id': 1,
        'status': 'pending',
        'pickup_address': 'A',
        'pickup_lat': 0,
        'pickup_lng': 0,
        'dropoff_address': 'B',
        'dropoff_lat': 0,
        'dropoff_lng': 0,
        'estimated_fare': 40,
        'estimated_distance_m': 1000,
        'payment_method': 'cash',
        'user': {'name': 'Juan Cruz', 'phone_number': '+639171234567'},
      });

      expect(order.dropoffContactName, 'Juan Cruz');
      expect(order.dropoffContactPhone, '+639171234567');
    });

    test('serviceName maps service IDs correctly', () {
      expect(RiderOrder.fromJson(_minimalOrder(serviceId: 1)).serviceName, 'LesGo');
      expect(RiderOrder.fromJson(_minimalOrder(serviceId: 2)).serviceName, 'LesRide');
      expect(RiderOrder.fromJson(_minimalOrder(serviceId: 3)).serviceName, 'LesEat');
      expect(RiderOrder.fromJson(_minimalOrder(serviceId: 4)).serviceName, 'LesBuy');
    });

    test('displayEarnings returns shipping fee', () {
      final order = RiderOrder.fromJson({
        ..._minimalOrder(),
        'estimated_fare': 75.0,
      });
      expect(order.displayEarnings, 75.0);
    });

    test('copyWith preserves fields', () {
      final order = RiderOrder.fromJson(_minimalOrder());
      final updated = order.copyWith(status: 'accepted', driverId: 10);
      expect(updated.status, 'accepted');
      expect(updated.driverId, 10);
      expect(updated.id, order.id);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RIDER ORDERS STATE TESTS
  // ═══════════════════════════════════════════════════════════════════════════
  group('RiderOrdersState', () {
    test('isActiveOrderForDriver matches driver profile ID', () {
      final order = RiderOrder.fromJson({
        ..._minimalOrder(),
        'status': 'accepted',
        'driver_id': 5,
      });

      expect(isActiveOrderForDriver(order, 5), isTrue);
      expect(isActiveOrderForDriver(order, 99), isFalse);
    });

    test('isActiveOrderForDriver false for non-active status', () {
      final order = RiderOrder.fromJson({
        ..._minimalOrder(),
        'status': 'completed',
        'driver_id': 5,
      });
      expect(isActiveOrderForDriver(order, 5), isFalse);
    });

    test('isActiveOrderForDriver false when no driver assigned', () {
      final order = RiderOrder.fromJson({
        ..._minimalOrder(),
        'status': 'accepted',
      });
      expect(isActiveOrderForDriver(order, 5), isFalse);
    });

    test('copyWith clears active order', () {
      final state = RiderOrdersState(
        activeOrder: RiderOrder.fromJson({..._minimalOrder(), 'status': 'accepted', 'driver_id': 1}),
      );
      final cleared = state.copyWith(clearActiveOrder: true);
      expect(cleared.activeOrder, isNull);
      expect(cleared.activeOrders, isEmpty);
    });

    test('copyWith sets lastRefreshed', () {
      final now = DateTime.now();
      final state = RiderOrdersState();
      final updated = state.copyWith(lastRefreshed: now);
      expect(updated.lastRefreshed, now);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // MERCHANT ORDER OPS TESTS
  // ═══════════════════════════════════════════════════════════════════════════
  group('MerchantOrderOpsUtils', () {
    test('canAccept only for pending', () {
      expect(MerchantOrderOpsUtils.canAccept('pending'), isTrue);
      expect(MerchantOrderOpsUtils.canAccept('accepted'), isFalse);
      expect(MerchantOrderOpsUtils.canAccept('searching_driver'), isFalse);
    });

    test('canCancelAfterAccept for searching/accepted/ready', () {
      expect(MerchantOrderOpsUtils.canCancelAfterAccept('searching_driver'), isTrue);
      expect(MerchantOrderOpsUtils.canCancelAfterAccept('accepted'), isTrue);
      expect(MerchantOrderOpsUtils.canCancelAfterAccept('ready_for_pickup'), isTrue);
      expect(MerchantOrderOpsUtils.canCancelAfterAccept('picked_up'), isFalse);
      expect(MerchantOrderOpsUtils.canCancelAfterAccept('completed'), isFalse);
    });

    test('canMarkReadyForPickup for searching/accepted', () {
      expect(MerchantOrderOpsUtils.canMarkReadyForPickup('searching_driver'), isTrue);
      expect(MerchantOrderOpsUtils.canMarkReadyForPickup('accepted'), isTrue);
      expect(MerchantOrderOpsUtils.canMarkReadyForPickup('pending'), isFalse);
      expect(MerchantOrderOpsUtils.canMarkReadyForPickup('picked_up'), isFalse);
    });

    test('isRiderFlowStatus detects rider has item', () {
      expect(MerchantOrderOpsUtils.isRiderFlowStatus('picked_up'), isTrue);
      expect(MerchantOrderOpsUtils.isRiderFlowStatus('in_progress'), isTrue);
      expect(MerchantOrderOpsUtils.isRiderFlowStatus('completed'), isTrue);
      expect(MerchantOrderOpsUtils.isRiderFlowStatus('searching_driver'), isFalse);
    });
  });
}

/// Helper to create minimal order JSON for testing
Map<String, dynamic> _minimalOrder({int serviceId = 1}) {
  return {
    'id': 1,
    'service_id': serviceId,
    'status': 'pending',
    'pickup_address': 'Pickup',
    'pickup_lat': 8.45,
    'pickup_lng': 124.63,
    'dropoff_address': 'Dropoff',
    'dropoff_lat': 8.46,
    'dropoff_lng': 124.64,
    'estimated_fare': 40.0,
    'estimated_distance_m': 2000,
    'payment_method': 'cash',
  };
}
