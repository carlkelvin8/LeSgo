import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lezgo_rider/core/constants/routers/main/main_routes.dart';
import 'package:lezgo_rider/core/di/injection.dart';
import 'package:lezgo_rider/core/network/auth_token_interceptor.dart';
import 'package:lezgo_rider/core/network/dio_client.dart';
import 'package:lezgo_rider/core/network/token_refresh_service.dart';
import 'package:lezgo_rider/core/services/remember_me_service.dart';
import 'package:lezgo_rider/core/services/secure_storage_service.dart';
import 'package:lezgo_rider/core/utils/api_error_mapper.dart';
import 'package:lezgo_rider/core/utils/validators/login_validator.dart';
import 'package:lezgo_rider/data/data_source/auth_remote_datasource.dart';
import 'package:lezgo_rider/presentation/provider/auth/forgot_password_provider.dart';
import 'package:lezgo_rider/presentation/provider/auth/rider_auth_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_duty_provider.dart';
import 'package:lezgo_rider/presentation/provider/register/riderside/rider_phone_verification_provider.dart';
import 'package:lezgo_rider/presentation/screens/auth/auth_startup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Client implements DioClient {
  _Client(this.dio);
  @override
  final Dio dio;
  @override
  void initialize() {}
}

/// Answers every request with [handler]'s response.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final ResponseBody Function(RequestOptions) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, dynamic> _loginOk({String role = 'driver'}) => {
  'success': true,
  'token': 'tok',
  'refresh_token': 'ref',
  'expires_in': 3600,
  'user': {
    'id': 5,
    'name': 'R',
    'email': 'r@example.test',
    'role': role,
    'driver_profile': {'id': 9},
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    RememberMeService.resetForTests();
    await RememberMeService.init();
    dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    if (getIt.isRegistered<DioClient>()) await getIt.reset();
    getIt.registerSingleton<DioClient>(_Client(dio));
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('LoginValidator', () {
    test('accepts valid emails the old regex rejected', () {
      for (final e in [
        'tester+rider@gmail.com',
        'a@mail.company',
        'first.last@sub.example.photography',
        '  rider@gmail.com ',
      ]) {
        expect(LoginValidator.email(e), isNull, reason: e);
        expect(LoginValidator.emailOrPhone(e), isNull, reason: e);
      }
    });

    test('still rejects garbage and phone numbers for email()', () {
      expect(LoginValidator.email('not-an-email'), isNotNull);
      expect(LoginValidator.email('09171234567'), isNotNull);
      expect(LoginValidator.email('  '), isNotNull);
    });

    test('login password only needs to be non-empty', () {
      expect(LoginValidator.loginPassword('abc'), isNull);
      expect(LoginValidator.loginPassword(''), isNotNull);
    });
  });

  group('login 2FA', () {
    test('202 two_factor_required is surfaced instead of a generic error',
        () async {
      dio.httpClientAdapter = _Adapter(
        (_) => _json(202, {
          'success': false,
          'message': 'Enter the code from Google Authenticator to continue.',
          'two_factor_required': true,
        }),
      );
      final auth = RiderAuthNotifier();
      final ok = await auth.login(
        'r@example.test',
        'pw',
        rememberMe: false,
        accountType: 'rider',
      );
      expect(ok, isFalse);
      expect(auth.state.twoFactorRequired, isTrue);
      expect(auth.state.error, contains('Google Authenticator'));
      expect(auth.state.error, isNot('Invalid response from server'));
    });

    test('retry with a code sends two_factor_code and signs in', () async {
      final adapter = _Adapter((o) {
        final body = o.data as Map;
        if (body['two_factor_code'] == '123456') return _json(200, _loginOk());
        return _json(202, {
          'two_factor_required': true,
          'message': 'code needed',
        });
      });
      dio.httpClientAdapter = adapter;
      final auth = RiderAuthNotifier();
      await auth.login('r@example.test', 'pw',
          rememberMe: false, accountType: 'rider');
      final ok = await auth.login('r@example.test', 'pw',
          rememberMe: false,
          accountType: 'rider',
          twoFactorCode: '123456');
      expect(ok, isTrue);
      expect(auth.state.isLoggedIn, isTrue);
      expect(auth.state.twoFactorRequired, isFalse);
      expect(auth.state.user!.driverProfileId, 9);
    });

    test('wrong code (422) keeps asking and shows the API message', () async {
      dio.httpClientAdapter = _Adapter(
        (_) => _json(422, {
          'success': false,
          'message': 'The authenticator or backup code is invalid.',
          'two_factor_required': true,
        }),
      );
      final auth = RiderAuthNotifier();
      final ok = await auth.login('r@example.test', 'pw',
          rememberMe: false, accountType: 'rider', twoFactorCode: '000000');
      expect(ok, isFalse);
      expect(auth.state.twoFactorRequired, isTrue);
      expect(auth.state.error, contains('invalid'));
    });

    test('string expires_in does not break an otherwise valid login',
        () async {
      final body = _loginOk()..['expires_in'] = '3600';
      dio.httpClientAdapter = _Adapter((_) => _json(200, body));
      final auth = RiderAuthNotifier();
      final ok = await auth.login('r@example.test', 'pw',
          rememberMe: false, accountType: 'rider');
      expect(ok, isTrue);
    });
  });

  group('429 / error messaging', () {
    test('429 without a JSON message still reads as rate limiting', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/v1/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/v1/auth/login'),
          statusCode: 429,
          data: '<html>Too Many</html>' * 20,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(ApiErrorMapper.message(err), contains('Too many attempts'));
    });

    test('login 429 shows the API message', () async {
      dio.httpClientAdapter = _Adapter(
        (_) => _json(429, {
          'success': false,
          'message': 'Too many login attempts. Please try again in a few minutes.',
        }),
      );
      final auth = RiderAuthNotifier();
      await auth.login('r@example.test', 'pw',
          rememberMe: false, accountType: 'rider');
      expect(auth.state.error, contains('Too many login attempts'));
    });

    test('forgot-password errors are readable, not raw DioException text',
        () async {
      dio.httpClientAdapter = _Adapter(
        (_) => _json(429, {'message': 'Too many requests. Please slow down.'}),
      );
      final n = ForgotPasswordNotifier(AuthRemoteDataSource(_Client(dio)));
      expect(await n.sendOtp('a@b.co'), isFalse);
      expect(n.state.errorMessage, 'Too many requests. Please slow down.');
      expect(n.state.errorMessage, isNot(contains('DioException')));
    });

    test('forgot-password offline error is readable', () async {
      dio.httpClientAdapter = _Adapter((o) => throw DioException(
            requestOptions: o,
            type: DioExceptionType.connectionError,
          ));
      final n = ForgotPasswordNotifier(AuthRemoteDataSource(_Client(dio)));
      expect(await n.sendOtp('a@b.co'), isFalse);
      expect(n.state.errorMessage, isNot(contains('DioException')));
      expect(n.state.errorMessage, contains('Cannot reach'));
    });
  });

  group('phone OTP', () {
    test('HTML error body (proxy/502) does not crash or leave spinner on',
        () async {
      dio.httpClientAdapter = _Adapter(
        (_) => ResponseBody.fromString('<html>Bad gateway</html>', 502),
      );
      getIt.registerSingleton<AuthRemoteDataSource>(
        AuthRemoteDataSource(_Client(dio)),
      );
      final n = PhoneVerificationNotifier();
      n.updatePhoneNumber('09171234567');
      await n.sendOTP();
      expect(n.state.isLoading, isFalse);
      expect(n.state.errorMessage, isNotNull);
      expect(n.state.errorMessage, isNot(contains('DioException')));
      n.updatePhoneNumber('09171234567');
      expect(await n.verifyOTP('123456'), isFalse);
      expect(n.state.isLoading, isFalse);
    });
  });

  group('token refresh', () {
    Future<void> seedSession() => SecureStorageService.saveToken(
      token: 'old',
      expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      refreshToken: 'refresh-1',
    );

    test('429 on refresh keeps the refresh token (no forced logout)',
        () async {
      await seedSession();
      final refreshDio = Dio(BaseOptions(baseUrl: 'http://localhost'))
        ..httpClientAdapter = _Adapter(
          (_) => _json(429, {'message': 'Too many login attempts.'}),
        );
      TokenRefreshService.instance.refreshDioForTest = refreshDio;
      expect(await TokenRefreshService.instance.refreshAccessToken(), isNull);
      expect(TokenRefreshService.instance.lastFailureWasTransient, isTrue);

      // Interceptor path: a 401 whose refresh was throttled must not wipe auth.
      dio.interceptors.add(AuthTokenInterceptor(dio));
      dio.httpClientAdapter = _Adapter((_) => _json(401, {'message': 'x'}));
      await expectLater(
        dio.get('/v1/auth/me'),
        throwsA(isA<DioException>()),
      );
      expect(await SecureStorageService.getRefreshToken(), 'refresh-1');
    });

    test('a rejected refresh token (401) still clears the session', () async {
      await seedSession();
      TokenRefreshService.instance.refreshDioForTest =
          Dio(BaseOptions(baseUrl: 'http://localhost'))
            ..httpClientAdapter = _Adapter(
              (_) => _json(401, {'message': 'Invalid refresh token'}),
            );
      dio.interceptors.add(AuthTokenInterceptor(dio));
      dio.httpClientAdapter = _Adapter((_) => _json(401, {'message': 'x'}));
      await expectLater(
        dio.get('/v1/auth/me'),
        throwsA(isA<DioException>()),
      );
      expect(TokenRefreshService.instance.lastFailureWasTransient, isFalse);
      expect(await SecureStorageService.getRefreshToken(), isNull);
    });
  });

  group('session restore routing', () {
    RiderUser user(String role) =>
        RiderUser(id: 1, name: 'n', email: 'e@x.co', role: role);

    test('partner staff go to the merchant shell like a fresh login', () {
      expect(startupRouteFor(user('partner_staff')), MainRoutes.merchantMain);
      expect(startupRouteFor(user('partner_admin')), MainRoutes.merchantMain);
      expect(startupRouteFor(user('driver')), MainRoutes.riderMain);
      expect(startupRouteFor(null), MainRoutes.riderMain);
    });
  });

  group('PartnerStaffInfo parsing', () {
    test('map-shaped permissions or 0/1 flags do not throw at login', () {
      final info = PartnerStaffInfo.fromJson({
        'staff': {
          'id': '4',
          'role': 'cook',
          'permissions': {'menu': true},
          'is_active': 1,
        },
      });
      expect(info, isNotNull);
      expect(info!.id, 4);
      expect(info.permissions, isNull);
      expect(info.isActive, isTrue);
    });
  });

  group('duty attendance', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          riderAuthProvider.overrideWith((ref) {
            final n = RiderAuthNotifier();
            n.state = RiderAuthState(
              isLoggedIn: true,
              user: RiderUser(
                id: 7,
                name: 'R',
                email: 'r@example.test',
                role: 'driver',
                driverProfileId: 10,
              ),
            );
            return n;
          }),
        ],
      );
    });
    tearDown(() => container.dispose());

    XFile photo() => XFile.fromData(
      Uint8List.fromList([1, 2, 3]),
      name: 'duty.jpg',
      mimeType: 'image/jpeg',
    );

    test('posts multipart `photo` to the duty-attendance route', () async {
      final adapter = _Adapter((_) => _json(200, {'data': {'id': 1}}));
      dio.httpClientAdapter = adapter;
      final err = await container
          .read(riderDutyProvider.notifier)
          .goOnDutyWithPhoto(photo());
      expect(err, isNull);
      final first = adapter.requests.first;
      expect(first.path, '/v1/drivers/10/duty-attendance');
      final form = first.data as FormData;
      expect(form.files.map((f) => f.key), contains('photo'));
    });

    test('unapproved account gets the under-review message', () async {
      dio.httpClientAdapter = _Adapter(
        (_) => _json(403, {
          'success': false,
          'error_code': 'REGISTRATION_NOT_ACTIVE',
          'message': 'Restricted',
        }),
      );
      final err = await container
          .read(riderDutyProvider.notifier)
          .goOnDutyWithPhoto(photo());
      expect(err, contains('under review'));
    });

    test('availability sync failure is readable, not raw exception text',
        () async {
      dio.httpClientAdapter = _Adapter((o) {
        if (o.path.contains('duty-attendance')) return _json(200, {'data': {}});
        return _json(403, {
          'error_code': 'REGISTRATION_NOT_ACTIVE',
          'message': 'Restricted',
        });
      });
      final err = await container
          .read(riderDutyProvider.notifier)
          .goOnDutyWithPhoto(photo());
      expect(err, isNotNull);
      expect(err, isNot(contains('DioException')));
      expect(err, isNot(contains('Failed to sync driver availability')));
    });
  });
}
