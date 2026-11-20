// Shared helpers for the merchant integration tests that run against the LOCAL
// throwaway Laravel API (see merchant_order_flow_test.dart for how to run).
//
// The customer and the driver are simulated through the REST API; the merchant
// is always driven through the real UI with a WidgetTester.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/constants/api_constants.dart';
import 'package:lezgo_rider/core/services/remember_me_service.dart';
import 'package:lezgo_rider/core/services/secure_storage_service.dart';
import 'package:lezgo_rider/main.dart' as app;
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_main_screen.dart';
import 'package:lezgo_rider/presentation/widgets/main/merchantside/merchant_bottom_nav_bar.dart';

const kMerchantEmail = String.fromEnvironment(
  'LES_GO_TEST_MERCHANT_EMAIL',
  defaultValue: 'merchant@test.com',
);
const kMerchantPassword = String.fromEnvironment(
  'LES_GO_TEST_MERCHANT_PASSWORD',
  defaultValue: 'Password123!',
);
const kCustomerEmail = 'customer@lesgo.test';
const kCustomerPassword = 'password';
const kRiderEmail = 'testrider@lesgo.com';
const kRiderPassword = 'TestRider123!';

/// Throwaway-account password (bcrypt hash below is for exactly this string).
const kThrowawayPassword = 'Throwaway123!';
const _kThrowawayHash =
    r'$2y$10$pZLO/KAgGI/M8iy0slPzFufsFi5tb6sUrY8umeDBG7mpzxzwn6Sce';

/// Sidecar that runs whitelisted SQL against the local sqlite DB
/// (integration_test/support/local_sqlite_helper.py).
const _kSqlHelper = String.fromEnvironment(
  'LOCAL_SQL_HELPER',
  defaultValue: 'http://127.0.0.1:8002',
);

// 1x1 PNG
const kTinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

void assertLocalBackend() {
  final base = ApiConstants.baseUrl;
  if (!(base.contains('127.0.0.1') || base.contains('localhost'))) {
    throw StateError(
      'These tests create real orders/withdrawals and delete accounts. '
      'They only run against a LOCAL API, got $base',
    );
  }
}

// ---------------------------------------------------------------------------
// REST helpers (customer / driver simulation + assertions)
// ---------------------------------------------------------------------------

class ApiResult {
  ApiResult(this.status, this.body);
  final int status;
  final dynamic body;

  bool get ok => status >= 200 && status < 300;
  Map<String, dynamic> get json =>
      body is Map ? Map<String, dynamic>.from(body as Map) : {};
  dynamic get data => json['data'];
  Map<String, dynamic> get dataMap =>
      data is Map ? Map<String, dynamic>.from(data as Map) : {};
  String get message => '${json['message'] ?? ''}';

  @override
  String toString() => 'HTTP $status ${jsonEncode(body)}';
}

final Dio _dio = Dio(
  BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    validateStatus: (_) => true,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json'},
  ),
);

Future<ApiResult> api(
  String method,
  String path, {
  String? token,
  Object? data,
  Map<String, dynamic>? query,
}) async {
  final response = await _dio.request<dynamic>(
    path,
    data: data,
    queryParameters: query,
    options: Options(
      method: method,
      headers: token == null ? null : {'Authorization': 'Bearer $token'},
    ),
  );
  return ApiResult(response.statusCode ?? 0, response.data);
}

Future<String> apiLogin(String email, String password) async {
  final r = await api(
    'POST',
    '/v1/auth/login',
    data: {'email': email, 'password': password},
  );
  final token = r.json['token'];
  if (token is! String) throw StateError('Login failed for $email: $r');
  return token;
}

Future<List<dynamic>> localSql(String sql, [List<Object?> params = const []]) async {
  final response = await Dio().post<dynamic>(
    _kSqlHelper,
    data: {'sql': sql, 'params': params},
    options: Options(
      validateStatus: (_) => true,
      contentType: Headers.jsonContentType,
    ),
  );
  if (response.statusCode != 200) {
    throw StateError('SQL helper failed: ${response.data} ($sql)');
  }
  return (response.data as Map)['rows'] as List<dynamic>;
}

/// Idempotent fixtures: merchant + rider fee paid, rider on duty, store open.
Future<void> ensureLocalFixtures() async {
  assertLocalBackend();
  await localSql(
    "update registration_fee_payments set payment_status='paid', "
    "payment_date=datetime('now'), approved_at=datetime('now'), "
    "activated_at=datetime('now'), is_active=1, application_status='approved' "
    'where user_id in (select id from users where email in (?, ?))',
    [kMerchantEmail, kRiderEmail],
  );
  // Leftovers of an aborted earlier run would keep the rider busy.
  await localSql(
    "update orders set status='cancelled', cancel_reason='e2e cleanup' "
    "where partner_id=1 and status not in ('completed', 'cancelled')",
  );
  await localSql('update driver_profiles set is_available=1 where user_id=3');
  await localSql('update partners set is_open=1 where id=1');
}

