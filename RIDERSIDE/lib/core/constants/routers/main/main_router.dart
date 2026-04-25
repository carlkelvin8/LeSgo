import 'package:flutter/material.dart';
import '../../../../presentation/screens/main/riderside/rider_main_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_booking_detail_screen.dart';
import '../../../../presentation/screens/main/riderside/rider_history_detail_screen.dart';
import '../../../../presentation/screens/main/merchantside/merchant_main_screen.dart';
import '../../../../domain/entities/rider_booking.dart';
import 'main_routes.dart';

class MainRouter {
  static final Map<String, WidgetBuilder> _routes = {
    MainRoutes.riderMain: (_) => const RiderMainScreen(),
    MainRoutes.merchantMain: (_) => const MerchantMainScreen(),
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
