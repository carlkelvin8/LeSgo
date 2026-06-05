import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/auth/auth_routes.dart';
import '../../../provider/auth/auth_provider.dart';
import '../../../provider/register/merchant/merchant_register_info_provider.dart';
import '../../../widgets/widgets.dart';

class MerchantRegisterCompleteScreen extends ConsumerWidget {
  const MerchantRegisterCompleteScreen({super.key});

  void _goToLogin(BuildContext context, WidgetRef ref) {
    ref.read(authViewProvider.notifier).state = AuthView.welcome;
    AppRouter.pushAndRemoveUntil(context, AuthRoutes.auth);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(merchantRegisterInfoProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                const MerchantCompleteHeader(),
                const MerchantCompleteIllustration(),
                MerchantCompleteInfoCard(
                  restaurantName: state.presentationRestaurantName,
                  address: state.presentationAddress,
                  email: state.presentationEmail,
                  contactNumber: state.presentationContactNumber,
                ),
                MerchantCompleteActionButtons(
                  onProceed: () => _goToLogin(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
