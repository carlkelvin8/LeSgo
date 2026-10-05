import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/services/api_service.dart';

import '../../../provider/register/merchant/merchant_register_info_provider.dart';
import '../../../widgets/global/primary_button.dart';
import '../../../widgets/global/register_scaffold.dart';
import '../../../widgets/register/merchant/info/merchant_document_upload_list.dart';
import '../../../widgets/register/merchant/info/merchant_info_form_fields.dart';
import 'merchant_terms_screen.dart';
import '../registration_terms_gate.dart';

class MerchantRegisterScreen extends ConsumerStatefulWidget {
  const MerchantRegisterScreen({super.key});

  @override
  ConsumerState<MerchantRegisterScreen> createState() =>
      _MerchantRegisterScreenState();
}

class _MerchantRegisterScreenState
    extends ConsumerState<MerchantRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantNameController = TextEditingController();
  final _ownerFirstNameController = TextEditingController();
  final _ownerLastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restaurantNameController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updateRestaurantName(_restaurantNameController.text);
    });
    _ownerFirstNameController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updateOwnerFirstName(_ownerFirstNameController.text);
    });
    _ownerLastNameController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updateOwnerLastName(_ownerLastNameController.text);
    });
    _emailController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updateEmail(_emailController.text);
    });
    _contactNumberController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updateContactNumber(_contactNumberController.text);
    });
    _addressController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updateAddress(_addressController.text);
    });
    _zipCodeController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updateZipCode(_zipCodeController.text);
    });
    _passwordController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updatePassword(_passwordController.text);
    });
    _confirmPasswordController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updateConfirmPassword(_confirmPasswordController.text);
    });
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _ownerFirstNameController.dispose();
    _ownerLastNameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _zipCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!ref.read(merchantRegisterInfoProvider).termsAccepted) return;
    // Trigger visual validation in UI
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ref.read(merchantRegisterInfoProvider.notifier).attemptSubmit();
      return;
    }

    // Phone must be provided
    final phone = _contactNumberController.text.trim();
    if (phone.isEmpty || phone.length < 11) {
      SnackBarUtils.showError(context, 'Please enter a valid phone number');
      return;
    }

    // Show OTP verification bottom sheet before submitting
    _showOtpVerification(phone);
  }

  Future<void> _showOtpVerification(String phone) async {
    // Normalize phone to E.164
    String normalizedPhone = phone;
    if (phone.startsWith('09')) {
      normalizedPhone = '+63${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      normalizedPhone = '+63$phone';
    }

    // Send OTP
    try {
      final response = await ApiService.dio.post(
        '/v1/auth/otp/send',
        data: {'phone_number': normalizedPhone, 'channel': 'sms'},
      );

      final data = response.data;
      final fallbackOtp = data['otp']; // For fallback/testing mode

      if (!mounted) return;

      // Show OTP input dialog
      final verified = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => _OtpBottomSheet(
          phone: normalizedPhone,
          fallbackOtp: fallbackOtp?.toString(),
        ),
      );

      if (verified != null && verified.isNotEmpty && mounted) {
        ref.read(merchantRegisterInfoProvider.notifier).setPhoneProof(verified);
        // OTP verified — proceed with actual registration
        ref.read(merchantRegisterInfoProvider.notifier).attemptSubmit();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Failed to send OTP. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(merchantRegisterInfoProvider);
    final controller = ref.read(merchantRegisterInfoProvider.notifier);

    ref.listen<MerchantRegisterInfoState>(merchantRegisterInfoProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage != null) {
        SnackBarUtils.showError(context, next.errorMessage!);
        controller.clearError();
      }
      if (next.isSubmitted && previous?.isSubmitted != true) {
        AppRouter.pushAndRemoveUntil(
          context,
          MainRoutes.registrationFeeStatus,
          arguments: {'target': MainRoutes.merchantMain},
        );
      }
    });

    return RegistrationTermsGate(
      isSubmitting: state.isSubmitting,
      onConsentChanged: controller.setTermsAccepted,
      termsBuilder: (accept) => MerchantTermsScreen(onAccepted: accept),
      formBuilder: (reviewTerms) => _buildForm(state, controller, reviewTerms),
    );
  }

  Widget _buildForm(
    MerchantRegisterInfoState state,
    MerchantRegisterInfoNotifier controller,
    VoidCallback reviewTerms,
  ) {
    return RegisterScaffold(
      title: 'Register',
      onBackPressed: reviewTerms,
      headerBottomSpacing: 24,
      body: Form(
        key: _formKey,
        autovalidateMode: state.hasAttemptedSubmit
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: state.isSubmitting ? null : reviewTerms,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Review Merchant Terms & Conditions'),
            ),
            // Store Illustration (Placeholder)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF9B59F0), width: 2),
                ),
                child: SvgPicture.asset(
                  'assets/images/register/10.svg', // Assuming 10.svg is store
                  height: ResponsiveUtils.imageHeight(context, 180),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 32)),

            MerchantInfoFormFields(
              restaurantNameController: _restaurantNameController,
              ownerFirstNameController: _ownerFirstNameController,
              ownerLastNameController: _ownerLastNameController,
              emailController: _emailController,
              contactNumberController: _contactNumberController,
              addressController: _addressController,
              zipCodeController: _zipCodeController,
              passwordController: _passwordController,
              confirmPasswordController: _confirmPasswordController,
              latitude: state.info.latitude,
              longitude: state.info.longitude,
              showPinError:
                  state.hasAttemptedSubmit && !state.info.hasPinLocation,
              onLocationChanged: controller.updateLocation,
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            MerchantDocumentUploadList(
              onUploadSelfie: controller.uploadSelfie,
              onUploadValidId: controller.uploadValidId,
              onUploadDigitalSignature: controller.uploadDigitalSignature,
              onUploadBarangayPermit: controller.uploadBarangayPermit,
              onUploadMayorsPermit: controller.uploadMayorsPermit,
              onUploadDtiPermit: controller.uploadDtiPermit,
              isSelfieLoading: state.isSelfieLoading,
              isValidIdLoading: state.isValidIdLoading,
              isSignatureLoading: state.isSignatureLoading,
              isBarangayPermitLoading: state.isBarangayPermitLoading,
              isMayorsPermitLoading: state.isMayorsPermitLoading,
              isDtiPermitLoading: state.isDtiPermitLoading,
              selfiePath: state.documents.selfiePath,
              validIdPath: state.documents.validIdPath,
              digitalSignaturePath: state.documents.digitalSignaturePath,
              barangayPermitPath: state.documents.barangayPermitPath,
              mayorsPermitPath: state.documents.mayorsPermitPath,
              dtiPermitPath: state.documents.dtiPermitPath,
              showError: state.hasAttemptedSubmit,
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 32)),

            PrimaryButton(
              text: 'Continue to payment',
              onPressed: state.isSubmitting ? () {} : _handleSubmit,
              isLoading: state.isSubmitting,
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'We appreciate your application and are excited to welcome you aboard!\n\nPlease allow us 24 to 48 hours to carefully review your details.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 32)),
          ],
        ),
      ),
    );
  }
}

