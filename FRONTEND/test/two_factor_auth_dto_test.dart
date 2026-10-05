import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/data/data_source/dto/login/login_request_dto.dart';
import 'package:lesgo/data/data_source/dto/user/user_dto.dart';

void main() {
  test('login request sends the authenticator code using the API field', () {
    final request = LoginRequestDto(
      email: 'customer@example.com',
      password: 'Secret123!',
      twoFactorCode: '123456',
    );

    expect(request.toJson()['two_factor_code'], '123456');
  });

  test('login response recognizes a two-factor challenge', () {
    final response = UserDto.fromJson(const {
      'success': false,
      'message': 'Enter your authenticator code.',
      'two_factor_required': true,
    });

    expect(response.twoFactorRequired, isTrue);
    expect(response.token, isNull);
  });
}
