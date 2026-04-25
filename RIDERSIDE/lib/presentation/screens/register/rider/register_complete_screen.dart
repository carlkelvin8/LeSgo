import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/utils.dart';
import '../../../provider/register/riderside/rider_register_info_provider.dart';
import '../../../widgets/widgets.dart';

class RegisterCompleteScreen extends ConsumerWidget {
  const RegisterCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final state = ref.watch(registerInfoProvider);

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
                  contactNumber: state.presentationContactNumber,
                ),
                ActionButtonsSection(
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
