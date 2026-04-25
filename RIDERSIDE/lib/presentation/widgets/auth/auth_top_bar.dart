import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/utils.dart';
import '../../provider/auth/auth_provider.dart';
import '../widgets.dart';

class AuthTopBar extends ConsumerWidget {
  const AuthTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authView = ref.watch(authViewProvider);
    final isWelcome = authView == AuthView.welcome;

    // Determine center widget based on auth view
    Widget centerWidget = switch (authView) {
      AuthView.login => const LoginText(),
      AuthView.riderLogin ||
      AuthView.merchantLogin => SvgPicture.asset(
            'assets/images/Logo.svg',
            height: ResponsiveUtils.imageHeight(context, 40),
            fit: BoxFit.contain,
          ),
      AuthView.register => const RegisterText(),
      AuthView.welcome => const WelcomeText(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: AnimatedOpacity(
        key: ValueKey(authView),
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: TopBar(
          centerWidget: centerWidget,
          showBackButton: !isWelcome,
          onBackPressed: () {
            final notifier = ref.read(authViewProvider.notifier);
            if (authView == AuthView.riderLogin ||
                authView == AuthView.merchantLogin) {
              notifier.state = AuthView.login;
            } else {
              notifier.state = AuthView.welcome;
            }
          },
        ),
      ),
    );
  }
}
