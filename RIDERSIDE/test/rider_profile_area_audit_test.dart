import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/utils/validators/profile_validator.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_document_verification_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_edit_profile_screen.dart';

void main() {
  group('driverProfileIdFrom (PHP empty array safe)', () {
    test('reads id from user.driver_profile', () {
      expect(
        RiderEditProfileScreen.driverProfileIdFrom({
          'user': {
            'driver_profile': {'id': 7},
          },
        }),
        7,
      );
    });
    test('driver_profile encoded as [] does not throw', () {
      expect(
        RiderEditProfileScreen.driverProfileIdFrom({
          'user': {'driver_profile': []},
        }),
        isNull,
      );
    });
    test('missing / non-map user does not throw', () {
      expect(RiderEditProfileScreen.driverProfileIdFrom({'user': []}), isNull);
      expect(RiderEditProfileScreen.driverProfileIdFrom({}), isNull);
    });
  });

  group('ProfileValidator.phone / maxLength', () {
    test('accepts empty and typical PH numbers', () {
      expect(ProfileValidator.phone(''), isNull);
      expect(ProfileValidator.phone(null), isNull);
      expect(ProfileValidator.phone('09949768791'), isNull);
      expect(ProfileValidator.phone('+63 994 976 8791'), isNull);
    });
    test('rejects letters, too short and too long', () {
      expect(ProfileValidator.phone('abc12345'), isNotNull);
      expect(ProfileValidator.phone('123'), isNotNull);
      expect(ProfileValidator.phone('1' * 21), isNotNull);
    });
    test('maxLength mirrors API limits', () {
      expect(ProfileValidator.maxLength('A' * 20, 20, 'Plate number'), isNull);
      expect(ProfileValidator.maxLength('A' * 21, 20, 'Plate number'),
          contains('20'));
    });
  });

  group('document submission validation', () {
    test('requires number and at least one photo', () {
      final v = RiderDocumentVerificationScreen.validateSubmission;
      expect(v('', 1), isNotNull);
      expect(v('   ', 1), isNotNull);
      expect(v('N01-23', 0), isNotNull);
      expect(v('N01-23', 2), isNull);
      expect(v('x' * 101, 1), isNotNull);
    });
  });
}
