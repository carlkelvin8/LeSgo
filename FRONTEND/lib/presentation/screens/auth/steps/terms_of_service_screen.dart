import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/register/register_provider.dart';
import '../../../widgets/widgets.dart';
import '../../../../core/constants/routers/register/register_routes.dart';
import '../../../../core/constants/routers/app_router.dart';

class TermsOfServiceScreen extends ConsumerWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: Theme.of(context).copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(const Color(0xFF7C3AED)),
          thickness: WidgetStateProperty.all(3),
          radius: const Radius.circular(0),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Builder(
            builder: (context) {
              return TermsContent(
                onAccept: () {
                  ref.read(registerProvider.notifier).acceptTerms();
                  AppRouter.push(context, RegisterRoutes.personalInfo);
                },
                onDecline: () => Navigator.of(context).pop(),
              );
            },
          ),
        ),
      ),
    );
  }
}
