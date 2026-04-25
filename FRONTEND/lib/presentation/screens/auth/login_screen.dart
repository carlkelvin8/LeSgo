import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../provider/auth/auth_provider.dart';
import '../../provider/auth/controller/login.controller.notifier.dart';
import '../../widgets/widgets.dart';
import '../../../core/utils/utils.dart';
import '../../../core/constants/routers/register/register_routes.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/constants/routers/app_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final LoginControllers _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = LoginControllers();
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final maxWidth = ResponsiveUtils.maxContentWidth(context);
    final screenHeight = ResponsiveUtils.screenHeight(context);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SizedBox(
              height: screenHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Form(
                  key: _controllers.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: ResponsiveUtils.spacing(context, 80)),
           
                      Center(
                        child: SvgPicture.asset(
                          'assets/images/Logo.svg',
                          height: ResponsiveUtils.imageHeight(context, 82),
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 22),
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                      Text(
                        'Please enter your details',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 48)),
         
                      CustomTextField(
                        controller: _controllers.emailController,
                        labelText: 'Email/Phone',
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.emailOrPhone,
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                      CustomTextField(
                        controller: _controllers.passwordController,
                        labelText: 'Password',
                        obscureText: _controllers.obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _controllers.obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _controllers.togglePasswordVisibility();
                            });
                          },
                        ),
                        validator: Validators.password,
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RememberMeCheckbox(
                            value: authState.rememberMe,
                            onChanged: (value) {
                              ref.read(authProvider.notifier).toggleRememberMe(value ?? false);
                            },
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Navigate to forgot password screen
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
                                color: const Color(0xFF6B4EFF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 32)),
                      PrimaryButton(
                        text: 'Log In',
                        isLoading: authState.isLoading,
                        onPressed: () async {
                          final success = await _controllers.handleLogin(context, ref);
                          if (success) {
                            if (!context.mounted) return;
                            AppRouter.pushReplacement(context, MainRoutes.home);
                          }
                        },
                        backgroundColor: const Color(0xFF5F2D82),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                      SocialLoginButton(
                        text: 'Log in with Google',
                        iconUrl: 'https://www.google.com/favicon.ico',
                        iconData: Icons.g_mobiledata,
                        onPressed: () => _controllers.handleGoogleSignIn(context, ref),
                      ),
  const Spacer(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              color: Colors.grey[700],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              AppRouter.push(context, RegisterRoutes.register);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Sign Up',
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
                      SizedBox(height: ResponsiveUtils.spacing(context, 84)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
