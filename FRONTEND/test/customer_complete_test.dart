import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/utils/voucher_service_utils.dart';
import 'package:lesgo/data/data_source/order_remote_datasource.dart';
import 'package:lesgo/data/data_source/dto/order/create_order_request_dto.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // BOOKING SERVICE IDS
  // ═══════════════════════════════════════════════════════════════════════════
  group('BookingServiceIds', () {
    test('service IDs are correctly mapped', () {
      expect(BookingServiceIds.lesgo, 1);
      expect(BookingServiceIds.lesride, 2);
      expect(BookingServiceIds.leseat, 3);
      expect(BookingServiceIds.lesbuy, 4);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATE ORDER REQUEST DTO
  // ═══════════════════════════════════════════════════════════════════════════
  group('CreateOrderRequestDto', () {
    test('serializes to JSON correctly', () {
      final dto = CreateOrderRequestDto(
        serviceId: 1,
        estimatedDistanceM: 5000,
        pickup: OrderAddressDto(
          address: '123 Main St',
          lat: 8.4542,
          lng: 124.6319,
          contactName: 'Juan',
          contactPhone: '+639171234567',
        ),
        dropoff: OrderAddressDto(
          address: '456 Oak Ave',
          lat: 8.4600,
          lng: 124.6400,
          contactName: 'Maria',
          contactPhone: '+639181234567',
        ),
        paymentMethod: 'cash',
        notes: 'Handle with care',
      );

      final json = dto.toJson();
      expect(json['service_id'], 1);
      expect(json['estimated_distance_m'], 5000);
      expect(json['payment_method'], 'cash');
      expect(json['notes'], 'Handle with care');
      // Pickup/dropoff are nested objects
      expect(json['pickup'], isNotNull);
      expect(json['dropoff'], isNotNull);
    });

    test('serializes with items for LesEat/LesBuy', () {
      final dto = CreateOrderRequestDto(
        serviceId: 3,
        partnerId: 1,
        estimatedDistanceM: 3000,
        pickup: OrderAddressDto(address: 'Store', lat: 8.45, lng: 124.63),
        dropoff: OrderAddressDto(address: 'Home', lat: 8.46, lng: 124.64),
        items: [
          OrderItemDto(name: 'Burger', quantity: 2, estimatedPrice: 120),
          OrderItemDto(name: 'Fries', quantity: 1, estimatedPrice: 65),
        ],
        meta: {'order_value': 305, 'subtotal': 305},
      );

      final json = dto.toJson();
      expect(json['partner_id'], 1);
      expect(json['items'], isNotNull);
      expect((json['items'] as List).length, 2);
      expect(json['meta']?['subtotal'], 305);
    });

    test('serializes voucher code and discount', () {
      final dto = CreateOrderRequestDto(
        serviceId: 1,
        estimatedDistanceM: 2000,
        pickup: OrderAddressDto(address: 'A', lat: 0, lng: 0),
        dropoff: OrderAddressDto(address: 'B', lat: 0, lng: 0),
        voucherCode: 'SAVE20',
        discountAmount: 20.0,
      );

      final json = dto.toJson();
      expect(json['voucher_code'], 'SAVE20');
      expect(json['discount_amount'], 20.0);
    });

    test('serializes scheduled delivery time', () {
      final dto = CreateOrderRequestDto(
        serviceId: 4,
        estimatedDistanceM: 4000,
        pickup: OrderAddressDto(address: 'Shop', lat: 8.45, lng: 124.63),
        dropoff: OrderAddressDto(address: 'Office', lat: 8.46, lng: 124.64),
        scheduledDeliveryTime: '2026-07-28T14:00:00Z',
      );

      final json = dto.toJson();
      expect(json['scheduled_delivery_time'], '2026-07-28T14:00:00Z');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // FARE BREAKDOWN RESULT
  // ═══════════════════════════════════════════════════════════════════════════
  group('FareBreakdownResult', () {
    test('stores fare details correctly', () {
      const result = FareBreakdownResult(
        estimatedFare: 65.0,
        distanceKm: 5.0,
        estimatedDurationMinutes: 10.0,
        baseFare: 40.0,
        distanceFare: 19.0,
        serviceFee: 0.0,
        weightSurcharge: 0.0,
        total: 59.0,
      );

      expect(result.estimatedFare, 65.0);
      expect(result.baseFare, 40.0);
      expect(result.distanceFare, 19.0);
      expect(result.total, 59.0);
      expect(result.distanceKm, 5.0);
    });

    test('weight surcharge included when applicable', () {
      const result = FareBreakdownResult(
        estimatedFare: 80.0,
        distanceKm: 3.0,
        estimatedDurationMinutes: 6.0,
        baseFare: 40.0,
        distanceFare: 0.0,
        serviceFee: 0.0,
        weightSurcharge: 30.0,
        total: 70.0,
      );

      expect(result.weightSurcharge, 30.0);
    });

    test('service fee for LesEat/LesBuy orders', () {
      const result = FareBreakdownResult(
        estimatedFare: 85.0,
        distanceKm: 4.0,
        estimatedDurationMinutes: 8.0,
        baseFare: 40.0,
        distanceFare: 9.5,
        serviceFee: 15.0,
        weightSurcharge: 0.0,
        total: 64.5,
      );

      expect(result.serviceFee, 15.0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ORDER ADDRESS DTO
  // ═══════════════════════════════════════════════════════════════════════════
  group('OrderAddressDto', () {
    test('serializes all fields', () {
      final addr = OrderAddressDto(
        address: 'SM CDO',
        lat: 8.4542,
        lng: 124.6319,
        contactName: 'Customer',
        contactPhone: '+639171234567',
      );

      final json = addr.toJson();
      expect(json['address'], 'SM CDO');
      expect(json['lat'], 8.4542);
      expect(json['lng'], 124.6319);
      expect(json['contact_name'], 'Customer');
      expect(json['contact_phone'], '+639171234567');
    });

    test('contact fields are optional', () {
      final addr = OrderAddressDto(
        address: 'Location',
        lat: 0,
        lng: 0,
      );

      final json = addr.toJson();
      expect(json['address'], 'Location');
      expect(json['contact_name'], isNull);
      expect(json['contact_phone'], isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ORDER ITEM DTO
  // ═══════════════════════════════════════════════════════════════════════════
  group('OrderItemDto', () {
    test('serializes with all fields', () {
      final item = OrderItemDto(
        name: 'Chicken Joy',
        quantity: 3,
        estimatedPrice: 99.0,
        notes: 'Extra gravy',
        menuItemId: 42,
      );

      final json = item.toJson();
      expect(json['name'], 'Chicken Joy');
      expect(json['quantity'], 3);
      expect(json['estimated_price'], 99.0);
      expect(json['notes'], 'Extra gravy');
      expect(json['menu_item_id'], 42);
    });

    test('optional fields can be null', () {
      final item = OrderItemDto(name: 'Water', quantity: 1);
      final json = item.toJson();
      expect(json['name'], 'Water');
      expect(json['quantity'], 1);
      expect(json['estimated_price'], isNull);
    });
  });
}
