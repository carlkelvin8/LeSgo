import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/utils.dart';
import '../../provider/auth/auth_provider.dart';
import '../widgets.dart';

class LoginContent extends ConsumerWidget {
  const LoginContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      key: const ValueKey('login_buttons'),
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          text: 'Merchant',
          onPressed: () => ref.read(authViewProvider.notifier).state =
              AuthView.merchantLogin,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 14)),
        PrimaryButton(
          text: 'Rider',
          onPressed: () =>
              ref.read(authViewProvider.notifier).state = AuthView.riderLogin,
        ),
      ],
    );
  }
}

class LoginText extends StatelessWidget {
  const LoginText({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('login_text'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Login',
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
