import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/presentation/provider/auth/rider_auth_provider.dart';

void main() {
  group('RiderUser driver profile parsing', () {
    Map<String, dynamic> userJson(Map<String, dynamic> extra) => {
      'id': 61,
      'name': 'Test Rider',
      'email': 'rider@example.com',
      'role': 'driver',
      ...extra,
    };

    test('reads nested snake-case driver profile', () {
      final user = RiderUser.fromJson(
        userJson({
          'driver_profile': {'id': 15},
        }),
      );

      expect(user.driverProfileId, 15);
    });

    test('reads legacy camel-case driver profile', () {
      final user = RiderUser.fromJson(
        userJson({
          'driverProfile': {'id': '16'},
        }),
      );

      expect(user.driverProfileId, 16);
    });

    test('reads a direct driver profile ID', () {
      final user = RiderUser.fromJson(userJson({'driver_profile_id': '17'}));

      expect(user.driverProfileId, 17);
    });
  });
}
