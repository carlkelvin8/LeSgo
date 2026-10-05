import 'package:lesgo/core/theme/app_colors.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/data_source/document_remote_datasource.dart';
import '../../../widgets/auth/register/verification_content.dart';
import '../../../widgets/common/camera_capture_screen.dart';

class IdentityOnboardingScreen extends ConsumerStatefulWidget {
  const IdentityOnboardingScreen({super.key});

  @override
  ConsumerState<IdentityOnboardingScreen> createState() =>
      _IdentityOnboardingScreenState();
}

class _IdentityOnboardingScreenState
    extends ConsumerState<IdentityOnboardingScreen> {
  XFile? _selfie;
  XFile? _validIdFront;
  XFile? _validIdBack;
  String _idType = '';
  String _idNumber = '';
  bool _isLoading = false;

  Future<void> _capture({
    required CameraLensDirection camera,
    required String title,
    required String helpText,
    required ValueChanged<XFile> onCaptured,
    required String successMessage,
  }) async {
    try {
      final photo = await capturePhotoWithCamera(
        context,
        lensDirection: camera,
        title: title,
        helpText: helpText,
      );
      if (!mounted) return;
      if (photo != null) {
        setState(() => onCaptured(photo));
        SnackBarUtils.showSuccess(context, successMessage);
      }
    } catch (_) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Hindi ma-open ang camera. I-allow ang Camera permission sa app settings at subukan ulit.',
        );
      }
    }
  }

  Future<void> _submit() async {
    final error = _validationError();
    if (error != null) {
      SnackBarUtils.showError(context, error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await getIt<DocumentRemoteDataSource>().submitIdentityOnboarding(
        selfie: _selfie!,
        idType: _idType,
        idNumber: _idNumber.trim(),
        validIdFront: _validIdFront!,
        validIdBack: _validIdBack!,
      );
      if (!mounted) return;
      SnackBarUtils.showSuccess(
        context,
        'Identity verification submitted for review.',
      );
      AppRouter.pushAndRemoveUntil(context, MainRoutes.home);
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        ApiErrorMapper.message(
          e,
          fallbackEn:
              'Could not submit identity verification. Please try again.',
          fallbackTl:
              'Hindi ma-submit ang identity verification. Subukan ulit.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validationError() {
    if (_selfie == null) return 'Kailangan munang kumuha ng live selfie.';
    if (_idType.isEmpty) return 'Pumili ng uri ng government ID.';
    if (_idNumber.trim().isEmpty) return 'Ilagay ang ID number.';
    if (_validIdFront == null) return 'Kunan ang harap ng government ID.';
    if (_validIdBack == null) return 'Kunan ang likod ng government ID.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isLoading) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface(context, Colors.white),
        body: SafeArea(
          child: VerificationContent(
            selfiePath: _selfie?.path ?? '',
            idType: _idType,
            idNumber: _idNumber,
            validIdFrontPath: _validIdFront?.path ?? '',
            validIdBackPath: _validIdBack?.path ?? '',
            isLoading: _isLoading,
            onCaptureSelfie: () => _capture(
              camera: CameraLensDirection.front,
              title: 'Live selfie',
              helpText: 'Center your face and look directly at the camera.',
              onCaptured: (file) => _selfie = file,
              successMessage: 'Selfie captured successfully!',
            ),
            onCaptureIdFront: () => _capture(
              camera: CameraLensDirection.back,
              title: 'Front of ID',
              helpText:
                  'Keep all four corners visible and make sure the details are readable.',
              onCaptured: (file) => _validIdFront = file,
              successMessage: 'Front of ID captured successfully!',
            ),
            onCaptureIdBack: () => _capture(
              camera: CameraLensDirection.back,
              title: 'Back of ID',
              helpText:
                  'Capture the back side of the same ID with all details readable.',
              onCaptured: (file) => _validIdBack = file,
              successMessage: 'Back of ID captured successfully!',
            ),
            onIdTypeChanged: (value) => setState(() => _idType = value),
            onIdNumberChanged: (value) => _idNumber = value,
            onNext: _submit,
          ),
        ),
      ),
    );
  }
}
