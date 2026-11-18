import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lezgo_rider/core/di/injection.dart';
import 'package:lezgo_rider/core/network/dio_client.dart';
import 'package:lezgo_rider/core/services/scheduled_payout_service.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_wallet_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_scheduled_payout_screen.dart';

class _Client implements DioClient {
  _Client(this.dio);
  @override
  final Dio dio;
  @override
  void initialize() {}
}

class _Wallet extends StateNotifier<RiderWalletState>
    implements RiderWalletNotifier {
  _Wallet() : super(const RiderWalletState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> settings({bool enabled = false}) => {
  'enabled': enabled,
  'frequency': 'weekly',
  'weekly_day': 1,
  'monthly_day': 1,
  'time': '09:00',
  'threshold': '500.00',
  'account_provider': null,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  final requests = <RequestOptions>[];
  var failLoad = false;
  var failSave = false;
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'app_language': 'en',
      'rider_payout_frequency': 'daily',
      'rider_payout_account': 'gcash',
    });
    requests.clear();
    failLoad = failSave = false;
    dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          final fail = request.method == 'GET' ? failLoad : failSave;
          if (fail) {
            handler.reject(
              DioException(
                requestOptions: request,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: request,
                  statusCode: 404,
                  data: {'message': 'Not found'},
                ),
              ),
            );
          } else {
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': request.method == 'PUT' ? request.data : settings(),
                },
              ),
            );
          }
        },
      ),
    );
    getIt.registerSingleton<DioClient>(_Client(dio));
  });
  tearDown(() async => getIt.reset());

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [riderWalletProvider.overrideWith((ref) => _Wallet())],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RiderScheduledPayoutScreen(),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  test(
    'server failure never restores another account legacy preferences',
    () async {
      failLoad = true;
      await expectLater(
        ScheduledPayoutService.load(),
        throwsA(isA<DioException>()),
      );
    },
  );

  test('failed save throws instead of reporting local-only success', () async {
    failSave = true;
    await expectLater(
      ScheduledPayoutService.save(const ScheduledPayoutPreferences()),
      throwsA(isA<DioException>()),
    );
  });

  test('malformed server schedule is rejected', () {
    expect(
      () =>
          ScheduledPayoutPreferences.fromJson({...settings(), 'time': '25:00'}),
      throwsFormatException,
    );
    expect(
      () => ScheduledPayoutPreferences.fromJson({
        ...settings(),
        'threshold': 'NaN',
      }),
      throwsFormatException,
    );
  });

  testWidgets('fractional threshold is preserved when settings load', (
    tester,
  ) async {
    dio.interceptors.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: {
                'success': true,
                'data': {...settings(), 'threshold': '500.25'},
              },
            ),
          );
        },
      ),
    );
    await open(tester);
    await tester.scrollUntilVisible(
      find.byType(TextField),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '500.25',
    );
  });

  testWidgets('unsupported server shows retry and disables saving', (
    tester,
  ) async {
    failLoad = true;
    await open(tester);
    expect(find.textContaining('not available on the server'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
      isNull,
    );
    failLoad = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    await tester.scrollUntilVisible(
      find.text('Save Scheduled Payout'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled schedule can be saved without a linked account', (
    tester,
  ) async {
    await open(tester);
    await tester.scrollUntilVisible(
      find.text('Save Scheduled Payout'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save Scheduled Payout'));
    await tester.pumpAndSettle();
    expect(
      requests.where((r) => r.method == 'PUT').single.data['enabled'],
      false,
    );
    expect(find.byType(RiderScheduledPayoutScreen), findsNothing);
  });

  testWidgets('invalid threshold does not submit to API', (tester) async {
    await open(tester);
    await tester.scrollUntilVisible(
      find.byType(TextField),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'NaN');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save Scheduled Payout'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save Scheduled Payout'));
    await tester.pumpAndSettle();
    expect(requests.where((r) => r.method == 'PUT'), isEmpty);
    await tester.scrollUntilVisible(
      find.textContaining('Enter a threshold'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Enter a threshold'), findsOneWidget);
  });
}
