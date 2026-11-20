import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/data/data_source/auth_remote_datasource.dart';
import 'package:lesgo/data/data_source/dto/auth/otp_response_dto.dart';
import 'package:lesgo/presentation/widgets/profile/change_phone_sheet.dart';

class FakeAuth extends Fake implements AuthRemoteDataSource {
  final sent = <String>[];
  Object? throwOnSend;
  OtpResponseDto response = const OtpResponseDto(success: true, message: 'ok');

  @override
  Future<OtpResponseDto> sendOtp(
    String phoneNumber, {
    String channel = 'sms',
  }) async {
    sent.add(phoneNumber);
    if (throwOnSend != null) throw throwOnSend!;
    return response;
  }
}

void main() {
  late FakeAuth auth;

  setUp(() {
    auth = FakeAuth();
    getIt.registerSingleton<AuthRemoteDataSource>(auth);
  });
  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ChangePhoneSheet(currentPhone: '')),
        ),
      ),
    );
  }

  Future<void> enterPhoneAndSend(WidgetTester tester, String phone) async {
    await tester.enterText(find.byType(TextField), phone);
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows inline error when sendOtp throws', (tester) async {
    auth.throwOnSend = Exception('boom');
    await pumpSheet(tester);
    await enterPhoneAndSend(tester, '9171234567');

    expect(auth.sent, ['+639171234567']);
    expect(find.byKey(const Key('change_phone_error')), findsOneWidget);
    // OTP step must not be reached.
    expect(find.text('Verify & Save'), findsNothing);
    expect(find.text('Send OTP'), findsOneWidget);
  });

  testWidgets('inline error does not expose technical exception text', (
    tester,
  ) async {
    auth.throwOnSend = StateError('SocketException: connection refused #42');
    await pumpSheet(tester);
    await enterPhoneAndSend(tester, '9171234567');

    final text = tester.widget<Text>(
      find.byKey(const Key('change_phone_error')),
    );
    expect(text.data, isNotEmpty);
    expect(text.data, isNot(contains('SocketException')));
    expect(text.data, isNot(contains('StateError')));
  });

  testWidgets('shows inline error when server answers success=false', (
    tester,
  ) async {
    auth.response = const OtpResponseDto(
      success: false,
      message: 'Number already in use',
    );
    await pumpSheet(tester);
    await enterPhoneAndSend(tester, '9171234567');

    final text = tester.widget<Text>(
      find.byKey(const Key('change_phone_error')),
    );
    expect(text.data, 'Number already in use');
  });

  testWidgets('rejects too-short number without calling the API', (
    tester,
  ) async {
    await pumpSheet(tester);
    await enterPhoneAndSend(tester, '917');

    expect(auth.sent, isEmpty);
    expect(find.byKey(const Key('change_phone_error')), findsOneWidget);
  });

  for (final raw in [
    '9171234567',
    '09171234567',
    '+63 917 123 4567',
    '+63 0917 123 4567',
    '63917-123-4567',
  ]) {
    testWidgets('normalizes "$raw" to +639171234567', (tester) async {
      await pumpSheet(tester);
      await enterPhoneAndSend(tester, raw);

      expect(auth.sent, ['+639171234567']);
      expect(find.byKey(const Key('change_phone_error')), findsNothing);
      // Success moves to the OTP step.
      expect(find.text('Verify & Save'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('error clears after a successful retry', (tester) async {
    auth.throwOnSend = Exception('boom');
    await pumpSheet(tester);
    await enterPhoneAndSend(tester, '9171234567');
    expect(find.byKey(const Key('change_phone_error')), findsOneWidget);

    auth.throwOnSend = null;
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('change_phone_error')), findsNothing);
    expect(find.text('Verify & Save'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
