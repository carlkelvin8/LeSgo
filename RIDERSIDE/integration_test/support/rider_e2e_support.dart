// Shared helpers for the rider end-to-end integration tests.
//
// The rider side is always driven through the real UI. The CUSTOMER, MERCHANT
// and ADMIN sides (and all assertions on server state) go through the HTTP API
// of the LOCAL throwaway backend (see API_BASE_URL dart-define).
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:lezgo_rider/core/constants/api_constants.dart';
import 'package:lezgo_rider/core/services/remember_me_service.dart';
import 'package:lezgo_rider/core/services/secure_storage_service.dart';
import 'package:lezgo_rider/main.dart' as app;
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_main_screen.dart';
import 'package:lezgo_rider/presentation/widgets/main/riderside/rider_bottom_nav_bar.dart';

const kRiderEmail = String.fromEnvironment('LES_GO_TEST_RIDER_EMAIL');
const kRiderPassword = String.fromEnvironment('LES_GO_TEST_RIDER_PASSWORD');

/// Seeded local accounts (see the task notes). Customer/merchant/admin are only
/// ever used through the API.
const kCustomerEmail = 'customer@lesgo.test';
const kCustomerPassword = 'password';
const kMerchantEmail = 'merchant@test.com';
const kMerchantPassword = 'Password123!';
const kAdminEmail = 'admin@lesgo.test';

/// Refuses to run against anything but the local throwaway API.
void assertLocalApi() {
  // Print the full widget-location report of every Flutter error (the test
  // binding only keeps the one-line summary, which hides where an overflow is).
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    // ignore: avoid_print
    print('FLUTTER_ERROR_DETAIL: ${details.toDiagnosticsNode().toStringDeep()}');
    previous?.call(details);
  };
  final url = ApiConstants.baseUrl;
  expect(
    url.contains('127.0.0.1') || url.contains('localhost'),
    isTrue,
    reason: 'Refusing to run: API_BASE_URL must be the LOCAL backend, got $url',
  );
}

/// A valid 8x8 PNG generated at runtime (zlib + CRC32), used for attendance and
/// proof-of-delivery photos.
final Uint8List kTinyPng = _buildPng();

Uint8List _buildPng() {
  final crcTable = List<int>.generate(256, (n) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    return c;
  });
  int crc(List<int> bytes) {
    var c = 0xFFFFFFFF;
    for (final b in bytes) {
      c = crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
    }
    return c ^ 0xFFFFFFFF;
  }

  List<int> u32(int v) =>
      [(v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255];
  List<int> chunk(String type, List<int> data) {
    final t = type.codeUnits;
    return [...u32(data.length), ...t, ...data, ...u32(crc([...t, ...data]))];
  }

  const w = 8, h = 8;
  final raw = <int>[];
  for (var y = 0; y < h; y++) {
    raw.add(0);
    for (var x = 0; x < w; x++) {
      raw.addAll(const [255, 128, 0]);
    }
  }
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    ...chunk('IHDR', [...u32(w), ...u32(h), 8, 2, 0, 0, 0]),
    ...chunk('IDAT', ZLibEncoder().convert(raw)),
    ...chunk('IEND', const []),
  ]);
}

/// Replaces the native image picker so the camera / gallery "pick" returns a
/// generated PNG instead of opening a native sheet.
class FakeImagePicker extends ImagePickerPlatform {
  int pickCount = 0;

  Future<XFile> _file() async {
    pickCount++;
    final f = File('${Directory.systemTemp.path}/e2e_photo_$pickCount.png');
    await f.writeAsBytes(kTinyPng);
    return XFile(f.path, mimeType: 'image/png', name: 'e2e_photo_$pickCount.png');
  }

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) =>
      _file();

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async =>
      [await _file()];
}

FakeImagePicker installFakeImagePicker() {
  final fake = FakeImagePicker();
  ImagePickerPlatform.instance = fake;
  return fake;
}

class ThrowawayDriver {
  ThrowawayDriver({required this.email, required this.password, required this.phone});
  final String email;
  String password;
  final String phone;
}

