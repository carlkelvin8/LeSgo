import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/register/register_routes.dart';
import '../../../../core/services/api_service.dart';
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
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _licenseExpiryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(() {
      ref.read(registerInfoProvider.notifier).updateFirstName(_firstNameController.text);
    });
    _lastNameController.addListener(() {
      ref.read(registerInfoProvider.notifier).updateLastName(_lastNameController.text);
    });
    _birthdayController.addListener(() {
      ref.read(registerInfoProvider.notifier).updateBirthday(_birthdayController.text);
    });
    _emailController.addListener(() {
      ref.read(registerInfoProvider.notifier).updateEmail(_emailController.text);
    });
    _phoneNumberController.addListener(() {
      ref.read(registerInfoProvider.notifier).updatePhoneNumber(_phoneNumberController.text);
    });
    _passwordController.addListener(() {
      ref.read(registerInfoProvider.notifier).updatePassword(_passwordController.text);
    });
    _confirmPasswordController.addListener(() {
      ref.read(registerInfoProvider.notifier).updateConfirmPassword(_confirmPasswordController.text);
    });
    _licenseNumberController.addListener(() {
      ref.read(registerInfoProvider.notifier).updateLicenseNumber(_licenseNumberController.text);
    });
    _licenseExpiryController.addListener(() {
      final value = _licenseExpiryController.text.trim();
      ref.read(registerInfoProvider.notifier).updateLicenseExpiryDate(
            value.isEmpty ? null : value,
          );
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthdayController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final isFormFieldsValid = _formKey.currentState?.validate() ?? false;
    if (!isFormFieldsValid) {
      ref.read(registerInfoProvider.notifier).attemptSubmit(isFormFieldsValid: false);
      return;
    }

    // Phone must be provided
    final phone = _phoneNumberController.text.trim();
    if (phone.isEmpty || phone.length < 11) {
      SnackBarUtils.showError(context, 'Please enter a valid phone number');
      return;
    }

    // Show OTP verification before submitting
    _showOtpVerification(phone);
  }

  Future<void> _showOtpVerification(String phone) async {
    String normalizedPhone = phone;
    if (phone.startsWith('09')) {
      normalizedPhone = '+63${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      normalizedPhone = '+63$phone';
    }

    try {
      final response = await ApiService.dio.post('/v1/auth/otp/send', data: {
        'phone_number': normalizedPhone,
        'channel': 'sms',
      });

      final data = response.data;
      final fallbackOtp = data['otp'];

      if (!mounted) return;

      final verified = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => _RiderOtpBottomSheet(
          phone: normalizedPhone,
          fallbackOtp: fallbackOtp?.toString(),
        ),
      );

      if (verified == true && mounted) {
        ref.read(registerInfoProvider.notifier).attemptSubmit(isFormFieldsValid: true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to send OTP. Please try again.');
      }
    }
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
              phoneNumberController: _phoneNumberController,
              passwordController: _passwordController,
              confirmPasswordController: _confirmPasswordController,
              licenseNumberController: _licenseNumberController,
              licenseExpiryController: _licenseExpiryController,
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
              text: state.isSubmitting ? 'SUBMITTING...' : 'SUBMIT',
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting ? null : _handleSubmit,
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


/// OTP verification bottom sheet for rider registration
class _RiderOtpBottomSheet extends StatefulWidget {
  final String phone;
  final String? fallbackOtp;

  const _RiderOtpBottomSheet({required this.phone, this.fallbackOtp});

  @override
  State<_RiderOtpBottomSheet> createState() => _RiderOtpBottomSheetState();
}

class _RiderOtpBottomSheetState extends State<_RiderOtpBottomSheet> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      setState(() => _error = 'Please enter the OTP code');
      return;
    }

    setState(() { _isVerifying = true; _error = null; });

    try {
      final response = await ApiService.dio.post('/v1/auth/otp/verify', data: {
        'phone_number': widget.phone,
        'otp': otp,
      });

      final data = response.data;
      if (data['success'] == true && (data['valid'] == true || data['verified'] == true)) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() { _isVerifying = false; _error = data['message'] ?? 'Invalid OTP'; });
      }
    } catch (e) {
      setState(() { _isVerifying = false; _error = 'Verification failed'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Verify Phone Number', style: TextStyle(fontFamily: 'TT Fors', fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Enter the OTP code sent to ${widget.phone}', style: TextStyle(fontFamily: 'TT Fors', fontSize: 14, color: Colors.grey[600])),
          if (widget.fallbackOtp != null) ...[
            const SizedBox(height: 8),
            Text('Test OTP: ${widget.fallbackOtp}', style: const TextStyle(fontFamily: 'TT Fors', fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'TT Fors', fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '000000', counterText: '', errorText: _error,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5F2D82), width: 2)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isVerifying ? null : _verify,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5F2D82), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _isVerifying
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify OTP', style: TextStyle(fontFamily: 'TT Fors', fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
