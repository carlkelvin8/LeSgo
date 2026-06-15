import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, filipino }

final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, AppLanguage>((ref) {
  return AppLanguageNotifier();
});

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  AppLanguageNotifier() : super(AppLanguage.english) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_language') ?? 'en';
    state = lang == 'tl' ? AppLanguage.filipino : AppLanguage.english;
  }

  Future<void> setLanguage(AppLanguage lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang == AppLanguage.filipino ? 'tl' : 'en');
  }
}

class AppLocalization {
  static String translate(String key, AppLanguage lang) {
    if (lang == AppLanguage.filipino && _filipinoTranslations.containsKey(key)) {
      return _filipinoTranslations[key]!;
    }
    return _englishTranslations[key] ?? key;
  }

  static const Map<String, String> _englishTranslations = {
    'app_name': 'LeSGo Rider',
    'earnings': 'My Earnings',
    'safety': 'Safety & SOS',
    'bookings': 'Bookings',
    'history': 'History',
    'profile': 'Profile',
    'more': 'More',
    'wallet': 'LesPay Wallet',
    'missions': 'Missions',
    'notifications': 'Notifications',
    'faqs': 'FAQs',
    'support': 'Support Tickets',
    'security': 'Security & 2FA',
    'dark_mode': 'Dark Mode',
    'language': 'Language',
    'english': 'English',
    'filipino': 'Filipino',
    'off_duty': 'Off Duty',
    'on_duty': 'On Duty',
    'no_notifications': 'No notifications yet',
    'no_history': 'No history yet',
    'completed_trips': 'Completed Trips',
    'net_earnings': 'Net Rider Earnings',
    'settings': 'Settings',
    'log_out': 'Log Out',
    'current_tier': 'Current Tier',
    'package_tier': 'Package Tier',
    'features': 'Features',
    'upgrade_options': 'Upgrade Options',
    'coming_soon': 'Coming Soon',
  };

  static const Map<String, String> _filipinoTranslations = {
    'app_name': 'LeSGo Rider',
    'earnings': 'Aking Kita',
    'safety': 'Kaligtasan at SOS',
    'bookings': 'Mga Booking',
    'history': 'Kasaysayan',
    'profile': 'Profile',
    'more': 'Iba Pa',
    'wallet': 'LesPay Wallet',
    'missions': 'Mga Misyon',
    'notifications': 'Mga Notipikasyon',
    'faqs': 'Mga FAQ',
    'support': 'Suporta',
    'security': 'Seguridad at 2FA',
    'dark_mode': 'Dark Mode',
    'language': 'Wika',
    'english': 'English',
    'filipino': 'Filipino',
    'off_duty': 'Off Duty',
    'on_duty': 'On Duty',
    'no_notifications': 'Wala pang notipikasyon',
    'no_history': 'Wala pang kasaysayan',
    'completed_trips': 'Mga Natapos na Biyahe',
    'net_earnings': 'Netong Kita',
    'settings': 'Settings',
    'log_out': 'Log Out',
    'current_tier': 'Kasalukuyang Tier',
    'package_tier': 'Package Tier',
    'features': 'Mga Tampok',
    'upgrade_options': 'Mga Opsyon sa Pag-upgrade',
    'coming_soon': 'Malapit Na',
  };
}
