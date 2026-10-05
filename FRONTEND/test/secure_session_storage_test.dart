import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lesgo/core/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('legacy secrets migrate together; remembered password is discarded', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'auth_token': 'session', 'refresh_token': 'refresh',
      'saved_password': 'old-password', 'saved_email': 'user@example.test',
      'pref_biometric_unlock': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final secure = SecureStorageService(prefs);
    await secure.initialize();
    expect(secure.getAuthToken(), 'session');
    expect(secure.isBiometricEnabled(), isTrue);
    expect(prefs.getKeys(), isEmpty);
    final values = await const FlutterSecureStorage().readAll();
    expect(values.values, isNot(contains('old-password')));
    expect(values['lesgo_secure_auth_token'], 'session');
    await secure.disableBiometric();
    expect(await const FlutterSecureStorage().read(key: 'lesgo_secure_pref_biometric_unlock'), 'false');
    // New preference instance models a fresh process using the same secure disk.
    SharedPreferences.setMockInitialValues({});
    final restored = SecureStorageService(await SharedPreferences.getInstance());
    await restored.initialize();
    expect(restored.getAuthToken(), 'session');
    expect(restored.isBiometricEnabled(), isFalse);
    await restored.clearAuthData();
    expect(restored.isLoggedIn(), isFalse);
    expect(await const FlutterSecureStorage().read(key: 'lesgo_secure_auth_token'), isNull);
    expect(await const FlutterSecureStorage().read(key: 'lesgo_secure_refresh_token'), isNull);
    expect(await const FlutterSecureStorage().read(key: 'lesgo_secure_saved_email'), isNull);
  });
  test('interrupted migration cannot restore a partially migrated unlocked session', () async {
    FlutterSecureStorage.setMockInitialValues({
      'lesgo_secure_migration': 'pending', 'lesgo_secure_auth_token': 'partial-session',
    });
    SharedPreferences.setMockInitialValues({'pref_biometric_unlock': true});
    final prefs = await SharedPreferences.getInstance();
    final secure = SecureStorageService(prefs);
    await secure.initialize();
    expect(secure.isLoggedIn(), isFalse);
    expect(await const FlutterSecureStorage().read(key: 'lesgo_secure_auth_token'), isNull);
    expect(prefs.getKeys(), isEmpty);
  });
}
