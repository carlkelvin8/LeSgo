import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/utils/app_logger.dart';

void main() {
  group('AppLogger', () {
    test('maskEmail hides local part', () {
      expect(AppLogger.maskEmail('rider@example.com'), 'r***@example.com');
    });

    test('sanitize redacts sensitive map keys', () {
      final sanitized = AppLogger.sanitize({
        'email': 'rider@example.com',
        'password': 'secret123',
        'token': 'abc',
        'nested': {'refresh_token': 'xyz'},
      }) as Map;

      expect(sanitized['email'], 'rider@example.com');
      expect(sanitized['password'], '***');
      expect(sanitized['token'], '***');
      expect((sanitized['nested'] as Map)['refresh_token'], '***');
    });
  });
}
