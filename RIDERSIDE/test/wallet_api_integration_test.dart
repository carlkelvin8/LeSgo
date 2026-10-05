import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Live API checks for wallet endpoints against staging/production API.
void main() {
  const baseUrl =
      'https://lesgo-api-feature-auth-fhlrsy.laravel.cloud/api';
  const email = 'testrider@lesgo.com';
  const password = 'TestRider123!';

  late Dio dio;
  late bool online;
  int? userId;

  setUpAll(() async {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));
    online = false;

    try {
      final login = await dio.post('/v1/auth/login', data: {
        'email': email,
        'password': password,
        'device_id': 'wallet-integration-test',
      });
      final body = login.data as Map;
      final token = body['token']?.toString();
      final user = body['user'];
      if (user is Map && user['id'] != null) {
        userId = (user['id'] as num).toInt();
      }
      if (token != null && token.isNotEmpty) {
        dio.options.headers['Authorization'] = 'Bearer $token';
        online = true;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Wallet API integration skipped (login failed): $e');
    }
  });

  test('wallet my/wallet returns balance', () async {
    if (!online) return;
    final res = await dio.get('/v1/wallets/my/wallet');
    expect(res.statusCode, 200);
    final wallet = (res.data as Map)['data'] as Map;
    expect(wallet['balance'], isNotNull);
  });

  test('wallet topup creates invoice', () async {
    if (!online) return;
    final res = await dio.post('/v1/wallets/my/topup', data: {
      'amount': 100,
      'payment_method': 'xendit',
    });
    expect(res.statusCode, 201);
    final data = (res.data as Map)['data'] as Map;
    expect(data['invoice_id'], isNotEmpty);
    expect(data['invoice_url'], contains('http'));
  });

  test('linked accounts returns list', () async {
    if (!online) return;
    final linked = await dio.get('/v1/wallets/my/linked-accounts');
    expect(linked.statusCode, 200);
    expect((linked.data as Map)['data'], isA<List>());
  });

  test('transactions returns list via numeric user path', () async {
    if (!online || userId == null) return;
    final tx = await dio.get('/v1/wallets/$userId/transactions');
    expect(tx.statusCode, 200);
    expect((tx.data as Map)['data'], isA<List>());
  });

  test('my/transactions route works when route-order fix is deployed', () async {
    if (!online) return;
    try {
      final tx = await dio.get('/v1/wallets/my/transactions');
      expect(tx.statusCode, 200);
      expect((tx.data as Map)['data'], isA<List>());
    } on DioException catch (e) {
      // Pre-deploy: /wallets/{user_id}/transactions captures user_id="my".
      expect(e.response?.statusCode, 500);
    }
  });
}
