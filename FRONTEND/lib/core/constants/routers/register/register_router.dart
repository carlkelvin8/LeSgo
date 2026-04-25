import 'package:flutter/material.dart';
import '../../../../presentation/screens/auth/register_screen.dart';
import '../../../../presentation/screens/auth/steps/terms_of_service_screen.dart';
import '../../../../presentation/screens/auth/steps/personal_info_screen.dart';
import '../../../../presentation/screens/auth/steps/verification_screen.dart';
import '../../../../presentation/screens/auth/steps/otp_verification_screen.dart';
import '../../../../presentation/screens/auth/steps/address_screen.dart';
import '../../../../presentation/screens/auth/steps/success_screen.dart';
import 'register_routes.dart';

class RegisterRouter {
  static final Map<String, WidgetBuilder> _routes = {
    // Registration flow
    RegisterRoutes.register: (_) => const RegisterScreen(),
    RegisterRoutes.termsOfService: (_) => const TermsOfServiceScreen(),
    RegisterRoutes.personalInfo: (_) => const PersonalInfoScreen(),
    RegisterRoutes.verification: (_) => const VerificationScreen(),
    RegisterRoutes.otpVerification: (_) => const OtpVerificationScreen(),
    RegisterRoutes.address: (_) => const AddressScreen(),
    RegisterRoutes.success: (_) => const CongratulationsScreen(),
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
  
  RegisterRouter._();
}
