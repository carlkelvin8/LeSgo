import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lesgo/core/di/local_storage_service.dart';
import 'package:lesgo/core/services/secure_storage_service.dart';
import 'package:lesgo/data/data_source/dto/login/login_request_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('login request sends a stable per-install device name', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await SecureStorageService(preferences).initialize();

    final storage = LocalStorageService(preferences);
    addTearDown(storage.dispose);

    final firstName = await storage.getOrCreateAuthDeviceName();
    final secondName = await storage.getOrCreateAuthDeviceName();
    final request = LoginRequestDto(
      email: 'qa@example.test',
      password: 'ignored-in-test',
      deviceName: firstName,
    );

    expect(firstName, startsWith('lesgo-customer-'));
    expect(secondName, firstName);
    expect(request.toJson()['device_name'], firstName);
  });
}
