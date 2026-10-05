import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/utils.dart';
import '../../provider/auth/auth_provider.dart';

class AuthIllustration extends ConsumerWidget {
  const AuthIllustration({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authView = ref.watch(authViewProvider);
    final isRiderLogin = authView == AuthView.riderLogin;
    final isMerchantLogin = authView == AuthView.merchantLogin;

    return Container(
      width: ResponsiveUtils.spacing(context, 340),
      height: ResponsiveUtils.spacing(context, 340),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF2F2F7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: isRiderLogin
              ? SvgPicture.asset(
                  'assets/images/Lesgo.svg',
                  key: const ValueKey('lesgo_illustration'),
                  height: ResponsiveUtils.imageHeight(context, 280),
                  fit: BoxFit.contain,
                )
              : isMerchantLogin
                  ? SvgPicture.asset(
                      'assets/images/merchant.svg',
                      key: const ValueKey('merchant_illustration'),
                      height: ResponsiveUtils.imageHeight(context, 280),
                      fit: BoxFit.contain,
                    )
              : SvgPicture.asset(
                  'assets/images/Logo.svg',
                  key: const ValueKey('logo_illustration'),
                  height: ResponsiveUtils.imageHeight(context, 140),
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}
