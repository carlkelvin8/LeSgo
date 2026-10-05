import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/services/gemini_customer_service.dart';

void main() {
  group('LeSGo customer service fallback', () {
    final service = GeminiCustomerService();

    test('answers greetings without requiring the remote model', () async {
      final reply = await service.sendMessage('hi');

      expect(reply, contains('How can I help'));
      expect(reply, contains('LeSGo'));
    });

    test('answers common account questions locally', () async {
      final reply = await service.sendMessage('I need help with my account');

      expect(reply, contains('Profile or Settings'));
    });

    test('returns a useful fallback instead of an error', () async {
      final reply = await service.sendMessage('I need assistance');

      expect(reply, contains('Settings > Support Tickets'));
      expect(reply, isNot(contains('trouble responding')));
    });
  });
}
