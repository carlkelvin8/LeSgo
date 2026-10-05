import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lesgo/core/services/secure_storage_service.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/constants/routers/auth/auth_routes.dart';
import 'package:lesgo/core/constants/routers/main/main_routes.dart';
import 'package:lesgo/domain/repository/user_repository.dart';
import 'package:lesgo/domain/use_cases/login_usecase.dart';
import 'package:lesgo/domain/use_cases/logout_usecase.dart';
import 'package:lesgo/presentation/provider/auth/auth_provider.dart';
import 'package:lesgo/presentation/screens/auth/auth_startup_screen.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lesgo/core/di/local_storage_service.dart';
import 'package:lesgo/core/services/app_preferences_service.dart';
import 'package:lesgo/core/services/biometric_unlock_service.dart';
import 'package:lesgo/presentation/widgets/auth/biometric_unlock_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lesgo/data/data_source/security_remote_datasource.dart';
import 'package:lesgo/data/data_source/dto/security/security_dto.dart';
import 'package:lesgo/presentation/provider/main/security/security_provider.dart';

class OfflineSecurity implements SecurityRemoteDataSource {
  @override
  Future<SecurityDashboardDto> getSecurityDashboard() async =>
      throw StateError('offline');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class UnusedUserRepository implements UserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StartupAuth extends AuthNotifier {
  StartupAuth(LocalStorageService storage)
    : super(
        LoginUseCase(UnusedUserRepository()),
        LogoutUseCase(UnusedUserRepository()),
        storage,
      );

  int restores = 0;

  @override
  Future<bool> restoreSession() async {
    restores++;
    return true;
  }
}

class DeviceAuth extends LocalAuthentication {
  List<BiometricType> enrolled = [BiometricType.fingerprint];
  final attempts = <Completer<bool>>[];
  AuthenticationOptions? options;

