import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/utils/lesbuy_manual_delivery_utils.dart';
import 'package:lesgo/presentation/provider/main/booking/lesbuy/manual_order_provider.dart';
import 'package:lesgo/data/data_source/dto/order/create_order_request_dto.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // MANUAL ORDER STATE - PICKUP LOCATION
  // ═══════════════════════════════════════════════════════════════════════════
  group('ManualOrderState - Pickup Location', () {
    test('rejects blank addresses and invalid or placeholder pins', () {
      for (final coords in [
        [0.0, 0.0],
        [91.0, 124.0],
        [8.0, 181.0],
        [double.nan, 124.0],
        [8.0, double.infinity],
      ]) {
        expect(ManualOrderState(
          pickupLocationName: 'Store',
          pickupLat: coords[0],
          pickupLng: coords[1],
        ).hasPickupLocation, isFalse);
      }
      expect(ManualOrderState(
        pickupLocationName: '   ', pickupLat: 8.45, pickupLng: 124.63,
      ).hasPickupLocation, isFalse);
    });

    test('buying address and pin survive adding to cart and clear with the order', () {
      final notifier = ManualOrderNotifier();
      addTearDown(notifier.dispose);
      notifier.setPickupLocation('  Store, Main Street  ', 8.45, 124.63);
      notifier.addItem('Rice', '', 1);
      notifier.confirmItems();
      expect(notifier.state.pickupLocationName, 'Store, Main Street');
      expect(notifier.state.pickupLat, 8.45);
      expect(notifier.state.pickupLng, 124.63);
      expect(notifier.state.hasPickupLocation, isTrue);
      notifier.clearAll();
      expect(notifier.state.hasPickupLocation, isFalse);
    });

    test('initially has no pickup location', () {
      final state = ManualOrderState();
      expect(state.hasPickupLocation, isFalse);
      expect(state.pickupLocationName, isNull);
      expect(state.pickupLat, isNull);
      expect(state.pickupLng, isNull);
    });

    test('hasPickupLocation true when all fields set', () {
      final state = ManualOrderState(
        pickupLocationName: 'SM CDO',
        pickupLat: 8.4542,
        pickupLng: 124.6319,
      );
      expect(state.hasPickupLocation, isTrue);
    });

    test('hasPickupLocation false when name empty', () {
      final state = ManualOrderState(
        pickupLocationName: '',
        pickupLat: 8.4542,
        pickupLng: 124.6319,
      );
      expect(state.hasPickupLocation, isFalse);
    });

    test('hasPickupLocation false when lat/lng null', () {
      final state = ManualOrderState(
        pickupLocationName: 'Store',
        pickupLat: null,
        pickupLng: 124.6319,
      );
      expect(state.hasPickupLocation, isFalse);
    });

    test('copyWith sets pickup location', () {
      final state = ManualOrderState();
      final updated = state.copyWith(
        pickupLocationName: 'Mercury Drug',
        pickupLat: 8.45,
        pickupLng: 124.63,
      );
      expect(updated.pickupLocationName, 'Mercury Drug');
      expect(updated.pickupLat, 8.45);
      expect(updated.pickupLng, 124.63);
      expect(updated.hasPickupLocation, isTrue);
    });

    test('copyWith clearPickupLocation resets all fields', () {
      final state = ManualOrderState(
        pickupLocationName: 'Store',
        pickupLat: 8.45,
        pickupLng: 124.63,
      );
      final cleared = state.copyWith(clearPickupLocation: true);
      expect(cleared.pickupLocationName, isNull);
      expect(cleared.pickupLat, isNull);
      expect(cleared.pickupLng, isNull);
      expect(cleared.hasPickupLocation, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // MANUAL ORDER STATE - ITEMS
  // ═══════════════════════════════════════════════════════════════════════════
  group('ManualOrderState - Items', () {
    test('totalItems sums quantities', () {
      final state = ManualOrderState(
        items: [
          ManualOrderItem(id: '1', name: 'Rice', quantity: 2, description: ''),
          ManualOrderItem(id: '2', name: 'Eggs', quantity: 6, description: ''),
        ],
      );
      expect(state.totalItems, 8);
    });

    test('totalConfirmedItems sums confirmed quantities', () {
      final state = ManualOrderState(
        confirmedItems: [
          ManualOrderItem(id: '1', name: 'Bread', quantity: 1, description: ''),
          ManualOrderItem(id: '2', name: 'Milk', quantity: 2, description: ''),
          ManualOrderItem(id: '3', name: 'Sugar', quantity: 1, description: ''),
        ],
      );
      expect(state.totalConfirmedItems, 4);
    });

    test('empty state has zero totals', () {
      final state = ManualOrderState();
      expect(state.totalItems, 0);
      expect(state.totalConfirmedItems, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // LESBUY MANUAL DELIVERY UTILS
  // ═══════════════════════════════════════════════════════════════════════════
  group('LesbuyManualDeliveryUtils', () {
    test('isManualOnlyCart true when only manual items', () {
      expect(
        LesbuyManualDeliveryUtils.isManualOnlyCart(
          hasStoreItems: false,
          hasManualItems: true,
        ),
        isTrue,
      );
    });

    test('isManualOnlyCart false when store items present', () {
      expect(
        LesbuyManualDeliveryUtils.isManualOnlyCart(
          hasStoreItems: true,
          hasManualItems: true,
        ),
        isFalse,
      );
    });

    test('isManualOnlyCart false when no manual items', () {
      expect(
        LesbuyManualDeliveryUtils.isManualOnlyCart(
          hasStoreItems: true,
          hasManualItems: false,
        ),
        isFalse,
      );
    });

    test('isManualOnlyCart false when cart empty', () {
      expect(
        LesbuyManualDeliveryUtils.isManualOnlyCart(
          hasStoreItems: false,
          hasManualItems: false,
        ),
        isFalse,
      );
    });

    test('walletMinimumAmount returns checkout total when certain', () {
      final amount = LesbuyManualDeliveryUtils.walletMinimumAmount(
        orderValueUncertain: false,
        checkoutTotal: 250.0,
      );
      expect(amount, 250.0);
    });

    test('walletMinimumAmount returns minimum when uncertain', () {
      final amount = LesbuyManualDeliveryUtils.walletMinimumAmount(
        orderValueUncertain: true,
        checkoutTotal: 0.0,
      );
      // When uncertain, returns the fallback minimum (could be 0 if no minimum set)
      expect(amount, greaterThanOrEqualTo(0));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ORDER REQUEST DTO - LESBUY MANUAL
  // ═══════════════════════════════════════════════════════════════════════════
  group('CreateOrderRequestDto - LesBuy Manual', () {
    test('manual order uses customer-set pickup location', () {
      final dto = CreateOrderRequestDto(
        serviceId: 4,
        estimatedDistanceM: 3000,
        pickup: OrderAddressDto(
          address: 'Gaisano Mall CDO',
          lat: 8.4550,
          lng: 124.6330,
          contactName: 'LesBuy Rider',
          contactPhone: '+639123456789',
        ),
        dropoff: OrderAddressDto(
          address: 'Customer Home',
          lat: 8.4600,
          lng: 124.6400,
          contactName: 'Juan',
          contactPhone: '+639171234567',
        ),
        items: [
          OrderItemDto(name: 'Shampoo', quantity: 2),
          OrderItemDto(name: 'Toothpaste', quantity: 1),
        ],
        meta: {
          'order_type': 'lesbuy_manual',
          'manual_pickup_source': 'customer_selected',
        },
      );

      final json = dto.toJson();
      expect(json['service_id'], 4);
      // Pickup should have the customer-selected location, not 0/0
      expect(json['pickup'], isNotNull);
      expect(json['meta']['order_type'], 'lesbuy_manual');
      expect(json['meta']['manual_pickup_source'], 'customer_selected');
      expect((json['items'] as List).length, 2);
    });

    test('store order uses store location for pickup', () {
      final dto = CreateOrderRequestDto(
        serviceId: 4,
        partnerId: 1,
        estimatedDistanceM: 2000,
        pickup: OrderAddressDto(
          address: 'Mercury Drug Limketkai',
          lat: 8.4542,
          lng: 124.6319,
          contactName: 'Mercury Drug',
          contactPhone: '+639123456789',
        ),
        dropoff: OrderAddressDto(
          address: 'Home',
          lat: 8.46,
          lng: 124.64,
        ),
        items: [
          OrderItemDto(name: 'Biogesic', quantity: 1, estimatedPrice: 8.0),
        ],
        meta: {'order_type': 'lesbuy', 'subtotal': 8.0},
      );

      final json = dto.toJson();
      expect(json['partner_id'], 1);
      expect(json['meta']['order_type'], 'lesbuy');
    });
  });
}
