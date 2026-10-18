import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, filipino }

final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, AppLanguage>(
  (ref) => AppLanguageNotifier(),
);

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  AppLanguageNotifier() : super(AppLanguage.english) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('pref_app_language') ?? 'en';
    state = lang == 'tl' ? AppLanguage.filipino : AppLanguage.english;
  }

  Future<void> setLanguage(AppLanguage lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pref_app_language',
      lang == AppLanguage.filipino ? 'tl' : 'en',
    );
  }
}

class AppLocalization {
  static String translate(String key, AppLanguage lang) {
    if (lang == AppLanguage.filipino && _filipinoTranslations.containsKey(key)) {
      return _filipinoTranslations[key]!;
    }
    return _englishTranslations[key] ?? key;
  }
}

/// Read the current translation for [key], reacting to language changes.
String tr(BuildContext context, String key) {
  try {
    final container = ProviderScope.containerOf(context, listen: true);
    return AppLocalization.translate(key, container.read(appLanguageProvider));
  } catch (_) {
    return AppLocalization.translate(key, AppLanguage.english);
  }
}

const Map<String, String> _englishTranslations = {
  // App & Navigation
  'app_name': 'LeSgo',
  'home': 'Home',
  'bookings': 'Bookings',
  'profile': 'Profile',
  'more': 'More',
  'inbox': 'Inbox',
  'transactions': 'Transactions',
  'favorites': 'Favorites',
  'offers': 'Offers',
  'missions': 'Missions',
  'support': 'Support',
  'settings': 'Settings',
  'history': 'History',
  'about': 'About',
  'account': 'Account',
  'app_section': 'App',
  'my_profile': 'My Profile',
  'invite_friends': 'Invite friends',
  'saved_addresses': 'Saved Addresses',
  'profile_information': 'Profile Information',
  'lesgo_support': 'LeSgo Support',
  'support_tickets': 'Support Tickets',

  // Common Actions
  'cancel': 'Cancel',
  'confirm': 'Confirm',
  'submit': 'Submit',
  'save': 'Save',
  'retry': 'Retry',
  'continue': 'Continue',
  'close': 'Close',
  'yes': 'Yes',
  'no': 'No',
  'back': 'Back',
  'done': 'Done',
  'ok': 'OK',
  'loading': 'Loading...',
  'no_data': 'No data available',
  'search': 'Search',
  'view_all': 'View All',
  'try_again': 'Try Again',
  'not_available': 'Not available',
  'pending': 'Pending',

  // Settings
  'settings_and_support': 'Settings & Support',
  'language': 'Language',
  'english': 'English',
  'filipino': 'Filipino',
  'dark_mode': 'Dark Mode',
  'notifications': 'Notifications',
  'notification_settings': 'Notification Settings',
  'security': 'Security & 2FA',
  'change_password': 'Change Password',
  'deactivate_account': 'Deactivate Account',
  'delete_account': 'Delete Account',
  'referrals_and_rewards': 'Referrals & Rewards',
  'faqs': 'FAQs',
  'document_verification': 'Document Verification',
  'privacy_policy': 'Privacy Policy',
  'terms_of_service': 'Terms of Service',
  'about_lesgo': 'About LeSgo',
  'language_changed': 'Language updated',
  'language_changed_immediately':
      'The app language updates immediately across all screens.',

  // LesPay Wallet
  'wallet': 'LesPay Wallet',
  'wallet_balance': 'Total Balance',
  'lespay_balance': 'LesPay Balance',
  'available_balance': 'Available Balance',
  'my_lespay_wallet': 'My LesPay Wallet',
  'tap_to_reveal': 'Tap to reveal',
  'transaction_history': 'Transaction History',
  'top_up_your_wallet': 'Top up your wallet to start making payments',
  'type_topup': 'Top-up',
  'type_payment': 'Payment',
  'top_up': 'Top Up',
  'withdraw': 'Withdraw',
  'use_lespay': 'Use LesPay',
  'scan_pay': 'Scan & Pay',
  'send': 'Send',
  'cash_earnings': 'Cash Earnings',
  'referral_earnings': 'Referral Earnings',
  'quick_actions': 'Quick Actions',
  'recent_transactions': 'Recent Transactions',
  'payment_methods': 'Payment Methods',
  'see_all': 'See All',
  'no_transactions_yet': 'No transactions yet',
  'your_transactions_will_appear':
      'Your transactions will appear here once you start using LesPay.',
  'month': 'Month',
  'total_spent': 'Total Spent',
  'total_received': 'Total Received',
  'spent': 'Spent',
  'saved': 'Saved',
  'this_month': 'This Month',
  'add_funds_with_card': 'Add funds with card',
  'manage_cards_wallets': 'Manage cards & wallets',
  'qr_pay': 'QR Pay',
  'pay_via_qr_ph': 'Pay via QR Ph',
  'receive_messages_orders':
      'Receive messages about your orders.',
  'pay_orders_lespay':
      'Pay your orders with your LesPay wallet.',
  'manage_payment_methods': 'Payment Methods',
  'linked_accounts': 'Linked Accounts',
  'message_center': 'Messages',
  'vouchers': 'Vouchers',
  'loyalty': 'Loyalty',
};

