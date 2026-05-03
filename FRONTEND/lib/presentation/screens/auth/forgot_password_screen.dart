import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/utils.dart';
import '../../provider/auth/forgot_password_provider.dart';
import '../../widgets/widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final maxWidth = ResponsiveUtils.maxContentWidth(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                    
                    // Logo
                    Center(
                      child: SvgPicture.asset(
                        'assets/images/Logo.svg',
                        height: ResponsiveUtils.imageHeight(context, 60),
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 32)),
                    
                    // Title
                    Text(
                      state.step == ForgotPasswordStep.enterEmail
                          ? 'Forgot Password?'
                          : state.step == ForgotPasswordStep.verifyOtp
                              ? 'Verify OTP'
                              : 'Reset Password',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 24),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                    
                    // Subtitle
                    Text(
                      state.step == ForgotPasswordStep.enterEmail
                          ? 'Enter your email to receive an OTP code'
                          : state.step == ForgotPasswordStep.verifyOtp
                              ? 'Enter the 6-digit code sent to ${_emailController.text}'
                              : 'Create a new password for your account',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 40)),
                    
                    // Step 1: Enter Email
                    if (state.step == ForgotPasswordStep.enterEmail) ...[
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                        enabled: !state.isLoading,
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                      
                      PrimaryButton(
                        text: 'Send OTP',
                        isLoading: state.isLoading,
                        onPressed: () => _sendOtp(),
                        backgroundColor: const Color(0xFF5F2D82),
                      ),
                    ],
                    
                    // Step 2: Verify OTP
                    if (state.step == ForgotPasswordStep.verifyOtp) ...[
                      CustomTextField(
                        controller: _otpController,
                        labelText: 'OTP Code',
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter OTP';
                          }
                          if (value.length != 6) {
                            return 'OTP must be 6 digits';
                          }
                          return null;
                        },
                        enabled: !state.isLoading,
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                      
                      // Resend OTP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the code? ",
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              color: Colors.grey[700],
                            ),
                          ),
                          TextButton(
                            onPressed: state.isLoading ? null : () => _resendOtp(),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Resend',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                                color: const Color(0xFF5F2D82),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                      
                      PrimaryButton(
                        text: 'Verify OTP',
                        isLoading: state.isLoading,
                        onPressed: () => _verifyOtp(),
                        backgroundColor: const Color(0xFF5F2D82),
                      ),
                    ],
                    
                    // Step 3: Reset Password
                    if (state.step == ForgotPasswordStep.resetPassword) ...[
                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'New Password',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: Validators.password,
                        enabled: !state.isLoading,
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                      
                      CustomTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm Password',
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        enabled: !state.isLoading,
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                      
                      PrimaryButton(
                        text: 'Reset Password',
                        isLoading: state.isLoading,
                        onPressed: () => _resetPassword(),
                        backgroundColor: const Color(0xFF5F2D82),
                      ),
                    ],
                    
                    SizedBox(height: ResponsiveUtils.spacing(context, 40)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(forgotPasswordProvider.notifier).sendOtp(
          _emailController.text.trim(),
        );

    if (success && mounted) {
      SnackBarUtils.showSuccess(context, 'OTP sent to your email');
    } else if (mounted) {
      final error = ref.read(forgotPasswordProvider).errorMessage;
      SnackBarUtils.showError(context, error ?? 'Failed to send OTP');
    }
  }

  Future<void> _resendOtp() async {
    final success = await ref.read(forgotPasswordProvider.notifier).resendOtp(
          _emailController.text.trim(),
        );

    if (success && mounted) {
      SnackBarUtils.showSuccess(context, 'OTP resent to your email');
    } else if (mounted) {
      final error = ref.read(forgotPasswordProvider).errorMessage;
      SnackBarUtils.showError(context, error ?? 'Failed to resend OTP');
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(forgotPasswordProvider.notifier).verifyOtp(
          _emailController.text.trim(),
          _otpController.text.trim(),
        );

    if (success && mounted) {
      SnackBarUtils.showSuccess(context, 'OTP verified successfully');
    } else if (mounted) {
      final error = ref.read(forgotPasswordProvider).errorMessage;
      SnackBarUtils.showError(context, error ?? 'Invalid or expired OTP');
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(forgotPasswordProvider.notifier).resetPassword(
          _emailController.text.trim(),
          _otpController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      SnackBarUtils.showSuccess(context, 'Password reset successfully');
      Navigator.pop(context); // Go back to login
    } else if (mounted) {
      final error = ref.read(forgotPasswordProvider).errorMessage;
      SnackBarUtils.showError(context, error ?? 'Failed to reset password');
    }
  }
}
