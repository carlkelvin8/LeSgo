import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/data/data_source/auth_remote_datasource.dart';
import 'package:lesgo/data/data_source/dto/auth/otp_response_dto.dart';
import 'package:lesgo/domain/entities/auth/register/register_request.dart';
import 'package:lesgo/presentation/provider/register/notifier/otp_notifier.dart';
import 'package:lesgo/presentation/provider/register/notifier/register_state.dart';

class _Otp extends StateNotifier<RegisterState> with OtpNotifier {
  _Otp()
    : super(RegisterState(data: RegisterRequest(phoneNumber: '+639171234570')));
}

class _Api implements AuthRemoteDataSource {
  Map<String, dynamic> response = {
    'success': true,
    'verified': true,
    'message': 'Verified',
    'phone_verification_token': 'server-issued-proof',
  };
  @override
  Future<OtpResponseDto> verifyOtp(String phone, String otp) async =>
      OtpResponseDto.fromJson(response);
  @override
  Future<OtpResponseDto> sendOtp(
    String phone, {
    String channel = 'sms',
  }) async => const OtpResponseDto(success: true, message: 'Sent');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Api api;
  late _Otp notifier;
  setUp(() {
    api = _Api();
    getIt.registerSingleton<AuthRemoteDataSource>(api);
    notifier = _Otp();
  });
  tearDown(() async {
    notifier.dispose();
    await getIt.unregister<AuthRemoteDataSource>();
  });

  test(
    'verified OTP retains server proof and changing phone invalidates it',
    () async {
      expect(await notifier.verifyOtp('123456'), true);
      expect(notifier.state.data.phoneVerificationToken, 'server-issued-proof');
      notifier.updatePhoneNumber('+639171234571');
      expect(notifier.state.data.phoneVerificationToken, isEmpty);
    },
  );

  test('resending OTP invalidates the previous proof', () async {
    await notifier.verifyOtp('123456');
    await notifier.resendOtp(notifier.state.data.phoneNumber);
    expect(notifier.state.data.phoneVerificationToken, isEmpty);
  });

  test(
    'a verified flag without server proof cannot complete verification',
    () async {
      api.response.remove('phone_verification_token');
      expect(await notifier.verifyOtp('123456'), false);
      expect(notifier.state.data.phoneVerificationToken, isEmpty);
      expect(notifier.state.isLoading, false);
    },
  );
}
