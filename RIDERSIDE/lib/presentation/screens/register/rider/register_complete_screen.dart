import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/auth/auth_routes.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../provider/auth/auth_provider.dart';
import '../../../provider/auth/rider_auth_provider.dart';
import '../../../provider/register/riderside/rider_register_info_provider.dart';
import '../../../widgets/widgets.dart';

class RegisterCompleteScreen extends ConsumerWidget {
  const RegisterCompleteScreen({super.key});

  void _goToApp(BuildContext context, WidgetRef ref) {
    ref.read(registerInfoProvider.notifier).reset();

    if (ref.read(riderAuthProvider).isLoggedIn) {
      AppRouter.pushAndRemoveUntil(
        context,
        MainRoutes.registrationFeeStatus,
        arguments: {'target': MainRoutes.riderMain},
      );
      return;
    }

    ref.read(authViewProvider.notifier).state = AuthView.welcome;
    AppRouter.pushAndRemoveUntil(context, AuthRoutes.auth);
  }

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
                  onProceed: () => _goToApp(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
