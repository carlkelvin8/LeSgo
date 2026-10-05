import 'package:flutter/material.dart';
import '../../../../presentation/screens/register/rider/register_screen.dart';
import '../../../../presentation/screens/register/rider/register_info_screen.dart';
import '../../../../presentation/screens/register/rider/register_complete_screen.dart';
import '../../../../presentation/screens/register/merchant/merchant_register_screen.dart';
import '../../../../presentation/screens/register/merchant/merchant_register_complete_screen.dart';
import 'register_routes.dart';

class RegisterRouter {
  static final Map<String, WidgetBuilder> _routes = {
    RegisterRoutes.riderRegister: (_) => const RegisterScreen(),
    // Legacy route: OTP step removed — go straight to info form.
    RegisterRoutes.riderPhoneVerification: (_) => const RegisterInfoScreen(),
    RegisterRoutes.riderInfo: (_) => const RegisterInfoScreen(),
    RegisterRoutes.riderComplete: (_) => const RegisterCompleteScreen(),
    RegisterRoutes.merchantRegister: (_) => const MerchantRegisterScreen(),
    RegisterRoutes.merchantComplete: (_) => const MerchantRegisterCompleteScreen(),
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

  RegisterRouter._();
}
