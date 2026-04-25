import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/utils.dart';
import '../../../provider/register/merchant/merchant_register_info_provider.dart';
import '../../../widgets/widgets.dart';

class MerchantRegisterCompleteScreen extends ConsumerWidget {
  const MerchantRegisterCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(merchantRegisterInfoProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    // Use presentation getters from state
    final restaurantName = state.presentationRestaurantName;
    final address = state.presentationAddress;
    final email = state.presentationEmail;
    final contact = state.presentationContactNumber;

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
                  restaurantName: restaurantName,
                  address: address,
                  email: email,
                  contactNumber: contact,
                ),
                MerchantCompleteActionButtons(
                  onProceed: () {
                    // TODO: Navigate to payment
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
