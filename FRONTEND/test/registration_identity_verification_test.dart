import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/data/data_source/dto/auth/register_request_dto.dart';
import 'package:lesgo/domain/entities/auth/register/register_request.dart';
import 'package:lesgo/presentation/widgets/auth/register/verification_content.dart';

void main() {
  test('registration is incomplete until selfie and both ID sides exist', () {
    expect(RegisterRequest().hasIdentityVerification, isFalse);

    final complete = RegisterRequest(
      selfiePath: '/tmp/selfie.jpg',
      idType: 'philippine_national_id',
      idNumber: '1234-5678-9012-3456',
      validIdFrontPath: '/tmp/id-front.jpg',
      validIdBackPath: '/tmp/id-back.jpg',
    );

    expect(complete.hasIdentityVerification, isTrue);
  });

  test('registration DTO sends government ID fields to the API', () {
    const dto = RegisterRequestDto(
      name: 'Maria Santos',
      email: 'maria@example.com',
      phone: '+639181234567',
      password: 'Password123!',
      passwordConfirmation: 'Password123!',
      termsAccepted: true,
      privacyAccepted: true,
      idType: 'passport',
      idNumber: 'P1234567A',
      role: 'customer',
    );

    expect(dto.toJson()['id_type'], 'passport');
    expect(dto.toJson()['id_number'], 'P1234567A');
  });

  testWidgets('identity step exposes camera actions for all required photos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VerificationContent(
            selfiePath: '',
            idType: '',
            idNumber: '',
            validIdFrontPath: '',
            validIdBackPath: '',
            isLoading: false,
            onCaptureSelfie: () async {},
            onCaptureIdFront: () async {},
            onCaptureIdBack: () async {},
            onIdTypeChanged: (_) {},
            onIdNumberChanged: (_) {},
            onNext: () {},
          ),
        ),
      ),
    );

    expect(find.text('Capture Selfie'), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    expect(find.text('Capture ID Front'), findsOneWidget);
    expect(find.text('Capture ID Back'), findsOneWidget);
  });
}