  @override
  Future<bool> get canCheckBiometrics async => true;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => enrolled;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<dynamic> authMessages = const [],
    AuthenticationOptions options = const AuthenticationOptions(),
  }) {
    this.options = options;
    final result = Completer<bool>();
    attempts.add(result);
    return result.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DeviceAuth auth;
  late AppPreferencesService preferences;
  late LocalStorageService storage;
  late BiometricUnlockService service;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      AppPreferencesService.biometricUnlockKey: true,
      LocalStorageService.authTokenKey: 'test-session',
    });
    final prefs = await SharedPreferences.getInstance();
    await SecureStorageService(prefs).initialize();
    auth = DeviceAuth();
    preferences = AppPreferencesService(prefs);
    storage = LocalStorageService(prefs);
    service = BiometricUnlockService(auth, preferences);
  });

  Widget app() => MaterialApp(
    home: BiometricUnlockGate(
      service: service,
      storage: storage,
      onSignInAgain: storage.clearRememberMeSession,
      child: const Scaffold(body: Text('Private account')),
    ),
  );

  test(
    'biometric session restores without Remember me and clears on logout',
    () async {
      expect(storage.isRememberMeEnabled(), isFalse);
      expect(storage.isRememberMeSessionValid(), isFalse);
      expect(storage.canRestoreSession(), isTrue);
      await storage.clearRememberMeSession();
      expect(storage.canRestoreSession(), isFalse);
      expect(preferences.biometricUnlockEnabled, isFalse);
    },
  );

  test('valid token restores an ordinary session without Remember me', () async {
    await preferences.setBiometricUnlockEnabled(false);
    expect(storage.canRestoreSession(), isTrue);
    await storage.secure.setBool(LocalStorageService.rememberMeKey, true);
    await storage.secure.setInt(
      LocalStorageService.rememberMeExpiresKey,
      DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
    );
    expect(storage.canRestoreSession(), isTrue);
    await storage.secure.setInt(LocalStorageService.rememberMeExpiresKey, 0);
    expect(storage.canRestoreSession(), isTrue);
    await preferences.setBiometricUnlockEnabled(true);
    expect(storage.canRestoreSession(), isTrue);
    await storage.secure.remove(LocalStorageService.authTokenKey);
    expect(storage.canRestoreSession(), isFalse);
  });

  for (final biometric in [BiometricType.face, BiometricType.fingerprint]) {
    test(
      'enables $biometric only after device authentication succeeds',
      () async {
        auth.enrolled = [biometric];
        await preferences.setBiometricUnlockEnabled(false);
        final notifier = SecuritySettingsNotifier(
          service,
          dataSource: OfflineSecurity(),
        );
        addTearDown(notifier.dispose);
        await Future<void>.delayed(Duration.zero);
        final enabling = notifier.toggleBiometricUnlock(true);
        await Future<void>.delayed(Duration.zero);
        expect(preferences.biometricUnlockEnabled, isFalse);
        expect(auth.options!.biometricOnly, isTrue);
        auth.attempts.single.complete(true);
        expect(await enabling, isTrue);
        expect(storage.canRestoreSession(), isTrue);
      },
    );
  }

  testWidgets(
    'real startup preserves biometric-only session behind unlock gate',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final startupAuth = StartupAuth(storage);
      getIt.registerSingleton<LocalStorageService>(storage);
      addTearDown(() => getIt.unregister<LocalStorageService>());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith((ref) => startupAuth)],
          child: MaterialApp(
            routes: {
              LoginRoutes.startup: (_) => const AuthStartupScreen(),
              LoginRoutes.login: (_) => const Scaffold(body: Text('Sign in')),
              MainRoutes.home: (_) =>
                  const Scaffold(body: Text('Restored account')),
            },
            builder: (context, child) => BiometricUnlockGate(
              service: service,
              storage: storage,
              onSignInAgain: storage.clearRememberMeSession,
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(startupAuth.restores, 1);
      expect(storage.token, 'test-session');
      expect(preferences.biometricUnlockEnabled, isTrue);
      expect(find.text('Restored account'), findsNothing);
      auth.attempts.single.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('Restored account'), findsNothing);
      await tester.tap(find.text('Unlock'));
      auth.attempts.last.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Restored account'), findsOneWidget);
    },
  );

  test('enrollment requires an enrolled biometric', () async {
    auth.enrolled = [];
    await expectLater(
      service.authenticate(enrolling: true),
      throwsA(isA<PlatformException>()),
    );
    expect(auth.attempts, isEmpty);
    expect(service.isAuthenticating, isFalse);
  });

  test(
    'offline API does not block local enrollment; cancellation preserves setting',
    () async {
      await preferences.setBiometricUnlockEnabled(false);
      final notifier = SecuritySettingsNotifier(
        service,
        dataSource: OfflineSecurity(),
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.deviceSupportsBiometrics, isTrue);
      expect(notifier.state.isLoading, isFalse);
      final enabling = notifier.toggleBiometricUnlock(true);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.isProcessing, isTrue);
      expect(await notifier.toggleBiometricUnlock(true), isFalse);
      auth.attempts.last.complete(false);
      expect(await enabling, isFalse);
      expect(preferences.biometricUnlockEnabled, isFalse);
      final retry = notifier.toggleBiometricUnlock(true);
      await Future<void>.delayed(Duration.zero);
      auth.attempts.last.complete(true);
      expect(await retry, isTrue);
      expect(preferences.biometricUnlockEnabled, isTrue);
      expect(notifier.state.localBiometricEnabled, isTrue);
      expect(notifier.state.isProcessing, isFalse);
      notifier.dispose();
    },
  );

  test('disabling requires successful device authentication', () async {
    final notifier = SecuritySettingsNotifier(
      service,
      dataSource: OfflineSecurity(),
    );
    await Future<void>.delayed(Duration.zero);
    final disabling = notifier.toggleBiometricUnlock(false);
    auth.attempts.last.complete(false);
    expect(await disabling, isFalse);
    expect(preferences.biometricUnlockEnabled, isTrue);
    final retry = notifier.toggleBiometricUnlock(false);
    auth.attempts.last.complete(true);
    expect(await retry, isTrue);
    expect(preferences.biometricUnlockEnabled, isFalse);
    notifier.dispose();
  });

  test(
    'enrollment is biometric-only and concurrent prompts are rejected',
    () async {
      final pending = service.authenticate(enrolling: true);
      await Future<void>.delayed(Duration.zero);
      expect(auth.options!.biometricOnly, isTrue);
      expect(await service.authenticate(), isFalse);
      expect(auth.attempts, hasLength(1));
      auth.attempts.single.complete(true);
      expect(await pending, isTrue);
      expect(service.isAuthenticating, isFalse);
    },
  );

  testWidgets(
    'cold start hides account; cancellation stays locked; retry unlocks',
    (tester) async {
      await tester.pumpWidget(app());
      expect(find.text('Private account'), findsNothing);
      auth.attempts.single.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('Private account'), findsNothing);
      expect(
        find.text('Unlock cancelled. Try again to continue.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Unlock'));
      await tester.pump();
      auth.attempts.last.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Private account'), findsOneWidget);
      expect(auth.options!.biometricOnly, isFalse);
    },
  );

  testWidgets(
    'background and resume lock again, with no duplicate native prompt',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(app());
      auth.attempts.single.complete(true);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('Private account'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(auth.attempts, hasLength(2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(auth.attempts, hasLength(2));
      auth.attempts.last.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Private account'), findsOneWidget);
    },
  );

  testWidgets('native error stays locked and sign-in recovery clears session', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    auth.attempts.single.completeError(PlatformException(code: 'LockedOut'));
    await tester.pumpAndSettle();
    expect(find.text('Private account'), findsNothing);
    expect(find.textContaining('Biometrics are locked'), findsOneWidget);
    await tester.tap(find.text('Sign in again'));
    await tester.pumpAndSettle();
    expect(storage.token, isNull);
    expect(preferences.biometricUnlockEnabled, isFalse);
  });

  testWidgets('disabled preference never prompts', (tester) async {
    await preferences.setBiometricUnlockEnabled(false);
    await tester.pumpWidget(app());
    expect(find.text('Private account'), findsOneWidget);
    expect(auth.attempts, isEmpty);
  });

  testWidgets('disabling during native prompt does not leave a privacy cover', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(app());
    auth.attempts.single.complete(true);
    await tester.pumpAndSettle();
    final disabling = service.authenticate();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('Private account'), findsNothing);
    auth.attempts.last.complete(true);
    await disabling;
    await preferences.setBiometricUnlockEnabled(false);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Private account'), findsOneWidget);
    expect(auth.attempts, hasLength(2));
  });

  testWidgets(
    'authentication completing in background does not unlock on resume',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(app());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      auth.attempts.single.complete(true);
      await tester.pump();
      expect(find.text('Private account'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(auth.attempts, hasLength(2));
      expect(find.text('Private account'), findsNothing);
      auth.attempts.last.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Private account'), findsOneWidget);
    },
  );
}
