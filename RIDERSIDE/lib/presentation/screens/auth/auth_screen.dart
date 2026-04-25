import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/utils.dart';
import '../../provider/auth/auth_provider.dart';
import '../../widgets/widgets.dart';

import 'package:flutter/services.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authView = ref.watch(authViewProvider);
    final isWelcome = authView == AuthView.welcome;
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return PopScope(
      canPop: isWelcome,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !isWelcome) {
          if (authView == AuthView.riderLogin ||
              authView == AuthView.merchantLogin) {
            ref.read(authViewProvider.notifier).state = AuthView.login;
          } else {
            ref.read(authViewProvider.notifier).state = AuthView.welcome;
          }
        } else if (didPop && isWelcome) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: ResponsiveUtils.spacing(context, 40),
                          ),

                          // Top bar with logo + back button
                          const AuthTopBar(),

                          const Spacer(flex: 2),

                          // Circular illustration
                          const AuthIllustration(),

                          const Spacer(flex: 2),

                          const Spacer(flex: 1),

                          // Animated buttons section
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.2),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: switch (authView) {
                              AuthView.merchantLogin =>
                                const MerchantLoginContent(),
                              AuthView.riderLogin => const RiderLoginContent(),
                              AuthView.login => const LoginContent(),
                              AuthView.register => const RegisterContent(),
                              AuthView.welcome => const WelcomeContent(),
                            },
                          ),

                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
