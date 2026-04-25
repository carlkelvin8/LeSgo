import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/utils.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/register/register_routes.dart';
import '../widgets.dart';

class RegisterContent extends ConsumerWidget {
  const RegisterContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      key: const ValueKey('register_buttons'),
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          text: 'Merchant',
          onPressed: () {
            // Navigate to Merchant Registration Screen
            AppRouter.push(context, RegisterRoutes.merchantRegister);
          },
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 14)),
        PrimaryButton(
          text: 'Rider',
          onPressed: () {
            // Navigate to Rider Registration Screen
            AppRouter.push(context, RegisterRoutes.riderRegister);
          },
        ),
      ],
    );
  }
}

class RegisterText extends StatelessWidget {
  const RegisterText({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('register_text'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Register',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 24),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