/// OTP verification bottom sheet for merchant registration
class _OtpBottomSheet extends StatefulWidget {
  final String phone;
  final String? fallbackOtp;

  const _OtpBottomSheet({required this.phone, this.fallbackOtp});

  @override
  State<_OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<_OtpBottomSheet> {
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

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final response = await ApiService.dio.post(
        '/v1/auth/otp/verify',
        data: {'phone_number': widget.phone, 'otp': otp},
      );

      final data = response.data;
      if (data['success'] == true &&
          (data['valid'] == true || data['verified'] == true)) {
        final proof = data['phone_verification_token']?.toString();
        if (proof == null || proof.isEmpty) {
          throw StateError(
            'Verification proof missing. Please request another code.',
          );
        }
        if (mounted) Navigator.pop(context, proof);
      } else {
        setState(() {
          _isVerifying = false;
          _error = data['message'] ?? 'Invalid OTP code';
        });
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _error = 'Verification failed. Please try again.';
      });
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
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Verify Phone Number',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the OTP code sent to ${widget.phone}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (widget.fallbackOtp != null && AppConfig.isDevMode) ...[
            const SizedBox(height: 8),
            Text(
              'Test OTP: ${widget.fallbackOtp}',
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: '000000',
              counterText: '',
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF5F2D82),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isVerifying ? null : _verify,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isVerifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
