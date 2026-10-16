import 'package:flutter/material.dart';
import 'auth/auth_router.dart';
import 'register/register_router.dart';
import 'main/main_router.dart';
import 'booking/booking_router.dart';

// ─── Shared slide+fade transition ─────────────────────────────────────────────
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Offset beginOffset;

  SlidePageRoute({
    required this.child,
    required RouteSettings settings,
    this.beginOffset = const Offset(1.0, 0.0),
    Duration duration = const Duration(milliseconds: 320),
  }) : super(
          settings: settings,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, __, ___) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slide = Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
              ),
            );

            // Outgoing screen slides slightly left
            final secondarySlide = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.12, 0.0),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
            ));

            return SlideTransition(
              position: secondarySlide,
              child: FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: slide,
                  child: child,
                ),
              ),
            );
          },
        );
}

// ─── Helper to wrap any builder in the slide transition ───────────────────────
SlidePageRoute<T> _slide<T>({
  required RouteSettings settings,
  required WidgetBuilder builder,
  Offset begin = const Offset(1.0, 0.0),
}) =>
    SlidePageRoute<T>(
      child: Builder(builder: builder),
      settings: settings,
      beginOffset: begin,
    );

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final loginRoute = LoginRouter.onGenerateRoute(settings);
    if (loginRoute != null) return _wrapWithSlide(loginRoute, settings);

    final registerRoute = RegisterRouter.onGenerateRoute(settings);
    if (registerRoute != null) return _wrapWithSlide(registerRoute, settings);

    final mainRoute = MainRouter.onGenerateRoute(settings);
    if (mainRoute != null) return _wrapWithSlide(mainRoute, settings);

    final bookingRoute = BookingRouter.onGenerateRoute(settings);
    if (bookingRoute != null) return _wrapWithSlide(bookingRoute, settings);

    return _slide(
      settings: settings,
      builder: (_) => Scaffold(
        body: Center(
          child: Text('No route defined for ${settings.name}'),
        ),
      ),
    );
  }

  /// Wraps an existing MaterialPageRoute/CupertinoPageRoute with our
  /// custom slide transition by extracting its builder.
  static Route<dynamic> _wrapWithSlide(
    Route<dynamic> route,
    RouteSettings settings,
  ) {
    if (route is MaterialPageRoute) {
      return SlidePageRoute(
        child: Builder(builder: route.builder),
        settings: settings,
      );
    }
    // If it's already a custom route (e.g. PageRouteBuilder), keep it as-is
    return route;
  }

  static Future<T?> push<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
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

  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }

  AppRouter._();
}
