import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lezgo_rider/core/di/injection.dart';
import 'package:lezgo_rider/core/network/dio_client.dart';
import 'package:lezgo_rider/presentation/provider/auth/rider_auth_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_duty_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_location_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_orders_provider.dart';

class Client implements DioClient {
  @override
  final Dio dio;
  Client(this.dio);
  @override
  void initialize() {}
}

class Auth extends RiderAuthNotifier {
  Auth() {
    loginAs(7);
  }

  /// Fresh login/account switch. riderDutyProvider watches auth.user.id, so
  /// this rebuilds the duty notifier (dropping its onDutyChanged callback).
  void loginAs(int id, {int driverProfileId = 10}) {
    state = RiderAuthState(
      isLoggedIn: true,
      user: RiderUser(
        id: id,
        name: 'Rider',
        email: 'rider$id@example.test',
        role: 'driver',
        driverProfileId: driverProfileId,
      ),
    );
  }
}

/// Minimal WidgetRef backed by a ProviderContainer, enough for
/// RiderAuthNotifier.logout().
class RefStub implements WidgetRef {
  RefStub(this.container);
  final ProviderContainer container;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final arg = invocation.positionalArguments.first;
    switch (invocation.memberName) {
      case #read:
        return container.read(arg as ProviderListenable);
      case #invalidate:
        container.invalidate(arg as ProviderOrFamily);
        return null;
      default:
        return super.noSuchMethod(invocation);
    }
  }
}

class Location extends StateNotifier<RiderLocationState>
    implements RiderLocationNotifier {
  Location() : super(const RiderLocationState());
  int starts = 0;
  int stops = 0;
  @override
  Future<void> startTracking({int? orderId}) async {
    starts++;
  }

  @override
  Future<void> stopTracking() async {
    stops++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late Location location;
  late ProviderContainer container;
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'rider_on_duty': true,
      'rider_on_duty_99': true,
    });
    dio = Dio();
    getIt.registerSingleton<DioClient>(Client(dio));
    location = Location();
    container = ProviderContainer(
      overrides: [
        riderAuthProvider.overrideWith((ref) => Auth()),
        riderLocationProvider.overrideWith((ref) => location),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await getIt.reset();
  });

  test(
    'failed availability update leaves rider offline without tracking or saved duty',
    () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            handler.reject(
              DioException(
                requestOptions: request,
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );
      final duty = container.read(riderDutyProvider.notifier);
      expect(await duty.setOnDuty(true), isNotNull);
      expect(container.read(riderDutyProvider), isFalse);
      expect(location.starts, 0);
      expect(
        (await SharedPreferences.getInstance()).getBool('rider_on_duty_7'),
        isNot(true),
      );
    },
  );

  test(
    'failed off-duty request keeps confirmed duty and location tracking',
    () async {
      var fail = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            if (fail) {
              handler.reject(
                DioException(
                  requestOptions: request,
                  type: DioExceptionType.connectionError,
                ),
              );
            } else {
              handler.resolve(
                Response(requestOptions: request, data: {'success': true}),
              );
            }
          },
        ),
      );
      final duty = container.read(riderDutyProvider.notifier);
      expect(await duty.setOnDuty(true), isNull);
      fail = true;
      expect(await duty.setOnDuty(false), isNotNull);
      expect(container.read(riderDutyProvider), isTrue);
      expect(location.stops, 0);
      expect(
        (await SharedPreferences.getInstance()).getBool('rider_on_duty_7'),
        isTrue,
      );
    },
  );

  test(
    'does not inherit another account duty and waits for server confirmation',
    () async {
      final pending = Completer<void>();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            await pending.future;
            handler.resolve(
              Response(requestOptions: request, data: {'success': true}),
            );
          },
        ),
      );
      final duty = container.read(riderDutyProvider.notifier);
      final result = duty.setOnDuty(true);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(riderDutyProvider), isFalse);
      expect(location.starts, 0);
      expect(await duty.setOnDuty(true), isNotNull);
      pending.complete();
      expect(await result, isNull);
      expect(container.read(riderDutyProvider), isTrue);
      expect(location.starts, 1);
    },
  );

  test(
    'going on duty after a re-login still resumes order polling',
    () async {
      final requested = <String>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requested.add(request.path);
            handler.resolve(
              Response(
                requestOptions: request,
                data: {'success': true, 'data': []},
              ),
            );
          },
        ),
      );

      // Builds the orders notifier, which registers onDutyChanged.
      container.read(riderOrdersProvider.notifier);

      // Logout -> login rebuilds riderDutyProvider with a fresh notifier.
      final auth = container.read(riderAuthProvider.notifier) as Auth;
      auth.loginAs(8, driverProfileId: 11);
      await Future<void>.delayed(Duration.zero);

      final duty = container.read(riderDutyProvider.notifier);
      expect(await duty.setOnDuty(true), isNull);
      expect(container.read(riderDutyProvider), isTrue);
      expect(location.starts, 1);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        requested.where((path) => path.startsWith('/v1/orders')).toList(),
        isNotEmpty,
        reason: 'the re-created duty notifier must keep resuming order polling',
      );
    },
  );

  test(
    'logout goes off duty and stops location tracking',
    () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            handler.resolve(
              Response(requestOptions: request, data: {'success': true}),
            );
          },
        ),
      );

      container.read(riderOrdersProvider.notifier);
      final duty = container.read(riderDutyProvider.notifier);
      expect(await duty.setOnDuty(true), isNull);
      expect(location.starts, 1);
      expect(location.stops, 0);

      final target = await container
          .read(riderAuthProvider.notifier)
          .logout(RefStub(container));

      expect(target, AuthViewTarget.rider);
      expect(
        location.stops,
        greaterThan(0),
        reason: 'tracking must stop when the session ends',
      );
      expect(container.read(riderDutyProvider), isFalse);
      expect(
        (await SharedPreferences.getInstance()).getBool('rider_on_duty_7'),
        isFalse,
      );
    },
  );
}
