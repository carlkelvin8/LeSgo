import 'package:flutter/material.dart';
import '../../../../presentation/screens/main/riderside/rider_earnings_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_earnings_insights_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_safety_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_schedule_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_scheduled_payout_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_rating_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_vehicle_management_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_document_verification_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_benefits_screens.dart';
import '../../../../presentation/screens/main/riderside/rider_change_password_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_deactivate_account_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_delete_account_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_notification_center_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_notification_settings_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_customer_service_chat_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_security_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_faqs_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_main_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_booking_detail_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_history_detail_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_quick_stats_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_payout_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_trip_analytics_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_performance_screen.dart';
import '../../../../presentation/screens/main/merchantside/merchant_main_screen.dart';
import '../../../../presentation/screens/main/merchantside/merchant_order_detail_screen.dart';
import '../../../../presentation/screens/main/merchantside/merchant_reviews_screen.dart';
import '../../../../presentation/screens/main/merchantside/merchant_analytics_screen.dart';
import '../../../../presentation/screens/main/merchantside/merchant_sales_report_screen.dart';
import '../../../../presentation/screens/main/merchantside/merchant_staff_screen.dart';
import '../../../../presentation/screens/main/merchantside/merchant_support_tickets_screen.dart';
import '../../../../presentation/screens/main/merchantside/printer_settings_screen.dart';
import '../../../../presentation/screens/main/merchantside/merchant_missions_screen.dart';
import '../../../../domain/entities/rider_booking.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';
import 'main_routes.dart';

class MainRouter {
  static final Map<String, WidgetBuilder> _routes = {
    MainRoutes.riderMain: (_) => const RiderMainScreen(),
    MainRoutes.riderChangePassword: (_) => const RiderChangePasswordScreen(),
    MainRoutes.riderDeactivateAccount: (_) => const RiderDeactivateAccountScreen(),
    MainRoutes.riderDeleteAccount: (_) => const RiderDeleteAccountScreen(),
    MainRoutes.riderSupportTickets: (_) => const RiderSupportTicketsScreen(),
    MainRoutes.riderNotifications: (_) => const RiderNotificationCenterScreen(),
    MainRoutes.riderNotificationSettings: (_) =>
        const RiderNotificationSettingsScreen(),
    MainRoutes.riderCustomerServiceChat: (_) =>
        const RiderCustomerServiceChatScreen(),
    MainRoutes.riderFaqs: (_) => const RiderFaqsScreen(),
    MainRoutes.riderOffers: (_) => const RiderOffersScreen(),
    MainRoutes.riderLoyalty: (_) => const RiderLoyaltyScreen(),
    MainRoutes.riderReferral: (_) => const RiderReferralScreen(),
    MainRoutes.riderSecurity: (_) => const RiderSecurityScreen(),
    MainRoutes.riderDocuments: (_) => const RiderDocumentVerificationScreen(),
    MainRoutes.riderEarnings: (_) => const RiderEarningsScreen(),
    MainRoutes.riderSafety: (_) => const RiderSafetyScreen(),
    MainRoutes.riderSchedule: (_) => const RiderScheduleScreen(),
    MainRoutes.riderScheduledPayout: (_) =>
        const RiderScheduledPayoutScreen(),
    MainRoutes.riderEarningsInsights: (_) =>
        const RiderEarningsInsightsScreen(),
    MainRoutes.riderRating: (_) => const RiderRatingScreen(),
    MainRoutes.riderVehicleManagement: (_) =>
        const RiderVehicleManagementScreen(),
    MainRoutes.riderQuickStats: (_) => const RiderQuickStatsScreen(),
    MainRoutes.riderPayout: (_) => const RiderPayoutScreen(),
    MainRoutes.riderTripAnalytics: (_) => const RiderTripAnalyticsScreen(),
    MainRoutes.riderPerformance: (_) => const RiderPerformanceScreen(),
    MainRoutes.merchantFaqs: (_) => const RiderFaqsScreen(),
    MainRoutes.merchantOffers: (_) => const RiderOffersScreen(),
    MainRoutes.merchantLoyalty: (_) => const RiderLoyaltyScreen(),
    MainRoutes.merchantReferral: (_) => const RiderReferralScreen(),
    MainRoutes.merchantSecurity: (_) => const RiderSecurityScreen(),
    MainRoutes.merchantSupportTickets: (_) =>
        const MerchantSupportTicketsScreen(),
    MainRoutes.merchantMissions: (_) => const MerchantMissionsScreen(),
    MainRoutes.merchantDeactivateAccount: (_) =>
        const RiderDeactivateAccountScreen(),
    MainRoutes.merchantDeleteAccount: (_) => const RiderDeleteAccountScreen(),
    MainRoutes.merchantDocuments: (_) => const RiderDocumentVerificationScreen(),
    MainRoutes.merchantMain: (_) => const MerchantMainScreen(),
    MainRoutes.merchantReviews: (_) => const MerchantReviewsScreen(),
    MainRoutes.merchantAnalytics: (_) => const MerchantAnalyticsScreen(),
    MainRoutes.merchantSalesReport: (_) => const MerchantSalesReportScreen(),
    MainRoutes.merchantStaff: (_) => const MerchantStaffScreen(),
    MainRoutes.merchantPrinterSettings: (_) => const PrinterSettingsScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Handle booking detail route with RiderBooking argument
    if (settings.name == MainRoutes.riderBookingDetail) {
      final booking = settings.arguments as RiderBooking;
      return MaterialPageRoute(
        builder: (_) => RiderBookingDetailScreen(booking: booking),
        settings: settings,
      );
    }

    if (settings.name == MainRoutes.merchantOrderDetail) {
      final order = settings.arguments as OrderDto;
      return MaterialPageRoute(
        builder: (_) => MerchantOrderDetailScreen(order: order),
        settings: settings,
      );
    }

    // Handle history detail route with Map argument
    if (settings.name == MainRoutes.riderHistoryDetail) {
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (_) => RiderHistoryDetailScreen(
          bookingData: args['bookingData'] as Map<String, String>,
          statusColor: args['statusColor'] as Color,
          statusBackgroundColor: args['statusBackgroundColor'] as Color,
        ),
        settings: settings,
      );
    }

    final builder = _routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }
    return null;
  }

  MainRouter._();
}
