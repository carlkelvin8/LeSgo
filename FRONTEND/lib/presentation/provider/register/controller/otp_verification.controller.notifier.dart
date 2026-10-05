import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/validators/otp_validator.dart';
import '../register_provider.dart';

class OtpVerificationControllers {
  final TextEditingController phoneController;
  final List<TextEditingController> otpControllers;

  OtpVerificationControllers()
    : phoneController = TextEditingController(text: '+63 '),
      otpControllers = List.generate(6, (index) => TextEditingController());

  /// Send OTP to the phone number
  Future<void> sendOtp(BuildContext context, WidgetRef ref) async {
    final phoneNumber = phoneController.text.trim();
    final error = OtpValidator.phoneNumber(phoneNumber);

    if (error != null) {
      SnackBarUtils.showWarning(context, error);
      return;
    }

    final success = await ref
        .read(registerProvider.notifier)
        .sendOtp(phoneNumber);

    if (!context.mounted) return;

    if (success) {
      // Check if there's a fallback OTP message in the error field
      final stateError = ref.read(registerProvider).error;
      if (stateError != null && stateError.contains('Your OTP is')) {
        SnackBarUtils.showSuccess(context, stateError);
      } else {
        SnackBarUtils.showSuccess(context, 'OTP sent to $phoneNumber');
      }
    } else {
      final stateError = ref.read(registerProvider).error;
      if (stateError != null) {
        SnackBarUtils.showError(context, stateError);
      }
    }
  }

  /// Resend OTP to the phone number
  Future<void> resendOtp(BuildContext context, WidgetRef ref) async {
    final phoneNumber = phoneController.text.trim();
    final error = OtpValidator.phoneNumber(phoneNumber);

    if (error != null) {
      SnackBarUtils.showWarning(context, error);
      return;
    }

    final success = await ref
        .read(registerProvider.notifier)
        .resendOtp(phoneNumber);

    if (!context.mounted) return;

    if (success) {
      SnackBarUtils.showSuccess(context, 'OTP sent to $phoneNumber');
    } else {
      final stateError = ref.read(registerProvider).error;
      if (stateError != null) {
        SnackBarUtils.showError(context, stateError);
      }
    }
  }

  /// Validate and verify OTP
  Future<bool> validateAndVerifyOtp(BuildContext context, WidgetRef ref) async {
    final phoneNumber = phoneController.text.trim();
    final otp = otpControllers.map((c) => c.text).join();

    // Validate phone number
    final phoneError = OtpValidator.phoneNumber(phoneNumber);
    if (phoneError != null) {
      SnackBarUtils.showWarning(context, phoneError);
      return false;
    }

    // Validate OTP
    final otpError = OtpValidator.otpCode(otp);
    if (otpError != null) {
      SnackBarUtils.showWarning(context, otpError);
      return false;
    }

    // Update phone number in provider
    ref.read(registerProvider.notifier).updatePhoneNumber(phoneNumber);

    // Verify OTP
    final success = await ref.read(registerProvider.notifier).verifyOtp(otp);

    if (!context.mounted) return false;

    if (!success) {
      final stateError = ref.read(registerProvider).error;
      if (stateError != null) {
        SnackBarUtils.showError(context, stateError);
      }
    }

    return success;
  }

  void dispose() {
    phoneController.dispose();
    for (var controller in otpControllers) {
      controller.dispose();
    }
  }
}
