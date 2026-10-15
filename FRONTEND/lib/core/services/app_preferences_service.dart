import 'secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-facing app preferences (notifications, language).
class AppPreferencesService {
  static const pushPromotionsKey = 'pref_push_promotions';
  static const pushOrderUpdatesKey = 'pref_push_order_updates';
  static const pushMissionRemindersKey = 'pref_push_mission_reminders';
  static const appLanguageKey = 'pref_app_language';
  static const biometricUnlockKey = 'pref_biometric_unlock';
  static const lespayBalanceVisibleKey = 'pref_lespay_balance_visible';
  static const darkModeKey = 'pref_dark_mode';

  final SharedPreferences _prefs;

  AppPreferencesService(this._prefs);

  bool get pushPromotionsEnabled =>
      _prefs.getBool(pushPromotionsKey) ?? true;

  bool get pushOrderUpdatesEnabled =>
      _prefs.getBool(pushOrderUpdatesKey) ?? true;

  bool get pushMissionRemindersEnabled =>
      _prefs.getBool(pushMissionRemindersKey) ?? true;

  bool get biometricUnlockEnabled =>
      SecureStorageService(_prefs).getBool(biometricUnlockKey) ?? false;

  bool get lespayBalanceVisible =>
      _prefs.getBool(lespayBalanceVisibleKey) ?? true;

  String get appLanguage => _prefs.getString(appLanguageKey) ?? 'en';

  bool get darkModeEnabled => _prefs.getBool(darkModeKey) ?? false;

  Future<void> setPushPromotionsEnabled(bool value) =>
      _prefs.setBool(pushPromotionsKey, value);

  Future<void> setPushOrderUpdatesEnabled(bool value) =>
      _prefs.setBool(pushOrderUpdatesKey, value);

  Future<void> setPushMissionRemindersEnabled(bool value) =>
      _prefs.setBool(pushMissionRemindersKey, value);

  Future<void> setBiometricUnlockEnabled(bool value) =>
      SecureStorageService(_prefs).setBool(biometricUnlockKey, value);

  Future<void> setLespayBalanceVisible(bool value) =>
      _prefs.setBool(lespayBalanceVisibleKey, value);

  Future<void> setAppLanguage(String languageCode) =>
      _prefs.setString(appLanguageKey, languageCode);

  Future<void> setDarkModeEnabled(bool value) =>
      _prefs.setBool(darkModeKey, value);
}
