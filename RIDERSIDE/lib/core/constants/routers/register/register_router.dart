import 'package:flutter/material.dart';
import '../../../../presentation/screens/register/rider/register_screen.dart';
import '../../../../presentation/screens/register/rider/register_phone_verification_screen.dart';
import '../../../../presentation/screens/register/rider/register_info_screen.dart';
import '../../../../presentation/screens/register/rider/register_complete_screen.dart';
import '../../../../presentation/screens/register/merchant/merchant_register_screen.dart';
import '../../../../presentation/screens/register/merchant/merchant_register_complete_screen.dart';
import '../../../../presentation/screens/register/register_payment_screen.dart';
import '../../../../presentation/provider/register/register_payment_provider.dart';
import 'register_routes.dart';

class RegisterRouter {
  static final Map<String, WidgetBuilder> _routes = {
    RegisterRoutes.riderRegister: (_) => const RegisterScreen(),
    RegisterRoutes.riderPhoneVerification: (_) => const RegisterPhoneVerificationScreen(),
    RegisterRoutes.riderInfo: (_) => const RegisterInfoScreen(),
    RegisterRoutes.riderComplete: (_) => const RegisterCompleteScreen(),
    RegisterRoutes.riderPayment: (_) => const RegisterPaymentScreen(
          role: RegisterPaymentRole.rider,
        ),
    RegisterRoutes.merchantRegister: (_) => const MerchantRegisterScreen(),
    RegisterRoutes.merchantComplete: (_) => const MerchantRegisterCompleteScreen(),
    RegisterRoutes.merchantPayment: (_) => const RegisterPaymentScreen(
          role: RegisterPaymentRole.merchant,
        ),
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
