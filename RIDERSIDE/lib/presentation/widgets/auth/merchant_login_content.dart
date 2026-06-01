import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/utils.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../provider/auth/rider_auth_provider.dart';
import '../../provider/auth/auth_provider.dart';
import '../../provider/auth/forgot_password_provider.dart';
import '../widgets.dart';

class MerchantLoginContent extends ConsumerStatefulWidget {
  const MerchantLoginContent({super.key});

  @override
  ConsumerState<MerchantLoginContent> createState() => _MerchantLoginContentState();
}

class _MerchantLoginContentState extends ConsumerState<MerchantLoginContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isRememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    print('🔐 MERCHANT LOGIN BUTTON PRESSED');
    
    if (!(_formKey.currentState?.validate() ?? false)) {
      print('❌ Form validation failed');
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    print('🔐 Attempting merchant login with email: $email');

    // Perform actual authentication
    final success = await ref.read(riderAuthProvider.notifier).login(email, password);
    
    print('🔐 Merchant login result: ${success ? "SUCCESS" : "FAILED"}');

    if (!mounted) return;

    if (success) {
      print('✅ Merchant login successful');
      
      // Get user info to verify it's a merchant
      final user = ref.read(riderAuthProvider).user;
      print('🔐 User role: ${user?.role}, Is merchant: ${user?.isMerchant}, Partner ID: ${user?.partnerId}');
      
      // Wait a bit to ensure state is updated
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      // Navigate to Merchant Main Screen
      print('🔐 Navigating to Merchant Main Screen');
      AppRouter.pushReplacement(context, MainRoutes.merchantMain);
    } else {
      // Show error message
      final error = ref.read(riderAuthProvider).error ?? 'Login failed';
      print('❌ Merchant login failed with error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(riderAuthProvider);

    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('merchant_login_form'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            hintText: 'Email/Phone',
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            validator: LoginValidator.emailOrPhone,
            readOnly: authState.isLoading,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 14)),
          CustomTextField(
            hintText: 'Password',
            isPassword: true,
            controller: _passwordController,
            validator: LoginValidator.password,
            readOnly: authState.isLoading,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: isRememberMe,
                      onChanged: authState.isLoading
                          ? null
                          : (value) {
                              setState(() {
                                isRememberMe = value ?? false;
                              });
                            },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                      activeColor: const Color(0xFF5F2D82),
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    'Remember for 30 days',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: authState.isLoading
                    ? null
                    : () {
                        ref.read(forgotPasswordReturnViewProvider.notifier).state =
                            AuthView.merchantLogin;
                        ref.read(forgotPasswordProvider.notifier).reset();
                        ref.read(authViewProvider.notifier).state =
                            AuthView.forgotPassword;
                      },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          PrimaryButton(
            text: authState.isLoading ? 'Logging in...' : 'Log In',
            onPressed: authState.isLoading ? null : _handleLogin,
          ),
        ],
      ),
    );
  }
}
