import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/responsive_utils.dart';
import '../../../provider/register/controller/otp_verification.controller.notifier.dart';
import '../../../provider/register/register_provider.dart';
import '../../../../core/constants/routers/register/register_routes.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../widgets/widgets.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  late final OtpVerificationControllers _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = OtpVerificationControllers();
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    await _controllers.sendOtp(context, ref);
  }

  Future<void> _handleContinue() async {
    final success = await _controllers.validateAndVerifyOtp(context, ref);

    if (success && mounted) {
      AppRouter.push(context, RegisterRoutes.verification);
    }
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final otpSent = registerState.otpSent;

    return Scaffold(
      backgroundColor: AppColors.surface(context, Colors.white),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthHeader(title: 'SIGN UP'),
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                      const OtpVerificationIllustration(),
                      OtpContactSection(
                        phoneController: _controllers.phoneController,
                        onResend: () => _controllers.resendOtp(context, ref),
                        otpSent: otpSent,
                      ),
                      if (otpSent) OtpCodeSection(controllers: _controllers),
                      const Spacer(),
                      OtpActions(
                        isLoading: registerState.isLoading,
                        onContinue: otpSent ? _handleContinue : _handleSendOtp,
                        text: otpSent ? 'Verify' : 'Send OTP',
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
