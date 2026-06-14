import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/services/remember_me_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    RememberMeService.resetForTests();
    SharedPreferences.setMockInitialValues({});
    await RememberMeService.init();
  });

  test('savePreference stores email and account type only', () async {
    await RememberMeService.savePreference(
      enabled: true,
      email: 'rider@example.com',
      accountType: 'rider',
    );

    expect(RememberMeService.isEnabled(), isTrue);
    expect(RememberMeService.savedEmail, 'rider@example.com');
    expect(RememberMeService.savedAccountType, 'rider');
    expect(RememberMeService.hasSavedEmail, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('remember_me_password'), isFalse);
  });

  test('init purges legacy plaintext password', () async {
    RememberMeService.resetForTests();
    SharedPreferences.setMockInitialValues({
      'remember_me_enabled': true,
      'remember_me_email': 'old@example.com',
      'remember_me_password': 'plaintext-secret',
      'remember_me_account_type': 'rider',
      'remember_me_expires_at':
          DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
    });

    await RememberMeService.init();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('remember_me_password'), isFalse);
    expect(RememberMeService.savedEmail, 'old@example.com');
  });

  test('clearPreference removes remembered email', () async {
    await RememberMeService.savePreference(
      enabled: true,
      email: 'rider@example.com',
      accountType: 'rider',
    );

    await RememberMeService.clearPreference();

    expect(RememberMeService.isEnabled(), isFalse);
    expect(RememberMeService.savedEmail, isNull);
    expect(RememberMeService.hasSavedEmail, isFalse);
  });
}
