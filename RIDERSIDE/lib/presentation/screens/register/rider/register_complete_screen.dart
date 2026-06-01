import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/register/register_routes.dart';
import '../../../../core/utils/phone_utils.dart';
import '../../../provider/register/riderside/rider_register_info_provider.dart';
import '../../../provider/register/riderside/rider_phone_verification_provider.dart';
import '../../../widgets/widgets.dart';

class RegisterCompleteScreen extends ConsumerWidget {
  const RegisterCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final state = ref.watch(registerInfoProvider);
    final phone = ref.watch(phoneVerificationProvider).phoneNumber;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                const HeaderSection(),
                const IllustrationSection(),
                InfoCardSection(
                  name: state.presentationName,
                  birthday: state.presentationBirthday,
                  email: state.presentationEmail,
                  contactNumber: phone.isNotEmpty
                      ? PhoneUtils.toInternational(phone)
                      : 'Not provided',
                ),
                ActionButtonsSection(
                  onProceed: () {
                    AppRouter.push(context, RegisterRoutes.riderPayment);
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
