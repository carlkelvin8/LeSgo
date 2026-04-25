import 'package:flutter/material.dart';
import 'auth/auth_router.dart';
import 'register/register_router.dart';
import 'main/main_router.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final authRoute = AuthRouter.onGenerateRoute(settings);
    if (authRoute != null) {
      return authRoute;
    }

    final registerRoute = RegisterRouter.onGenerateRoute(settings);
    if (registerRoute != null) {
      return registerRoute;
    }

    final mainRoute = MainRouter.onGenerateRoute(settings);
    if (mainRoute != null) {
      return mainRoute;
    }

    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text('No route defined for ${settings.name}'),
        ),
      ),
    );
  }

  static Future<T?> push<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  static Future<T?> pushReplacement<T, TO>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed<T, TO>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  static Future<T?> pushAndRemoveUntil<T>(BuildContext context, String routeName, {Object? arguments}) {
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
