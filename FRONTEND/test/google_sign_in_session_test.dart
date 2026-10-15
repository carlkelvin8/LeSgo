import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/di/local_storage_service.dart';
import 'package:lesgo/core/services/favorites_service.dart';
import 'package:lesgo/core/services/notification_service.dart';
import 'package:lesgo/core/services/promo_notification_service.dart';
import 'package:lesgo/core/services/secure_storage_service.dart';
import 'package:lesgo/data/data_source/dto/user/user_profile_dto.dart';
import 'package:lesgo/data/data_source/dto/user/user_response_dto.dart';
import 'package:lesgo/data/data_source/user_remote_datasource.dart';
import 'package:lesgo/domain/repository/user_repository.dart';
import 'package:lesgo/domain/use_cases/login_usecase.dart';
import 'package:lesgo/domain/use_cases/logout_usecase.dart';
import 'package:lesgo/presentation/provider/auth/auth_provider.dart';

class _UnusedRepository implements UserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProfileSource implements UserRemoteDataSource {
  UserResponseDto? response;

  @override
  Future<UserResponseDto> getMe() async {
    if (response != null) return response!;
    throw Exception('Profile endpoint unavailable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notifications implements NotificationService {
  bool failRefresh = false;

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> refreshFromBackend() async {
    if (failRefresh) throw Exception('Notifications unavailable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PromoNotifications implements PromoNotificationService {
  bool failRegistration = false;

  @override
  Future<void> registerDeviceToken({String? token}) async {
    if (failRegistration) throw Exception('FCM unavailable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthNotifier auth;
  late LocalStorageService storage;
  late _ProfileSource source;
  late _Notifications notifications;
  late _PromoNotifications promos;
  const payload = {
    'id': 42,
    'email': 'customer@example.test',
    'name': 'Customer',
    'role': 'customer',
  };

  setUp(() async {
    await getIt.reset();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await SecureStorageService(prefs).initialize();
    storage = LocalStorageService(prefs);
    source = _ProfileSource();
    notifications = _Notifications();
    promos = _PromoNotifications();
    getIt.registerSingleton<UserRemoteDataSource>(source);
    getIt.registerSingleton<FavoritesService>(FavoritesService(prefs));
    getIt.registerSingleton<NotificationService>(notifications);
    getIt.registerSingleton<PromoNotificationService>(promos);
    auth = AuthNotifier(
      LoginUseCase(_UnusedRepository()),
      LogoutUseCase(_UnusedRepository()),
      storage,
    );
  });

  tearDown(() async {
    auth.dispose();
    storage.dispose();
    await getIt.reset();
  });

  test('profile outage uses the authenticated Google response', () async {
    final success = await auth.completeGoogleSignIn(
      token: 'verified-token',
      refreshToken: 'refresh-token',
      profilePayload: payload,
    );
    expect(success, isTrue);
    expect(auth.state.user?.id, '42');
    expect(storage.token, 'verified-token');
    expect(storage.refreshToken, 'refresh-token');
  });

  test(
    'a successful profile sync takes precedence over the fallback',
    () async {
      source.response = UserResponseDto(
        success: true,
        data: UserProfileDto(
          id: 99,
          name: 'Current profile',
          email: 'current@example.test',
          role: 'customer',
        ),
      );
      expect(
        await auth.completeGoogleSignIn(
          token: 'verified-token',
          profilePayload: payload,
        ),
        isTrue,
      );
      expect(auth.state.user?.id, '99');
    },
  );

  test('an incomplete fallback cannot restore a session', () async {
    expect(
      await auth.completeGoogleSignIn(
        token: 'verified-token',
        profilePayload: {'id': 42, 'role': 'customer'},
      ),
      isFalse,
    );
    expect(auth.state.isAuthenticated, isFalse);
    expect(storage.token, isNull);
  });

  test('non-customer Google accounts are rejected', () async {
    expect(
      await auth.completeGoogleSignIn(
        token: 'verified-token',
        profilePayload: {...payload, 'role': 'driver'},
      ),
      isFalse,
    );
    expect(auth.state.isAuthenticated, isFalse);
    expect(storage.token, isNull);
  });

  test('FCM registration failure keeps the authenticated session', () async {
    promos.failRegistration = true;
    expect(
      await auth.completeGoogleSignIn(
        token: 'verified-token',
        profilePayload: payload,
      ),
      isTrue,
    );
    expect(auth.state.isAuthenticated, isTrue);
    expect(storage.token, 'verified-token');
  });

  test('notification sync failure keeps the authenticated session', () async {
    notifications.failRefresh = true;
    expect(
      await auth.completeGoogleSignIn(
        token: 'verified-token',
        profilePayload: payload,
      ),
      isTrue,
    );
    expect(auth.state.isAuthenticated, isTrue);
    expect(storage.token, 'verified-token');
  });
}