const Map<String, String> _filipinoTranslations = {
  // App & Navigation
  'app_name': 'LeSgo',
  'home': 'Home',
  'bookings': 'Mga Booking',
  'profile': 'Profile',
  'more': 'Iba Pa',
  'inbox': 'Inbox',
  'transactions': 'Mga Transaksyon',
  'favorites': 'Mga Paborito',
  'offers': 'Mga Alok',
  'missions': 'Mga Misyon',
  'support': 'Suporta',
  'settings': 'Settings',
  'history': 'Kasaysayan',
  'about': 'Tungkol sa',
  'account': 'Account',
  'app_section': 'App',
  'my_profile': 'Aking Profile',
  'invite_friends': 'Mag-imbita ng kaibigan',
  'saved_addresses': 'Mga Naka-save na Address',
  'profile_information': 'Impormasyon ng Profile',
  'lesgo_support': 'LeSgo Support',
  'support_tickets': 'Mga Support Ticket',

  // Common Actions
  'cancel': 'Kanselahin',
  'confirm': 'Kumpirmahin',
  'submit': 'Isumite',
  'save': 'I-save',
  'retry': 'Subukan Muli',
  'continue': 'Magpatuloy',
  'close': 'Isara',
  'yes': 'Oo',
  'no': 'Hindi',
  'back': 'Bumalik',
  'done': 'Tapos',
  'ok': 'Sige',
  'loading': 'Naglo-load...',
  'no_data': 'Walang available na data',
  'search': 'Maghanap',
  'view_all': 'Tingnan Lahat',
  'try_again': 'Subukan Muli',
  'not_available': 'Hindi available',
  'pending': 'Nakabinbin',

  // Settings
  'settings_and_support': 'Settings at Suporta',
  'language': 'Wika',
  'english': 'English',
  'filipino': 'Filipino',
  'dark_mode': 'Dark Mode',
  'notifications': 'Mga Notipikasyon',
  'notification_settings': 'Settings ng Notipikasyon',
  'security': 'Seguridad at 2FA',
  'change_password': 'Palitan ang Password',
  'deactivate_account': 'I-deactivate ang Account',
  'delete_account': 'Burahin ang Account',
  'referrals_and_rewards': 'Referrals at Rewards',
  'faqs': 'Mga FAQ',
  'document_verification': 'Pag-verify ng Dokumento',
  'privacy_policy': 'Privacy Policy',
  'terms_of_service': 'Terms of Service',
  'about_lesgo': 'Tungkol sa LeSgo',
  'language_changed': 'Na-update ang wika',
  'language_changed_immediately':
      'Agad na mag-a-update ang wika ng app sa lahat ng screen.',

  // LesPay Wallet
  'wallet': 'LesPay Wallet',
  'wallet_balance': 'Kabuuang Balanse',
  'lespay_balance': 'LesPay Balance',
  'available_balance': 'Available na Balanse',
  'my_lespay_wallet': 'Aking LesPay Wallet',
  'tap_to_reveal': 'I-tap para makita',
  'transaction_history': 'Kasaysayan ng Transaksyon',
  'top_up_your_wallet': 'Mag-top up sa iyong wallet para makapagbayad',
  'type_topup': 'Top-up',
  'type_payment': 'Pagbabayad',
  'top_up': 'Mag-top Up',
  'withdraw': 'Mag-withdraw',
  'use_lespay': 'Gamitin ang LesPay',
  'scan_pay': 'Scan & Pay',
  'send': 'Ipadala',
  'cash_earnings': 'Cash Earnings',
  'referral_earnings': 'Referral Earnings',
  'quick_actions': 'Mabilis na Aksyon',
  'recent_transactions': 'Mga Kamakailang Transaksyon',
  'payment_methods': 'Mga Paraan ng Pagbabayad',
  'see_all': 'Tingnan Lahat',
  'no_transactions_yet': 'Wala pang transaksyon',
  'your_transactions_will_appear':
      'Lalabas ang iyong mga transaksyon dito kapag nagsimula kang gumamit ng LesPay.',
  'month': 'Buwan',
  'total_spent': 'Kabuuang Nagastos',
  'total_received': 'Kabuuang Natanggap',
  'spent': 'Nagastos',
  'saved': 'Naipon',
  'this_month': 'Ngayong Buwan',
  'add_funds_with_card': 'Magdagdag ng pondo gamit ang card',
  'manage_cards_wallets': 'Pamahalaan ang mga card at wallet',
  'qr_pay': 'QR Pay',
  'pay_via_qr_ph': 'Magbayad gamit ang QR Ph',
  'receive_messages_orders':
      'Makatanggap ng mga mensahe tungkol sa iyong mga order.',
  'pay_orders_lespay':
      'Bayaran ang iyong mga order gamit ang LesPay wallet.',
  'manage_payment_methods': 'Mga Paraan ng Pagbabayad',
  'linked_accounts': 'Mga Naka-link na Account',
  'message_center': 'Mga Mensahe',
  'vouchers': 'Mga Voucher',
  'loyalty': 'Loyalty',
};