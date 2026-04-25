import 'package:flutter/material.dart';
import '../../../../presentation/screens/main/booking/leseat/leseat_screen.dart';
import '../../../../presentation/screens/main/booking/leseat/restaurant_detail_screen.dart';
import '../../../../presentation/screens/main/booking/leseat/menu_item_detail_screen.dart';
import '../../../../presentation/screens/main/booking/leseat/leseat_checkout_screen.dart';
import '../../../../presentation/screens/main/booking/leseat/leseat_order_tracking_screen.dart';
import '../../../../presentation/screens/main/booking/leseat/leseat_order_status_screen.dart';
import '../../../../presentation/screens/main/booking/leseat/leseat_order_complete_screen.dart';
import '../../../../presentation/screens/main/booking/lesbuy/lesbuy_screen.dart';
import '../../../../presentation/screens/main/booking/lesbuy/lesbuy_order_tracking_screen.dart';
import '../../../../presentation/screens/main/booking/lesbuy/lesbuy_order_complete_screen.dart';
import '../../../../presentation/screens/main/booking/lesgo_screen.dart';
import '../../../../presentation/screens/main/booking/lesgo/lesgo_order_tracking_screen.dart';
import '../../../../presentation/screens/main/booking/lesport_screen.dart';
import '../../../../presentation/screens/main/booking/lesride_screen.dart';
import '../../../../domain/entities/booking/leseat/restaurant.dart';
import '../../../../domain/entities/booking/leseat/menu_item.dart';
import '../../../../domain/entities/booking/lesbuy/store.dart';
import '../../../../domain/entities/booking/lesbuy/product.dart';
import '../../../../presentation/screens/main/booking/lesbuy/store_detail_screen.dart';
import '../../../../presentation/screens/main/booking/lesbuy/store_product_detail_screen.dart';
import '../../../../presentation/screens/main/booking/lesbuy/store_cart_screen.dart';
import '../../../../presentation/screens/main/booking/lesbuy/manual_order_screen.dart';
import '../../../../presentation/screens/main/booking/driver_finding_screen.dart';
import 'booking_routes.dart';

class BookingRouter {
  static final Map<String, WidgetBuilder> _routes = {
    BookingRoutes.leseat: (_) => const LeseatScreen(),
    BookingRoutes.leseatCheckout: (_) => const LeseatCheckoutScreen(),
    BookingRoutes.lesbuy: (_) => const LesbuyScreen(),
    BookingRoutes.lesgo: (_) => const LesgoScreen(),
    BookingRoutes.lesport: (_) => const LesportScreen(),
    BookingRoutes.lesride: (_) => const LesrideScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Handle restaurant detail route with arguments
    if (settings.name == BookingRoutes.leseatRestaurantDetail) {
      final restaurant = settings.arguments as Restaurant;
      return MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
        settings: settings,
      );
    }

    // Handle menu item detail route with arguments
    if (settings.name == BookingRoutes.leseatMenuItemDetail) {
      final menuItem = settings.arguments as MenuItem;
      return MaterialPageRoute(
        builder: (_) => MenuItemDetailScreen(menuItem: menuItem),
        settings: settings,
      );
    }

    // Handle store detail route with arguments
    if (settings.name == BookingRoutes.lesbuyStoreDetail) {
      final store = settings.arguments as Store;
      return MaterialPageRoute(
        builder: (_) => StoreDetailScreen(store: store),
        settings: settings,
      );
    }

    // Handle product detail route with arguments
    if (settings.name == BookingRoutes.lesbuyProductDetail) {
      final product = settings.arguments as Product;
      return MaterialPageRoute(
        builder: (_) => StoreProductDetailScreen(product: product),
        settings: settings,
      );
    }

    if (settings.name == BookingRoutes.lesbuyCart) {
      return MaterialPageRoute(
        builder: (_) => const StoreCartScreen(),
        settings: settings,
      );
    }

    if (settings.name == BookingRoutes.lesbuyManualOrder) {
      final args = settings.arguments as Map<String, dynamic>?;
      final fromCart = args?['fromCart'] as bool? ?? false;
      return MaterialPageRoute(
        builder: (_) => ManualOrderScreen(fromCart: fromCart),
        settings: settings,
      );
    }

    // Handle driver finding route with arguments
    if (settings.name == BookingRoutes.driverFinding) {
      final args = settings.arguments as Map<String, dynamic>;
      final orderId = args['orderId'] as String;
      final orderType = args['orderType'] as String;
      final orderData = args['orderData'] as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => DriverFindingScreen(
          orderId: orderId,
          orderType: orderType,
          orderData: orderData,
        ),
        settings: settings,
      );
    }

    // Handle LesBuy order tracking route with arguments
    if (settings.name == BookingRoutes.lesbuyOrderTracking) {
      final args = settings.arguments as Map<String, dynamic>;
      final orderId = args['orderId'] as String;
      final orderType = args['orderType'] as String;
      final orderData = args['orderData'] as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => LesbuyOrderTrackingScreen(
          orderId: orderId,
          orderType: orderType,
          orderData: orderData,
        ),
        settings: settings,
      );
    }

    // Handle LesBuy order complete route with arguments
    if (settings.name == BookingRoutes.lesbuyOrderComplete) {
      final args = settings.arguments as Map<String, dynamic>;
      final orderId = args['orderId'] as String;
      final orderType = args['orderType'] as String;
      final orderData = args['orderData'] as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => LesbuyOrderCompleteScreen(
          orderId: orderId,
          orderType: orderType,
          orderData: orderData,
        ),
        settings: settings,
      );
    }

    // Handle LesGo order tracking route with arguments
    if (settings.name == BookingRoutes.lesgoOrderTracking) {
      final args = settings.arguments as Map<String, dynamic>;
      final orderId = args['orderId'] as String;
      final orderType = args['orderType'] as String;
      final orderData = args['orderData'] as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => LesgoOrderTrackingScreen(
          orderId: orderId,
          orderType: orderType,
          orderData: orderData,
        ),
        settings: settings,
      );
    }

    // Handle LesEat order tracking route with arguments
    if (settings.name == BookingRoutes.leseatOrderTracking) {
      final args = settings.arguments as Map<String, dynamic>;
      final orderId = args['orderId'] as String;
      final orderType = args['orderType'] as String;
      final orderData = args['orderData'] as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => LeseatOrderTrackingScreen(
          orderId: orderId,
          orderType: orderType,
          orderData: orderData,
        ),
        settings: settings,
      );
    }

    // Handle LesEat order status route with arguments
    if (settings.name == BookingRoutes.leseatOrderStatus) {
      final args = settings.arguments as Map<String, dynamic>;
      final orderId = args['orderId'] as String;
      final orderType = args['orderType'] as String;
      final orderData = args['orderData'] as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => LeseatOrderStatusScreen(
          orderId: orderId,
          orderType: orderType,
          orderData: orderData,
        ),
        settings: settings,
      );
    }

    // Handle LesEat order complete route with arguments
    if (settings.name == BookingRoutes.leseatOrderComplete) {
      final args = settings.arguments as Map<String, dynamic>;
      final orderId = args['orderId'] as String;
      final orderType = args['orderType'] as String;
      final orderData = args['orderData'] as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => LeseatOrderCompleteScreen(
          orderId: orderId,
          orderType: orderType,
          orderData: orderData,
        ),
        settings: settings,
      );
    }

    final builder = _routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    return null;
  }
}
