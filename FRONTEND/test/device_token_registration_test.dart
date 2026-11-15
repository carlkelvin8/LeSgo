import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/services/app_preferences_service.dart';
import 'package:lesgo/core/services/fcm_service.dart';
import 'package:lesgo/core/services/notification_service.dart';
import 'package:lesgo/core/services/promo_notification_service.dart';
import 'package:lesgo/data/data_source/device_remote_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ReadyFcm extends FcmService {
  @override
  String? get fcmToken => 'fcm-token-1';

  @override
  bool get isFirebaseReady => true;
}

class _RecordingDevices implements DeviceRemoteDataSource {
  final List<String> registered = [];

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    registered.add(token);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoNotifications implements NotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _RecordingDevices devices;
  late PromoNotificationService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    devices = _RecordingDevices();
    getIt.registerSingleton<AppPreferencesService>(AppPreferencesService(prefs));
    getIt.registerSingleton<DeviceRemoteDataSource>(devices);
    final fcm = _ReadyFcm();
    service = PromoNotificationService(fcm, _NoNotifications(), prefs);
  });

  tearDown(() async {
    await getIt.unregister<DeviceRemoteDataSource>();
    await getIt.unregister<AppPreferencesService>();
  });

  test('does not register the device token while logged out', () async {
    service.hasSession = () => false;

    await service.registerDeviceToken();

    expect(devices.registered, isEmpty);
  });

  test('registers the device token once a user is signed in', () async {
    service.hasSession = () => true;

    await service.registerDeviceToken();

    expect(devices.registered, ['fcm-token-1']);
  });
}
