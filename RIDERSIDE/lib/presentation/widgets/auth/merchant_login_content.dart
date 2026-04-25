import 'package:flutter/material.dart';
import '../../../core/utils/utils.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../widgets.dart';

class MerchantLoginContent extends StatefulWidget {
  const MerchantLoginContent({super.key});

  @override
  State<MerchantLoginContent> createState() => _MerchantLoginContentState();
}

class _MerchantLoginContentState extends State<MerchantLoginContent> {
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

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      // Navigate to MerchantMainScreen
      AppRouter.pushReplacement(context, MainRoutes.merchantMain);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 14)),
          CustomTextField(
            hintText: 'Password',
            isPassword: true,
            controller: _passwordController,
            validator: LoginValidator.password,
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
                      onChanged: (value) {
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
                onPressed: () {
                  // TODO: Forgot Password logic for Merchant
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
          PrimaryButton(text: 'Log In', onPressed: _handleLogin),
        ],
      ),
    );
  }
}
