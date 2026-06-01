import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../provider/auth/auth_provider.dart';
import '../../provider/auth/forgot_password_provider.dart';
import '../widgets.dart';

class ForgotPasswordContent extends ConsumerStatefulWidget {
  const ForgotPasswordContent({super.key});

  @override
  ConsumerState<ForgotPasswordContent> createState() =>
      _ForgotPasswordContentState();
}

class _ForgotPasswordContentState extends ConsumerState<ForgotPasswordContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goBackToLogin() {
    final returnView = ref.read(forgotPasswordReturnViewProvider);
    ref.read(forgotPasswordProvider.notifier).reset();
    ref.read(authViewProvider.notifier).state = returnView;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);

    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('forgot_password'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            state.step == ForgotPasswordStep.enterEmail
                ? 'Forgot Password?'
                : state.step == ForgotPasswordStep.verifyOtp
                    ? 'Verify OTP'
                    : 'Reset Password',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 22),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            state.step == ForgotPasswordStep.enterEmail
                ? 'Enter your email to receive an OTP code'
                : state.step == ForgotPasswordStep.verifyOtp
                    ? 'Enter the 6-digit code sent to ${_emailController.text}'
                    : 'Create a new password for your account',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          if (state.step == ForgotPasswordStep.enterEmail) ...[
            CustomTextField(
              hintText: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: LoginValidator.email,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            PrimaryButton(
              text: state.isLoading ? 'Sending...' : 'Send OTP',
              isLoading: state.isLoading,
              onPressed: state.isLoading ? null : _sendOtp,
            ),
          ],
          if (state.step == ForgotPasswordStep.verifyOtp) ...[
            CustomTextField(
              hintText: 'OTP Code (6 digits)',
              controller: _otpController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter OTP';
                }
                if (value.length != 6) {
                  return 'OTP must be 6 digits';
                }
                return null;
              },
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            Center(
              child: TextButton(
                onPressed: state.isLoading ? null : _resendOtp,
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    color: const Color(0xFF5F2D82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            PrimaryButton(
              text: state.isLoading ? 'Verifying...' : 'Verify OTP',
              isLoading: state.isLoading,
              onPressed: state.isLoading ? null : _verifyOtp,
            ),
          ],
          if (state.step == ForgotPasswordStep.resetPassword) ...[
            CustomTextField(
              hintText: 'New Password',
              controller: _passwordController,
              isPassword: true,
              validator: LoginValidator.password,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            CustomTextField(
              hintText: 'Confirm Password',
              controller: _confirmPasswordController,
              isPassword: true,
              validator: (value) =>
                  LoginValidator.confirmPassword(value, _passwordController.text),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            PrimaryButton(
              text: state.isLoading ? 'Resetting...' : 'Reset Password',
              isLoading: state.isLoading,
              onPressed: state.isLoading ? null : _resetPassword,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(forgotPasswordProvider.notifier)
        .sendOtp(_emailController.text.trim());
    if (!mounted) return;
    if (success) {
      SnackBarUtils.showSuccess(context, 'OTP sent to your email');
    } else {
      SnackBarUtils.showError(
        context,
        ref.read(forgotPasswordProvider).errorMessage ?? 'Failed to send OTP',
      );
    }
  }

  Future<void> _resendOtp() async {
    final success = await ref
        .read(forgotPasswordProvider.notifier)
        .resendOtp(_emailController.text.trim());
    if (!mounted) return;
    if (success) {
      SnackBarUtils.showSuccess(context, 'OTP resent to your email');
    } else {
      SnackBarUtils.showError(
        context,
        ref.read(forgotPasswordProvider).errorMessage ?? 'Failed to resend OTP',
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(forgotPasswordProvider.notifier).verifyOtp(
          _emailController.text.trim(),
          _otpController.text.trim(),
        );
    if (!mounted) return;
    if (success) {
      SnackBarUtils.showSuccess(context, 'OTP verified successfully');
    } else {
      SnackBarUtils.showError(
        context,
        ref.read(forgotPasswordProvider).errorMessage ?? 'Invalid or expired OTP',
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(forgotPasswordProvider.notifier).resetPassword(
          _emailController.text.trim(),
          _otpController.text.trim(),
          _passwordController.text,
        );
    if (!mounted) return;
    if (success) {
      SnackBarUtils.showSuccess(context, 'Password reset successfully');
      _goBackToLogin();
    } else {
      SnackBarUtils.showError(
        context,
        ref.read(forgotPasswordProvider).errorMessage ?? 'Failed to reset password',
      );
    }
  }
}
