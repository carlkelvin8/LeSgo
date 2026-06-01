import 'package:shared_preferences/shared_preferences.dart';

/// User-facing app preferences (notifications, language).
class AppPreferencesService {
  static const pushPromotionsKey = 'pref_push_promotions';
  static const pushOrderUpdatesKey = 'pref_push_order_updates';
  static const pushMissionRemindersKey = 'pref_push_mission_reminders';
  static const appLanguageKey = 'pref_app_language';
  static const biometricUnlockKey = 'pref_biometric_unlock';

  final SharedPreferences _prefs;

  AppPreferencesService(this._prefs);

  bool get pushPromotionsEnabled =>
      _prefs.getBool(pushPromotionsKey) ?? true;

  bool get pushOrderUpdatesEnabled =>
      _prefs.getBool(pushOrderUpdatesKey) ?? true;

  bool get pushMissionRemindersEnabled =>
      _prefs.getBool(pushMissionRemindersKey) ?? true;

  bool get biometricUnlockEnabled =>
      _prefs.getBool(biometricUnlockKey) ?? false;

  String get appLanguage => _prefs.getString(appLanguageKey) ?? 'en';

  Future<void> setPushPromotionsEnabled(bool value) =>
      _prefs.setBool(pushPromotionsKey, value);

  Future<void> setPushOrderUpdatesEnabled(bool value) =>
      _prefs.setBool(pushOrderUpdatesKey, value);

  Future<void> setPushMissionRemindersEnabled(bool value) =>
      _prefs.setBool(pushMissionRemindersKey, value);

  Future<void> setBiometricUnlockEnabled(bool value) =>
      _prefs.setBool(biometricUnlockKey, value);

  Future<void> setAppLanguage(String languageCode) =>
      _prefs.setString(appLanguageKey, languageCode);
}
