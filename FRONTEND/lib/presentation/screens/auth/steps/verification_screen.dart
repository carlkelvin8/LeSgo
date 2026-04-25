import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/register/register_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../widgets/widgets.dart';
import '../../../../core/constants/routers/register/register_routes.dart';
import '../../../../core/constants/routers/app_router.dart';

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  Future<void> _handleStartVerification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await ref.read(registerProvider.notifier).captureSelfie();

    if (!context.mounted) return;

    if (result != null) {
      SnackBarUtils.showSuccess(context, 'Selfie captured successfully!');
    } else {
      final error = ref.read(registerProvider).error;
      if (error != null) {
        SnackBarUtils.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registerState = ref.watch(registerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: VerificationContent(
          selfiePath: registerState.data.selfiePath,
          isLoading: registerState.isLoading,
          onStart: () => _handleStartVerification(context, ref),
          onNext: () {
            AppRouter.push(context, RegisterRoutes.otpVerification);
          },
        ),
      ),
    );
  }
}