/// Thin JSON client for the local backend; never throws on HTTP errors.
class E2eApi {
  E2eApi()
      : _dio = Dio(BaseOptions(
          baseUrl: '${ApiConstants.baseUrl}/v1',
          headers: {'Accept': 'application/json'},
          validateStatus: (_) => true,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 40),
        ));

  final Dio _dio;
  final Map<String, String> _tokens = {};

  Future<String> login(String email, String password) async {
    final res = await _dio.post('/auth/login',
        data: {'email': email, 'password': password});
    final token = (res.data is Map ? res.data['token'] : null) as String?;
    if (token == null) {
      throw StateError('Login failed for $email: ${res.statusCode} ${res.data}');
    }
    _tokens[email] = token;
    return token;
  }

  Future<String> _tok(String email, String password) async =>
      _tokens[email] ?? await login(email, password);

  Future<String> get customer => _tok(kCustomerEmail, kCustomerPassword);
  Future<String> get merchant => _tok(kMerchantEmail, kMerchantPassword);
  Future<String> get rider => _tok(kRiderEmail, kRiderPassword);

  Future<String> get admin => _tok(kAdminEmail, 'admin123');

  Future<Response<dynamic>> call(
    String method,
    String path, {
    String? token,
    Object? data,
    Map<String, dynamic>? query,
  }) =>
      _dio.request(
        path,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        ),
      );

  /// Unwraps `{data: ...}`.
  dynamic body(Response<dynamic> r) =>
      (r.data is Map && (r.data as Map).containsKey('data'))
          ? r.data['data']
          : r.data;

  // ---- customer ----------------------------------------------------------
  Future<int> createOrder({String payment = 'cash', int price = 150}) async {
    final res = await call('POST', '/orders', token: await customer, data: {
      'service_id': 3,
      'partner_id': 1,
      'payment_method': payment,
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
          'quantity': 2,
          'menu_item_id': 1,
          'source': 'store',
          'estimated_price': price,
        }
      ],
      'meta': {'order_value': price * 2},
    });
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw StateError('createOrder failed: ${res.statusCode} ${res.data}');
    }
    return (body(res)['id'] as num).toInt();
  }

  Future<Map<String, dynamic>> order(int id, {String? as}) async {
    final token = as ?? await customer;
    final res = await call('GET', '/orders/$id', token: token);
    expect(res.statusCode, 200, reason: 'GET /orders/$id -> ${res.data}');
    return Map<String, dynamic>.from(body(res) as Map);
  }

  Future<Response<dynamic>> setStatus(int id, String status,
      {required String token, String? reason}) {
    return call('PATCH', '/orders/$id/status', token: token, data: {
      'status': status,
      if (reason != null) 'cancel_reason': reason,
    });
  }

  /// Merchant: pending -> searching_driver -> ready_for_pickup.
  Future<void> merchantMarkReady(int id) async {
    final t = await merchant;
    var r = await setStatus(id, 'searching_driver', token: t);
    expect(r.statusCode, 200, reason: 'searching_driver -> ${r.data}');
    r = await setStatus(id, 'ready_for_pickup', token: t);
    expect(r.statusCode, 200, reason: 'ready_for_pickup -> ${r.data}');
  }

  /// Admin sweep so stale orders from earlier runs cannot pollute the rider's
  /// Bookings list or block "complete your active delivery".
  Future<void> cancelAllOpenOrders() async {
    final t = await admin;
    final res = await call('GET', '/orders',
        token: t, query: {'per_page': 100});
    final list = (body(res) is List) ? body(res) as List : const [];
    for (final o in list) {
      final s = '${o['status']}';
      if (s == 'completed' || s == 'cancelled') continue;
      await setStatus((o['id'] as num).toInt(), 'cancelled',
          token: t, reason: 'e2e cleanup');
    }
  }

  /// Test setup shortcut: the rider accepts an open order through the API.
  Future<void> riderAcceptViaApi(int id) async {
    final r = await setStatus(id, 'accepted', token: await rider);
    expect(r.statusCode, 200, reason: 'rider accept -> ${r.data}');
  }

  /// Test setup shortcut: accepted -> arrived -> picked_up -> proof -> completed,
  /// all through the API as the rider.
  Future<void> riderCompleteViaApi(int id) async {
    final t = await rider;
    for (final s in ['driver_arrived_at_pickup', 'picked_up']) {
      final r = await setStatus(id, s, token: t);
      expect(r.statusCode, 200, reason: '$s -> ${r.data}');
    }
    final form = FormData()
      ..files.add(MapEntry(
          'images[]',
          MultipartFile.fromBytes(kTinyPng,
              filename: 'proof.png',
              contentType: DioMediaType('image', 'png'))));
    final up = await _dio.post('/orders/$id/upload-proof',
        data: form, options: Options(headers: {'Authorization': 'Bearer $t'}));
    expect(up.statusCode, 200, reason: 'upload-proof -> ${up.data}');
    final r = await setStatus(id, 'completed', token: t);
    expect(r.statusCode, 200, reason: 'completed -> ${r.data}');
  }

  /// Multipart body with one PNG under `photo` (attendance upload).
  static FormData photoForm() => FormData.fromMap({
        'photo': MultipartFile.fromBytes(kTinyPng,
            filename: 'attendance.png',
            contentType: DioMediaType('image', 'png')),
      });

  // ---- throwaway driver accounts -----------------------------------------
  /// Registers a brand-new driver through the public API (phone OTP fallback is
  /// enabled on the local server), then has the admin approve + waive the fee so
  /// the account is fully active. Never touches the seeded rider.
  Future<ThrowawayDriver> createThrowawayDriver({String password = 'Throwaway123!'}) async {
    final n = DateTime.now().microsecondsSinceEpoch;
    final suffix = (n % 1000000000).toString().padLeft(9, '0');
    final phone = '+639$suffix';
    final email = 'e2e.driver.$n@lesgo.test';

    final sent = await call('POST', '/auth/otp/send', data: {'phone_number': phone});
    final otp = sent.data is Map ? sent.data['otp'] : null;
    if (otp == null) {
      throw StateError('OTP fallback not enabled on the local API: ${sent.statusCode} ${sent.data}');
    }
    final verified = await call('POST', '/auth/otp/verify',
        data: {'phone_number': phone, 'otp': '$otp'});
    final proof = verified.data is Map ? verified.data['phone_verification_token'] : null;
    if (proof == null) throw StateError('OTP verify failed: ${verified.data}');

    MultipartFile png(String name) => MultipartFile.fromBytes(kTinyPng,
        filename: '$name.png', contentType: DioMediaType('image', 'png'));
    final pdf = MultipartFile.fromBytes(
        Uint8List.fromList('%PDF-1.4\n1 0 obj\n<<>>\nendobj\ntrailer\n<<>>\n%%EOF\n'.codeUnits),
        filename: 'signature.pdf',
        contentType: DioMediaType('application', 'pdf'));
    final form = FormData.fromMap({
      'terms_accepted': '1',
      'phone_verification_token': proof,
      'name': 'E2E Throwaway $suffix',
      'email': email,
      'phone_number': phone,
      'password': password,
      'password_confirmation': password,
      'license_number': 'E2E-$suffix',
      'selfie': png('selfie'),
      'selfie_with_motorcycle': png('selfie_moto'),
      'resume': png('resume'),
      'barangay_clearance': png('brgy'),
      'drivers_license': png('license'),
      'motorcycle_orcr': png('orcr'),
      'scanned_orcr': png('scanned_orcr'),
      'digital_signature': pdf,
    });
    final reg = await _dio.post('/drivers/register', data: form);
    if (reg.statusCode != 200 && reg.statusCode != 201) {
      throw StateError('driver register failed: ${reg.statusCode} ${reg.data}');
    }

    final admin = await this.admin;
    final list = await call('GET', '/admin/registration-fees',
        token: admin, query: {'search': email});
    final d = body(list);
    final payments = d is Map ? d['payments'] : null;
    final rows = (payments is Map ? payments['data'] : (d is Map ? d['data'] : d))
        as List;
    final feeId = (rows.first['id'] as num).toInt();
    await call('POST', '/admin/registration-fees/$feeId/approve', token: admin);
    final waived = await call('POST', '/admin/registration-fees/$feeId/waive',
        token: admin, data: {'reason': 'e2e throwaway'});
    if (waived.statusCode != 200) {
      throw StateError('waive failed: ${waived.statusCode} ${waived.data}');
    }
    return ThrowawayDriver(email: email, password: password, phone: phone);
  }

  // ---- rider (API-side verification only) -------------------------------
  Future<Map<String, dynamic>> riderProfile() async {
    final res = await call('GET', '/drivers/1', token: await rider);
    expect(res.statusCode, 200, reason: '/drivers/1 -> ${res.data}');
    return Map<String, dynamic>.from(body(res) as Map);
  }

  Future<double> walletBalance({String? token}) async {
    final res = await call('GET', '/wallets/my/wallet',
        token: token ?? await rider);
    expect(res.statusCode, 200, reason: 'wallet -> ${res.data}');
    return double.parse('${body(res)['balance']}');
  }

  Future<List<Map<String, dynamic>>> walletTx({String? token}) async {
    final res = await call('GET', '/wallets/my/transactions',
        token: token ?? await rider);
    expect(res.statusCode, 200, reason: 'tx -> ${res.data}');
    final d = body(res);
    return (d is List ? d : const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> earnings(String period) async {
    final res = await call('GET', '/drivers/me/earnings',
        token: await rider, query: {'period': period});
    expect(res.statusCode, 200, reason: 'earnings -> ${res.data}');
    return Map<String, dynamic>.from(body(res) as Map);
  }
}

// ---------------------------------------------------------------------------
// Pump helpers
// ---------------------------------------------------------------------------

Future<void> pumpUntil(WidgetTester t, Finder f,
    {int pumps = 120, String? what}) async {
  for (var i = 0; i < pumps; i++) {
    if (f.evaluate().isNotEmpty) return;
    await t.pump(const Duration(milliseconds: 250));
  }
  fail('Timed out waiting for ${what ?? f.toString()}');
}

Future<void> pumpUntilAny(WidgetTester t, List<Finder> finders,
    {int pumps = 120, String? what}) async {
  for (var i = 0; i < pumps; i++) {
    if (finders.any((f) => f.evaluate().isNotEmpty)) return;
    await t.pump(const Duration(milliseconds: 250));
  }
  fail('Timed out waiting for ${what ?? 'one of $finders'}');
}

Future<void> pumpUntilGone(WidgetTester t, Finder f, {int pumps = 120}) async {
  for (var i = 0; i < pumps; i++) {
    if (f.evaluate().isEmpty) return;
    await t.pump(const Duration(milliseconds: 250));
  }
  fail('Timed out waiting for $f to disappear');
}

Future<void> settle(WidgetTester t, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 250; i++) {
    await t.pump(const Duration(milliseconds: 250));
  }
}

