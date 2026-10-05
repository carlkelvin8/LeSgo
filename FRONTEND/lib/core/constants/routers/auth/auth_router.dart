import 'package:flutter/material.dart';
import '../../../../presentation/screens/auth/welcome_screen.dart';
import '../../../../presentation/screens/auth/login_screen.dart';
import '../../../../presentation/screens/auth/auth_startup_screen.dart';
import 'auth_routes.dart';

class LoginRouter {
  static final Map<String, WidgetBuilder> _routes = {
    LoginRoutes.startup: (_) => const AuthStartupScreen(),
    LoginRoutes.welcome: (_) => const WelcomeScreen(),
    LoginRoutes.login: (_) => const LoginScreen(),
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
  
  LoginRouter._();
}
