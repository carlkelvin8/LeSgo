import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/register/register_routes.dart';
import '../../../provider/register/riderside/rider_register_info_provider.dart';
import '../../../widgets/widgets.dart';

class RegisterInfoScreen extends ConsumerStatefulWidget {
  const RegisterInfoScreen({super.key});

  @override
  ConsumerState<RegisterInfoScreen> createState() => _RegisterInfoScreenState();
}

class _RegisterInfoScreenState extends ConsumerState<RegisterInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(() {
      ref
          .read(registerInfoProvider.notifier)
          .updateFirstName(_firstNameController.text);
    });
    _lastNameController.addListener(() {
      ref
          .read(registerInfoProvider.notifier)
          .updateLastName(_lastNameController.text);
    });
    _birthdayController.addListener(() {
      ref
          .read(registerInfoProvider.notifier)
          .updateBirthday(_birthdayController.text);
    });
    _emailController.addListener(() {
      ref
          .read(registerInfoProvider.notifier)
          .updateEmail(_emailController.text);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthdayController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final isFormFieldsValid = _formKey.currentState?.validate() ?? false;
    ref
        .read(registerInfoProvider.notifier)
        .attemptSubmit(isFormFieldsValid: isFormFieldsValid);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerInfoProvider);
    final controller = ref.read(registerInfoProvider.notifier);

    ref.listen<RegisterInfoState>(registerInfoProvider, (previous, next) {
      if (next.errorMessage != null) {
        SnackBarUtils.showError(context, next.errorMessage!);
        controller.clearError();
      }
      if (next.isSubmitted) {
        AppRouter.push(context, RegisterRoutes.riderComplete);
      }
    });

    return RegisterScaffold(
      title: 'Register',
      headerBottomSpacing: 24,
      body: Form(
        key: _formKey,
        autovalidateMode: state.hasAttemptedSubmit
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InfoIllustration(),
            SizedBox(height: ResponsiveUtils.spacing(context, 32)),

            InfoFormFields(
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              birthdayController: _birthdayController,
              emailController: _emailController,
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            const InfoMessage(),
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            SelfieUploadSection(
              label: 'Selfie for Verification',
              buttonText: 'Upload',
              onUploadPressed: controller.uploadSelfie,
              isLoading: state.isSelfieLoading,
              imagePath: state.selfieImagePath,
              showError: state.hasAttemptedSubmit,
            ),
            SelfieUploadSection(
              label: 'Selfie with motorcycle',
              buttonText: 'Upload',
              onUploadPressed: controller.uploadSelfieWithMotorcycle,
              isLoading: state.isSelfieMotorcycleLoading,
              imagePath: state.selfieWithMotorcycleImagePath,
              showError: state.hasAttemptedSubmit,
            ),

            DocumentUploadList(
              onUploadResume: controller.uploadResume,
              onUploadBarangayClearance: controller.uploadBarangayClearance,
              onUploadDriversLicense: controller.uploadDriversLicense,
              onUploadMotorcycleORCRImage: controller.uploadMotorcycleORCRImage,
              onUploadScannedORCR: controller.uploadScannedORCR,
              onUploadDigitalSignature: controller.uploadDigitalSignature,
              isResumeLoading: state.isResumeLoading,
              isClearanceLoading: state.isClearanceLoading,
              isLicenseLoading: state.isLicenseLoading,
              isMotorcycleImageLoading: state.isMotorcycleImageLoading,
              isScannedORCRLoading: state.isScannedORCRLoading,
              isSignatureLoading: state.isSignatureLoading,
              resumeFilePath: state.resumeFilePath,
              barangayClearanceFilePath: state.barangayClearanceFilePath,
              driversLicenseFilePath: state.driversLicenseFilePath,
              motorcycleORCRImagePath: state.motorcycleORCRImagePath,
              scannedORCRFilePath: state.scannedORCRFilePath,
              digitalSignatureFilePath: state.digitalSignatureFilePath,
              showError: state.hasAttemptedSubmit,
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 4)),
            PrimaryButton(
              text: 'SUBMIT',
              onPressed: state.isSubmitting ? () {} : _handleSubmit,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            const SubmitInfoText(),
            SizedBox(height: ResponsiveUtils.spacing(context, 32)),
          ],
        ),
      ),
    );
  }
}
