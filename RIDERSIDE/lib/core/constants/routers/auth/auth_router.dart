import 'package:flutter/material.dart';
import '../../../../presentation/screens/auth/auth_screen.dart';
import '../../../../presentation/screens/auth/auth_startup_screen.dart';
import 'auth_routes.dart';

class AuthRouter {
  static final Map<String, WidgetBuilder> _routes = {
    AuthRoutes.startup: (_) => const AuthStartupScreen(),
    AuthRoutes.auth: (_) => const AuthScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = _routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }
    return null;
  }

  AuthRouter._();
}
