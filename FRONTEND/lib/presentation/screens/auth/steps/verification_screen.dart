import 'package:lesgo/core/theme/app_colors.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/register/register_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/common/camera_capture_screen.dart';
import '../../../../core/constants/routers/register/register_routes.dart';
import '../../../../core/constants/routers/app_router.dart';

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  Future<void> _handleCapture(
    BuildContext context,
    CameraLensDirection lensDirection,
    String title,
    String helpText,
    ValueChanged<String> onCaptured,
    String successMessage,
  ) async {
    final result = await capturePhotoWithCamera(
      context,
      lensDirection: lensDirection,
      title: title,
      helpText: helpText,
    );

    if (!context.mounted) return;

    if (result != null) {
      onCaptured(result.path);
      SnackBarUtils.showSuccess(context, successMessage);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registerState = ref.watch(registerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface(context, Colors.white),
      body: SafeArea(
        child: VerificationContent(
          selfiePath: registerState.data.selfiePath,
          idType: registerState.data.idType,
          idNumber: registerState.data.idNumber,
          validIdFrontPath: registerState.data.validIdFrontPath,
          validIdBackPath: registerState.data.validIdBackPath,
          isLoading: registerState.isLoading,
          onCaptureSelfie: () => _handleCapture(
            context,
            CameraLensDirection.front,
            'Live selfie',
            'Center your face and look directly at the camera.',
            ref.read(registerProvider.notifier).updateSelfie,
            'Selfie captured successfully!',
          ),
          onCaptureIdFront: () => _handleCapture(
            context,
            CameraLensDirection.back,
            'Front of ID',
            'Keep all four corners visible and make sure the details are readable.',
            ref.read(registerProvider.notifier).updateValidIdFront,
            'Front of ID captured successfully!',
          ),
          onCaptureIdBack: () => _handleCapture(
            context,
            CameraLensDirection.back,
            'Back of ID',
            'Capture the back side of the same ID with all details readable.',
            ref.read(registerProvider.notifier).updateValidIdBack,
            'Back of ID captured successfully!',
          ),
          onIdTypeChanged: ref.read(registerProvider.notifier).updateIdType,
          onIdNumberChanged: ref.read(registerProvider.notifier).updateIdNumber,
          onNext: () {
            final error = ref
                .read(registerProvider.notifier)
                .validateIdentityVerification();
            if (error != null) {
              SnackBarUtils.showError(context, error);
              return;
            }
            AppRouter.push(context, RegisterRoutes.address);
          },
        ),
      ),
    );
  }
}