/// Polls an async predicate (server state) while still pumping the UI.
Future<void> pollUntil(WidgetTester t, Future<bool> Function() check,
    {int tries = 40, String what = 'condition'}) async {
  for (var i = 0; i < tries; i++) {
    if (await check()) return;
    await t.pump(const Duration(milliseconds: 500));
  }
  fail('Timed out waiting for $what');
}

void noErrors(WidgetTester t, String where) {
  final e = t.takeException();
  if (e != null) {
    final detail = e is FlutterError ? e.toStringDeep() : '$e';
    fail('Framework exception at $where: $detail');
  }
}

/// Signs in through the real Login -> Rider form.
Future<void> signInRider(WidgetTester t,
    {String? email, String? password, bool expectMain = true}) async {
  await RememberMeService.init();
  await RememberMeService.clearSession();
  await SecureStorageService.clearAll();
  await app.main();
  await pumpUntil(t, find.text('Login'), what: 'Login button');
  await t.tap(find.text('Login').first);
  await t.pumpAndSettle();
  final btn = find.text('Rider');
  await pumpUntil(t, btn, what: 'Rider account type');
  await t.tap(btn.first);
  await t.pumpAndSettle();
  final form = find.byKey(const ValueKey('rider_login_form'));
  await pumpUntil(t, form, what: 'rider login form');
  final fields = find.descendant(of: form, matching: find.byType(TextFormField));
  await t.enterText(fields.at(0), email ?? kRiderEmail);
  await t.enterText(fields.at(1), password ?? kRiderPassword);
  FocusManager.instance.primaryFocus?.unfocus();
  await t.pumpAndSettle();
  await t.tap(find.text('Log In'));
  if (expectMain) {
    await pumpUntil(t, find.byType(RiderMainScreen),
        pumps: 200, what: 'RiderMainScreen');
    await settle(t, 2000);
  }
}

Future<void> tapRiderTab(WidgetTester t, String label) async {
  final tab = find.descendant(
      of: find.byType(RiderBottomNavBar), matching: find.text(label));
  expect(tab, findsWidgets, reason: 'tab $label');
  await t.tap(tab.last, warnIfMissed: false);
  await settle(t, 1000);
  noErrors(t, 'tab $label');
}

/// Prints every visible Text on screen (and the top route's widget types) to
/// make failing UI steps diagnosable from the log.
void dumpScreen(WidgetTester t, String label) {
  final texts = <String>[];
  for (final e in find.byType(Text).evaluate()) {
    final w = e.widget as Text;
    final d = w.data ?? w.textSpan?.toPlainText();
    if (d != null && d.trim().isNotEmpty) texts.add(d.trim().replaceAll('\n', ' '));
  }
  // ignore: avoid_print
  print('--- SCREEN DUMP [$label]: ${texts.take(60).join(' | ')}');
  final sw = find.byType(Switch).evaluate().length;
  // ignore: avoid_print
  print('--- switches=$sw dialogs=${find.byType(Dialog).evaluate().length} '
      'alerts=${find.byType(AlertDialog).evaluate().length}');
}
