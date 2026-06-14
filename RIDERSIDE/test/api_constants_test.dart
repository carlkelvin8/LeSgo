import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/constants/api_constants.dart';

void main() {
  group('ApiEnvironment', () {
    test('normalizeBaseUrl strips trailing slashes', () {
      expect(
        ApiEnvironment.normalizeBaseUrl('https://api.lesgo.com/api/'),
        'https://api.lesgo.com/api',
      );
    });
  });
}
