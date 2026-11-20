import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/network/auth_token_interceptor.dart';
import 'package:lezgo_rider/core/services/secure_storage_service.dart';

/// Answers 200 only for [validToken]; everything else is a 401.
class _FakeServer implements HttpClientAdapter {
  _FakeServer(this.validToken, {this.holdResponses});

  String validToken;
  final Future<void>? holdResponses;
  final seenTokens = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final header = options.headers['Authorization'] as String?;
    seenTokens.add(header);
    if (holdResponses != null && header == null) await holdResponses;
    final ok = header == 'Bearer $validToken';
    return ResponseBody.fromString(
      jsonEncode(ok ? {'success': true} : {'message': 'Unauthenticated.'}),
      ok ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _saveToken(String token) => SecureStorageService.saveToken(
      token: token,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      refreshToken: 'refresh-$token',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
      'a request that failed with a revoked token is retried with the newer '
      'session instead of logging the user out', () async {
    // The app sent a request with the old token, then a password change saved
    // new tokens and revoked the old one before the 401 came back.
    final server = _FakeServer('new-token');
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = server;
    dio.interceptors.add(AuthTokenInterceptor(dio));

    await _saveToken('new-token');
    final response = await dio.get(
      '/v1/orders',
      options: Options(headers: {'Authorization': 'Bearer old-token'}),
    );

    expect(response.statusCode, 200);
    expect(server.seenTokens.last, 'Bearer new-token');
    expect(await SecureStorageService.getToken(), 'new-token',
        reason: 'the new session must survive the stale 401');
  });

  test('a request sent without a token that 401s later never wipes a newer session',
      () async {
    // Providers keep refetching while logged out. Their requests carry no
    // token; if one of them 401s after the user logged back in (or changed
    // their password), it must not clear the new session.
    final gate = Completer<void>();
    final server = _FakeServer('valid-for-nobody', holdResponses: gate.future);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = server;
    dio.interceptors.add(AuthTokenInterceptor(dio));

    // No session yet: the request goes out without an Authorization header.
    final inFlight = dio.get('/v1/orders');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // The user logs in / changes password while the request is in flight.
    await _saveToken('new-session-token');
    gate.complete();

    await expectLater(inFlight, throwsA(isA<DioException>()));
    expect(await SecureStorageService.getToken(), 'new-session-token',
        reason: 'a 401 for a request that carried no token must not clear '
            'the session saved afterwards');
  });

  test('a rejected current session is still cleared', () async {
    final server = _FakeServer('something-else');
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = server;
    dio.interceptors.add(AuthTokenInterceptor(dio));

    await _saveToken('current-token');
    final request = dio.get(
      '/v1/orders',
      options: Options(extra: {'retriedAfterRefresh': true}),
    );

    await expectLater(request, throwsA(isA<DioException>()));
    expect(await SecureStorageService.getToken(), isNull,
        reason: 'a session the server rejected must be dropped');
  });
}
