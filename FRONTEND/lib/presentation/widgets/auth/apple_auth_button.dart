import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/services/apple_auth_service.dart';
import '../../../core/utils/apple_auth_helper.dart';
import '../../../core/utils/google_auth_helper.dart' show GoogleAuthMode;
import '../../../core/utils/responsive_utils.dart';

/// "Sign in with Apple" / "Sign up with Apple" button. Renders nothing off iOS.
/// Includes its own top spacing so call sites can drop it in below Google.
class AppleAuthButton extends ConsumerWidget {
  final GoogleAuthMode mode;

  const AppleAuthButton({super.key, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppleAuthService.isSupported) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSignup = mode == GoogleAuthMode.signup;

    return Padding(
      padding: EdgeInsets.only(top: ResponsiveUtils.spacing(context, 12)),
      child: SignInWithAppleButton(
        text: isSignup ? 'Sign up with Apple' : 'Sign in with Apple',
        height: ResponsiveUtils.buttonHeight(context),
        style: isDark
            ? SignInWithAppleButtonStyle.white
            : SignInWithAppleButtonStyle.black,
        borderRadius: BorderRadius.circular(8),
        onPressed: () => AppleAuthHelper.signIn(context, ref, mode: mode),
      ),
    );
  }
}
