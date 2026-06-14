import 'package:flutter/material.dart';
import '../../../../presentation/screens/main/home_screen.dart';
import '../../../../presentation/screens/main/booking/booking_screen.dart';
import '../../../../presentation/screens/main/lespay_screen.dart';
import '../../../../presentation/screens/main/inbox_screen.dart';
import '../../../../presentation/screens/main/profile_screen.dart';
import '../../../../presentation/screens/main/transactions_screen.dart';
import '../../../../presentation/screens/main/favorites_screen.dart';
import '../../../../presentation/screens/main/offers_screen.dart';
import '../../../../presentation/screens/main/missions_screen.dart';
import '../../../../presentation/screens/main/loyalty_redeem_screen.dart';
import '../../../../presentation/screens/main/settings_screen.dart';
import '../../../../presentation/screens/main/settings/notification_settings_screen.dart';
import '../../../../presentation/screens/main/settings/language_settings_screen.dart';
import '../../../../presentation/screens/main/security/security_settings_screen.dart';
import '../../../../presentation/screens/main/referral/referral_dashboard_screen.dart';
import '../../../../presentation/screens/main/faqs_screen.dart';
import '../../../../presentation/screens/main/support/support_tickets_screen.dart';
import '../../../../presentation/screens/main/support/customer_service_chat_screen.dart';
import '../../../../presentation/screens/main/documents/document_verification_screen.dart';
import '../../../../presentation/screens/main/about_screen.dart';
import '../../../../presentation/screens/legal/privacy_policy_screen.dart';
import '../../../../presentation/screens/legal/terms_of_service_screen.dart';
import '../../../../presentation/screens/main/settings/change_password_screen.dart';
import '../../../../presentation/screens/main/settings/deactivate_account_screen.dart';
import '../../../../presentation/screens/main/settings/delete_account_screen.dart';
import '../../../../presentation/screens/main/set_location_screen.dart';
import '../../../../presentation/screens/main/address_management_screen.dart';
import '../../../../presentation/screens/demo/address_demo_screen.dart';
import '../../../../presentation/screens/main/payment_methods_screen.dart';
import 'main_routes.dart';

class MainRouter {
  static final Map<String, WidgetBuilder> _routes = {
    MainRoutes.home: (_) => const HomeScreen(),
    MainRoutes.bookNow: (_) => const BookingScreen(),

    MainRoutes.lespay: (_) => const LespayScreen(),
    MainRoutes.inbox: (_) => const InboxScreen(),
    MainRoutes.profile: (_) => const ProfileScreen(),
    MainRoutes.favorites: (_) => const FavoritesScreen(),
    MainRoutes.offers: (_) => const OffersScreen(),
    MainRoutes.missions: (_) => const MissionsScreen(),
    MainRoutes.loyaltyRedeem: (_) => const LoyaltyRedeemScreen(),

    MainRoutes.settings: (_) => const SettingsScreen(),
    MainRoutes.notificationSettings: (_) => const NotificationSettingsScreen(),
    MainRoutes.languageSettings: (_) => const LanguageSettingsScreen(),
    MainRoutes.securitySettings: (_) => const SecuritySettingsScreen(),
    MainRoutes.referralDashboard: (_) => const ReferralDashboardScreen(),
    MainRoutes.faqs: (_) => const FaqsScreen(),
    MainRoutes.supportTickets: (_) => const SupportTicketsScreen(),
    MainRoutes.customerServiceChat: (_) => const CustomerServiceChatScreen(),
    MainRoutes.documentVerification: (_) => const DocumentVerificationScreen(),
    MainRoutes.about: (_) => const AboutScreen(),
    MainRoutes.privacyPolicy: (_) => const PrivacyPolicyScreen(),
    MainRoutes.termsOfService: (_) => const TermsOfServiceScreen(),
    MainRoutes.changePassword: (_) => const ChangePasswordScreen(),
    MainRoutes.deactivateAccount: (_) => const DeactivateAccountScreen(),
    MainRoutes.deleteAccount: (_) => const DeleteAccountScreen(),

    MainRoutes.setLocation: (_) => const SetLocationScreen(),
    MainRoutes.addressManagement: (_) => const AddressManagementScreen(),
    MainRoutes.addressDemo: (_) => const AddressDemoScreen(),
    MainRoutes.paymentMethods: (_) => const PaymentMethodsScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == MainRoutes.transactions) {
      final args = settings.arguments;
      final kind =
          args is Map<String, dynamic> ? args['kind'] as String? : null;
      return MaterialPageRoute(
        builder: (_) => TransactionsScreen(initialKindFilter: kind),
        settings: settings,
      );
    }
    if (settings.name == MainRoutes.setLocation) {
      return MaterialPageRoute<bool>(
        builder: (_) => const SetLocationScreen(),
        settings: settings,
      );
    }

    final builder = _routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    return null;
  }

  static Future<T?> push<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, TO>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  MainRouter._();
}