/// Creates a throwaway merchant (user + active partner + paid registration fee)
/// directly in the local DB and returns its email.
Future<String> createThrowawayMerchant(String tag) async {
  assertLocalBackend();
  final email = 'throwaway.$tag.${DateTime.now().millisecondsSinceEpoch}@test.com';
  await localSql(
    "insert into users (name, email, phone_number, role, email_verified_at, "
    "password, referral_code, points, is_active, created_at, updated_at) "
    "values (?, ?, ?, 'partner_admin', datetime('now'), ?, ?, 0, 1, "
    "datetime('now'), datetime('now'))",
    [
      'Throwaway Merchant',
      email,
      '+63917${DateTime.now().millisecondsSinceEpoch % 10000000}',
      _kThrowawayHash,
      'TW${DateTime.now().millisecondsSinceEpoch % 1000000}',
    ],
  );
  final userId =
      (await localSql('select id from users where email=?', [email])).first[0];
  await localSql(
    "insert into partners (user_id, name, slug, status, category, is_open, "
    "created_at, updated_at) values (?, ?, ?, 'active', 'restaurant', 1, "
    "datetime('now'), datetime('now'))",
    [userId, 'Throwaway Store $tag', 'throwaway-store-$tag-$userId'],
  );
  await localSql(
    "insert into registration_fee_payments (user_id, account_type, amount, "
    "currency, idempotency_key, payment_status, payment_date, "
    "application_status, approved_at, activated_at, is_active, "
    "is_grandfathered, created_at, updated_at) values (?, 'merchant', 1000, "
    "'PHP', ?, 'paid', datetime('now'), 'approved', datetime('now'), "
    "datetime('now'), 1, 0, datetime('now'), datetime('now'))",
    [userId, 'reg-fee-$userId-throwaway'],
  );
  return email;
}

// ---------------------------------------------------------------------------
// Order simulation
// ---------------------------------------------------------------------------

class TestActors {
  TestActors(this.customer, this.merchant, this.rider);
  final String customer;
  final String merchant;
  final String rider;

  static Future<TestActors> login() async => TestActors(
    await apiLogin(kCustomerEmail, kCustomerPassword),
    await apiLogin(kMerchantEmail, kMerchantPassword),
    await apiLogin(kRiderEmail, kRiderPassword),
  );
}

Map<String, dynamic> orderBody({
  String paymentMethod = 'cash',
  int quantity = 2,
  String? note,
}) => {
  'service_id': 3,
  'partner_id': 1,
  'payment_method': paymentMethod,
  'pickup': {
    'address': 'LesGo Test Store, Tuguegarao',
    'lat': 18.5187555,
    'lng': 120.9991032,
  },
  'dropoff': {
    'address': 'Customer Home, Tuguegarao',
    'lat': 18.5250,
    'lng': 121.0050,
    'contact_name': 'E2E Customer',
    'contact_phone': '09170000001',
  },
  'items': [
    {
      'name': 'Test Burger',
      'quantity': quantity,
      'menu_item_id': 1,
      'source': 'store',
      'estimated_price': 150,
    },
  ],
  'meta': {'order_value': 150 * quantity},
  if (note != null) 'notes': note,
};

Future<ApiResult> customerCreateOrder(
  String customerToken, {
  String paymentMethod = 'cash',
  int quantity = 2,
}) => api(
  'POST',
  '/v1/orders',
  token: customerToken,
  data: orderBody(paymentMethod: paymentMethod, quantity: quantity),
);

Future<Map<String, dynamic>> fetchOrder(String token, int id) async {
  final r = await api('GET', '/v1/orders/$id', token: token);
  if (!r.ok) throw StateError('GET order $id failed: $r');
  return r.dataMap;
}

Future<ApiResult> setStatus(
  String token,
  int orderId,
  String status, {
  String? reason,
}) => api(
  'PATCH',
  '/v1/orders/$orderId/status',
  token: token,
  data: {'status': status, if (reason != null) 'cancel_reason': reason},
);

/// Rider accepts, picks up, "uploads" proof (DB, because the local API has no
/// object storage) and completes. Each step is asserted.
Future<void> driverAccept(String riderToken, int orderId) async {
  final r = await setStatus(riderToken, orderId, 'accepted');
  expect(r.ok, isTrue, reason: 'driver accept failed: $r');
}

Future<void> driverPickUp(String riderToken, int orderId) async {
  final r = await setStatus(riderToken, orderId, 'picked_up');
  expect(r.ok, isTrue, reason: 'driver pickup failed: $r');
}

Future<void> driverComplete(String riderToken, int orderId) async {
  await localSql(
    'update orders set proof_images=? where id=?',
    [jsonEncode(['proof_images/$orderId/e2e.png']), orderId],
  );
  final r = await setStatus(riderToken, orderId, 'completed');
  expect(r.ok, isTrue, reason: 'driver complete failed: $r');
}

double num_(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

// ---------------------------------------------------------------------------
// UI helpers
// ---------------------------------------------------------------------------

Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 160,
  String? reason,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Timed out waiting for ${reason ?? finder.toString()}');
}

Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 160,
  String? reason,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isEmpty) return;
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Timed out waiting for ${reason ?? finder.toString()} to go away');
}

