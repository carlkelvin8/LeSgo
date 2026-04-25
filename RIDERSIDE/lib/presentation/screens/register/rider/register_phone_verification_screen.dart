import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/register/register_routes.dart';
import '../../../provider/register/riderside/rider_phone_verification_provider.dart';
import '../../../widgets/widgets.dart';

class RegisterPhoneVerificationScreen extends ConsumerStatefulWidget {
  const RegisterPhoneVerificationScreen({super.key});

  @override
  ConsumerState<RegisterPhoneVerificationScreen> createState() =>
      _RegisterPhoneVerificationScreenState();
}

class _RegisterPhoneVerificationScreenState
    extends ConsumerState<RegisterPhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  late final List<TextEditingController> _otpControllers;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(4, (index) => TextEditingController());
    _phoneController.addListener(() {
      ref
          .read(phoneVerificationProvider.notifier)
          .updatePhoneNumber(_phoneController.text);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOTP() async {
    await ref.read(phoneVerificationProvider.notifier).sendOTP();
  }

  Future<void> _resendOTP() async {
    await ref.read(phoneVerificationProvider.notifier).resendOTP();
  }

  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();

    final success = await ref
        .read(phoneVerificationProvider.notifier)
        .verifyOTP(otp);

    if (success && mounted) {
      AppRouter.push(context, RegisterRoutes.riderInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(phoneVerificationProvider);

    ref.listen<PhoneVerificationState>(phoneVerificationProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage != null) {
        SnackBarUtils.showError(context, next.errorMessage!);
        ref.read(phoneVerificationProvider.notifier).clearError();
      }
    });

    return RegisterScaffold(
      title: 'Register',
      onBackPressed: () {
        ref.read(phoneVerificationProvider.notifier).reset();
        Navigator.of(context).pop();
      },
      bottomWidget: verificationState.otpSent
          ? PrimaryButton(
              text: verificationState.isLoading ? 'Verifying...' : 'Continue',
              onPressed: verificationState.isLoading ? null : _verifyOTP,
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const PhoneVerificationIllustration(),
          SizedBox(height: ResponsiveUtils.spacing(context, 40)),

          PhoneVerificationForm(
            phoneController: _phoneController,
            otpControllers: _otpControllers,
            otpSent: verificationState.otpSent,
            isLoading: verificationState.isLoading,
            isPhoneNumberValid: verificationState.isPhoneNumberValid,
            onSendOTP: _sendOTP,
            onResendOTP: _resendOTP,
          ),

          SizedBox(height: ResponsiveUtils.spacing(context, 32)),
        ],
      ),
    );
  }
}
