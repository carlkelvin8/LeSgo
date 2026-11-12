import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/utils/cart_checkout_validation.dart';

void main() {
  group('validateCartDeliveryDetails', () {
    test('requires a delivery address', () {
      expect(
        validateCartDeliveryDetails(address: '  ', hasPinnedLocation: true),
        'Please enter a delivery address.',
      );
    });

    test('requires a pinned location before checkout can continue', () {
      expect(
        validateCartDeliveryDetails(
          address: 'QA test address',
          hasPinnedLocation: false,
        ),
        'Pin the delivery location so the delivery fee can be calculated.',
      );
    });

    test('accepts complete delivery details', () {
      expect(
        validateCartDeliveryDetails(
          address: 'QA test address',
          hasPinnedLocation: true,
        ),
        isNull,
      );
    });
  });
}
