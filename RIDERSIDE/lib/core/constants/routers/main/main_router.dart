import 'package:flutter/material.dart';
import '../../../../presentation/screens/main/riderside/rider_document_verification_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_benefits_screens.dart';
import '../../../../presentation/screens/main/riderside/rider_change_password_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_deactivate_account_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_main_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_booking_detail_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_history_detail_screen.dart';
import '../../../../presentation/screens/main/merchantside/merchant_main_screen.dart';
import '../../../../presentation/screens/main/merchantside/merchant_order_detail_screen.dart';
import '../../../../presentation/screens/main/merchantside/merchant_earnings_screen.dart';
import '../../../../domain/entities/rider_booking.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';
import 'main_routes.dart';

class MainRouter {
  static final Map<String, WidgetBuilder> _routes = {
    MainRoutes.riderMain: (_) => const RiderMainScreen(),
    MainRoutes.riderChangePassword: (_) => const RiderChangePasswordScreen(),
    MainRoutes.riderDeactivateAccount: (_) => const RiderDeactivateAccountScreen(),
    MainRoutes.riderFaqs: (_) => const RiderFaqsScreen(),
    MainRoutes.riderOffers: (_) => const RiderOffersScreen(),
    MainRoutes.riderLoyalty: (_) => const RiderLoyaltyScreen(),
    MainRoutes.riderReferral: (_) => const RiderReferralScreen(),
    MainRoutes.riderSecurity: (_) => const RiderSecurityScreen(),
    MainRoutes.riderDocuments: (_) => const RiderDocumentVerificationScreen(),
    MainRoutes.merchantFaqs: (_) => const RiderFaqsScreen(),
    MainRoutes.merchantOffers: (_) => const RiderOffersScreen(),
    MainRoutes.merchantLoyalty: (_) => const RiderLoyaltyScreen(),
    MainRoutes.merchantReferral: (_) => const RiderReferralScreen(),
    MainRoutes.merchantSecurity: (_) => const RiderSecurityScreen(),
    MainRoutes.merchantDocuments: (_) => const RiderDocumentVerificationScreen(),
    MainRoutes.merchantMain: (_) => const MerchantMainScreen(),
    MainRoutes.merchantEarnings: (_) => const MerchantEarningsScreen(),
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