Future<void> pumpFor(WidgetTester tester, int milliseconds) async {
  for (var i = 0; i < milliseconds ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void expectNoFrameworkErrors(WidgetTester tester, String where) {
  final e = tester.takeException();
  if (e != null) fail('Framework exception at $where: $e');
}

/// Boots the app logged out and opens the merchant login form (or, with
/// [register], the Merchant/Rider registration chooser) without submitting.
Future<void> openMerchantAuth(
  WidgetTester tester, {
  bool register = false,
}) async {
  await RememberMeService.init();
  await RememberMeService.clearSession();
  await SecureStorageService.clearAll();
  await app.main();
  final entry = find.text(register ? 'Register' : 'Login');
  await pumpUntil(tester, entry, reason: 'welcome screen');
  await tester.tap(entry.first);
  await tester.pumpAndSettle();
  if (register) return;
  final merchantButton = find.text('Merchant');
  await pumpUntil(tester, merchantButton, reason: 'Merchant role button');
  await tester.tap(merchantButton.first);
  await tester.pumpAndSettle();
  await pumpUntil(
    tester,
    find.byKey(const ValueKey('merchant_login_form')),
    reason: 'merchant login form',
  );
}

/// Opens the merchant login form and submits the credentials. Does not wait
/// for any landing screen.
Future<void> submitLogin(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await openMerchantAuth(tester);
  final form = find.byKey(const ValueKey('merchant_login_form'));
  final fields = find.descendant(
    of: form,
    matching: find.byType(TextFormField),
  );
  expect(fields, findsNWidgets(2));
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final submit = find.text('Log In');
  await tester.ensureVisible(submit);
  await tester.pumpAndSettle();
  await tester.tap(submit);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> signInMerchant(
  WidgetTester tester, {
  String email = kMerchantEmail,
  String password = kMerchantPassword,
}) async {
  await submitLogin(tester, email: email, password: password);
  await pumpUntil(
    tester,
    find.byType(MerchantMainScreen),
    maxPumps: 240,
    reason: 'MerchantMainScreen after login',
  );
  await pumpFor(tester, 2000);
  expectNoFrameworkErrors(tester, 'merchant sign-in');
}

Future<void> tapMerchantTab(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(MerchantBottomNavBar),
    matching: find.text(label),
  );
  expect(tab, findsWidgets, reason: 'Missing merchant tab: $label');
  // The nav bar renders each label more than once (animated copies); only the
  // hit-testable one is the real button. Tapping `.last` sometimes hit a
  // different tab (e.g. Menu instead of Orders).
  final tappable = tab.hitTestable();
  await tester.tap(
    tappable.evaluate().isNotEmpty ? tappable.first : tab.first,
    warnIfMissed: false,
  );
  await pumpFor(tester, 800);
  expectNoFrameworkErrors(tester, 'tab $label');
}

/// Enters [text] into the TextField/TextFormField that has [label]/[hint].
Finder fieldWith(String text) => find.byWidgetPredicate((w) {
  if (w is TextField) {
    final d = w.decoration;
    return d?.hintText == text || d?.labelText == text;
  }
  return false;
}, description: 'TextField "$text"');

/// True if a SnackBar shows up within [ms] (they disappear after ~1.5-4 s, so
/// check right after the action instead of after a long pump).
Future<bool> sawSnackBar(WidgetTester tester, {int ms = 4000}) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    if (find.byType(SnackBar).evaluate().isNotEmpty) return true;
    await tester.pump(const Duration(milliseconds: 100));
  }
  return false;
}

/// Every Text/RichText string currently in the tree (debug aid for failures).
List<String> allTexts() => [
  ...find.byType(Text).evaluate().map((e) => (e.widget as Text).data),
  ...find.byType(RichText).evaluate().map((e) => (e.widget as RichText).text.toPlainText()),
].whereType<String>().take(120).toList();

/// Taps [finder] once it is actually hit-testable (right after navigation the
/// page can still be animating or ignoring pointers).
Future<void> tapWhenHittable(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20; i++) {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder.first);
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.hitTestable().evaluate().isNotEmpty) {
        await tester.tap(finder.hitTestable().first);
        return;
      }
    }
    await tester.pump(const Duration(milliseconds: 500));
  }
  fail('$finder never became tappable');
}

/// enterText is unreliable once a field has been typed into and unfocused in
/// the same test (the new text is silently dropped). Type normally, and if the
/// controller did not take it, set it directly and fire onChanged.
Future<void> enterTextReliably(
  WidgetTester tester,
  Finder fieldFinder,
  String text,
) async {
  final field = tester.widget<TextField>(fieldFinder.first);
  try {
    await tester.enterText(fieldFinder.first, text);
    await tester.pump(const Duration(milliseconds: 200));
  } catch (_) {}
  if (field.controller != null && field.controller!.text != text) {
    field.controller!.text = text;
    field.onChanged?.call(text);
    await tester.pump(const Duration(milliseconds: 200));
  }
}
