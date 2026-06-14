import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  AppPreferencesService._();

  static const prefPushPromotions = 'pref_push_promotions';
  static const prefPushOrderUpdates = 'pref_push_order_updates';
  static const prefPushMissionReminders = 'pref_push_mission_reminders';
  static const prefPushChatMessages = 'pref_push_chat_messages';
  static const prefBiometricUnlock = 'pref_biometric_unlock';

  static Future<bool> getBool(String key, {bool defaultValue = true}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<Map<String, bool>> getNotificationSettings() async {
    return {
      prefPushPromotions: await getBool(prefPushPromotions),
      prefPushOrderUpdates: await getBool(prefPushOrderUpdates),
      prefPushMissionReminders: await getBool(prefPushMissionReminders),
      prefPushChatMessages: await getBool(prefPushChatMessages),
    };
  }

  static Future<bool> getBiometricUnlockEnabled() =>
      getBool(prefBiometricUnlock, defaultValue: false);

  static Future<void> setBiometricUnlockEnabled(bool value) =>
      setBool(prefBiometricUnlock, value);
}
