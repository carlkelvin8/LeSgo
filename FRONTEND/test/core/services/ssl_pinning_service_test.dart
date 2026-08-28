import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/services/ssl_pinning_service.dart';

void main() {
  test('pinned API host matches production base URL', () {
    expect(
      SslPinningService.pinnedApiHost,
      'lesgo-api-feature-auth-fhlrsy.laravel.cloud',
    );
  });

  test('production fingerprint is configured', () {
    const fingerprint =
        '51:5A:49:00:DE:74:25:F1:00:35:E7:AB:D3:AF:49:5B:3E:53:76:26:E1:F5:64:E0:54:C9:4E:9E:12:62:8E:65';
    expect(SslPinningService().validateCertificate(fingerprint), isTrue);
  });

  test('unknown certificate fingerprint is rejected', () {
    const fingerprint =
        '00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00';
    expect(SslPinningService().validateCertificate(fingerprint), isFalse);
  });
}
