import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/services/ssl_pinning_service.dart';

void main() {
  test('pinned API host matches production base URL', () {
    expect(
      SslPinningService.pinnedApiHost,
      'lesgo-api-feature-auth-secmes.free.laravel.cloud',
    );
  });

  test('production fingerprint is configured', () {
    const fingerprint =
        '3E:EB:26:92:E6:27:BE:9A:10:2A:7A:46:86:9A:A4:28:A6:DF:1D:24:E5:52:F1:5C:70:B7:EA:3B:44:74:EB:D8';
    expect(SslPinningService().validateCertificate(fingerprint), isTrue);
  });
}
