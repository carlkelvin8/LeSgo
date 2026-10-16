import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/data_source/auth_remote_datasource.dart';
import '../../provider/main/profile/profile_provider.dart';

/// Bottom sheet to change the profile phone number with OTP verification.
class ChangePhoneSheet extends ConsumerStatefulWidget {
  final String currentPhone;

  const ChangePhoneSheet({super.key, required this.currentPhone});

  static Future<void> show(BuildContext context, String currentPhone) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context, Colors.white),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ChangePhoneSheet(currentPhone: currentPhone),
      ),
    );
  }

  @override
  ConsumerState<ChangePhoneSheet> createState() => _ChangePhoneSheetState();
}

class _ChangePhoneSheetState extends ConsumerState<ChangePhoneSheet> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;

  String _normalizePhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('+')) return trimmed.replaceAll(' ', '');

    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('63') && digits.length >= 12) {
      return '+$digits';
    }
    if (digits.startsWith('0') && digits.length >= 11) {
      return '+63${digits.substring(1)}';
    }
    return '+63$digits';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _normalizePhone(_phoneController.text);
    if (phone.length < 13) {
      SnackBarUtils.showError(context, 'Enter a valid Philippine mobile number');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await getIt<AuthRemoteDataSource>().sendOtp(phone);
      if (!mounted) return;
      if (response.success) {
        setState(() => _otpSent = true);
        SnackBarUtils.showSuccess(context, 'OTP sent to $phone');
      } else {
        SnackBarUtils.showError(context, response.message);
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Failed to send OTP: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndSave() async {
    final phone = _normalizePhone(_phoneController.text);
    final otp = _otpController.text.trim();

    if (!_otpSent) {
      SnackBarUtils.showError(context, 'Send OTP first');
      return;
    }
    if (otp.length < 4) {
      SnackBarUtils.showError(context, 'Enter the OTP code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final verifyResponse =
          await getIt<AuthRemoteDataSource>().verifyOtp(phone, otp);
      if (!verifyResponse.success || !(verifyResponse.verified ?? false)) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Invalid OTP. Please try again.');
        }
        return;
      }

      final updated = await ref.read(profileProvider.notifier).updateProfile(
            phone: phone,
          );

      if (!mounted) return;
      if (updated) {
        SnackBarUtils.showSuccess(context, 'Phone number updated');
        Navigator.pop(context);
      } else {
        SnackBarUtils.showError(context, 'Could not update phone number');
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Verification failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surface(context, Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(
              'Change phone number',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              'Current: ${widget.currentPhone.isEmpty ? 'Not set' : widget.currentPhone}',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: AppColors.foreground(context, Colors.grey[600]!),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'New phone number',
                hintText: '9XX XXX XXXX',
                border: OutlineInputBorder(),
                prefixText: '+63 ',
              ),
            ),
            if (_otpSent) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'OTP code',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_otpSent ? _verifyAndSave : _sendOtp),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                minimumSize: const Size.fromHeight(48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _otpSent ? 'Verify & Save' : 'Send OTP',
                      style: const TextStyle(
                        fontFamily: 'TT Fors',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            if (_otpSent)
              TextButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: const Text('Resend OTP'),
              ),
          ],
        ),
      ),
    );
  }
}
