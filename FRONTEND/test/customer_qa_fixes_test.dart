import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/utils/app_localization.dart';
import 'package:lesgo/core/utils/driver_display_utils.dart';
import 'package:lesgo/core/utils/phone_utils.dart';
import 'package:lesgo/domain/models/location/location_address.dart';
import 'package:lesgo/presentation/provider/main/offers/offers_provider.dart';

void main() {
  group('PhoneUtils.normalizePh', () {
    test('strips spaces and a duplicated leading zero', () {
      expect(PhoneUtils.normalizePh('+63 09171234567'), '+639171234567');
      expect(PhoneUtils.normalizePh('+63 917 123 4567'), '+639171234567');
    });

    test('accepts local, country-code and bare forms', () {
      expect(PhoneUtils.normalizePh('09171234567'), '+639171234567');
      expect(PhoneUtils.normalizePh('639171234567'), '+639171234567');
      expect(PhoneUtils.normalizePh('9171234567'), '+639171234567');
      expect(PhoneUtils.normalizePh('+639171234567'), '+639171234567');
    });

    test('returns empty for empty input', () {
      expect(PhoneUtils.normalizePh(''), '');
      expect(PhoneUtils.normalizePh('   '), '');
    });
  });

  group('LocationAddress.toString', () {
    test('is a readable address, never an instance dump', () {
      final a = LocationAddress(
        houseNumberStreet: 'Burgos St',
        subdivisionBarangay: 'Centro 1',
        cityProvince: 'Claveria, Cagayan',
      );
      expect(a.toString(), 'Burgos St, Centro 1, Claveria, Cagayan');
      expect(a.toString(), isNot(contains('Instance of')));
    });

    test('skips blank parts', () {
      final a = LocationAddress(
        houseNumberStreet: '  ',
        cityProvince: 'Claveria, Claveria',
      );
      expect(a.toString(), 'Claveria, Claveria');
    });
  });

  group('offerIsExpired', () {
    final now = DateTime(2026, 11, 14, 12);

    test('past dates are expired', () {
      expect(offerIsExpired('2026-06-30', now: now), isTrue);
    });

    test('the expiry day itself and future dates are valid', () {
      expect(offerIsExpired('2026-11-14', now: now), isFalse);
      expect(offerIsExpired('2026-12-31', now: now), isFalse);
    });

    test('free text and null are kept', () {
      expect(offerIsExpired('Limited time', now: now), isFalse);
      expect(offerIsExpired(null, now: now), isFalse);
    });
  });

  group('DriverInfo', () {
    test('map constructor uses the driver USER id for the reviews screen', () {
      final info = DriverInfo.fromDriverProfileMap({
        'id': 7,
        'user_id': 21,
        'user': {'name': 'Test Rider'},
        'plate_number': 'ABC-1234',
      });
      expect(info?.driverId, 21);
    });

    test('map constructor falls back to the nested user id', () {
      final info = DriverInfo.fromDriverProfileMap({
        'id': 7,
        'user': {'id': 22, 'name': 'Test Rider'},
      });
      expect(info?.driverId, 22);
    });

    test(
      'fallback driver has no review id (order.driver_id is a profile id)',
      () {
        final info = DriverInfo.fromDriverProfile(null, fallbackDriverId: 3);
        expect(info?.driverId, isNull);
        expect(info?.name, 'Driver #3');
      },
    );
  });

  group('Settings subtitles', () {
    test('are translated to Filipino and fall back to English', () {
      const key = 'Manage your delivery addresses';
      expect(AppLocalization.translate(key, AppLanguage.english), key);
      expect(AppLocalization.translate(key, AppLanguage.filipino), isNot(key));
    });
  });
}
