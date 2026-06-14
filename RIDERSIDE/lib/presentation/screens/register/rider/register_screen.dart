import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/register/register_routes.dart';
import '../../../provider/register/register_provider.dart';
import '../../../widgets/widgets.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final termsAccepted = ref.watch(termsAcceptedProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: ResponsiveUtils.spacing(context, 20)),

              TopBar(
                title: 'Register',
                onBackPressed: () {
                  ref.read(termsAcceptedProvider.notifier).state = false;
                  Navigator.of(context).pop();
                },
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 24)),

              const TermsHeader(),

              SizedBox(height: ResponsiveUtils.spacing(context, 20)),

              const Expanded(child: TermsScrollableContent()),

              SizedBox(height: ResponsiveUtils.spacing(context, 16)),

              TermsAcceptanceCheckbox(
                value: termsAccepted,
                onChanged: (value) {
                  ref.read(termsAcceptedProvider.notifier).state =
                      value ?? false;
                },
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 16)),

              PrimaryButton(
                text: 'Continue',
                onPressed: termsAccepted
                    ? () {
                        ref.read(hasAcceptedTermsProvider.notifier).state =
                            true;
                        AppRouter.push(context, RegisterRoutes.riderInfo);
                      }
                    : null,
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            ],
          ),
        ),
      ),
    );
  }
}
