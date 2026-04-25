import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/utils.dart';
import '../../provider/auth/auth_provider.dart';
import '../widgets.dart';

class WelcomeContent extends ConsumerWidget {
  const WelcomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      key: const ValueKey('welcome_buttons'),
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          text: 'Login',
          onPressed: () =>
              ref.read(authViewProvider.notifier).state = AuthView.login,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 14)),
        PrimaryButton(
          text: 'Register',
          onPressed: () =>
              ref.read(authViewProvider.notifier).state = AuthView.register,
        ),
      ],
    );
  }
}

class WelcomeText extends StatelessWidget {
  const WelcomeText({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('welcome_text'),
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 30),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.3,
            ),
            children: const [
              TextSpan(text: 'Grow, Enjoy and\n'),
              TextSpan(
                text: 'Earn',
                style: TextStyle(color: Color(0xFF7B3FE4)),
              ),
              TextSpan(text: '!'),
            ],
          ),
        ),
      ],
    );
  }
}
