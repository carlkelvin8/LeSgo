import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/remember_me_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../provider/auth/rider_auth_provider.dart';
import '../../provider/auth/auth_provider.dart';
import '../../provider/auth/forgot_password_provider.dart';
import '../widgets.dart';

class RiderLoginContent extends ConsumerStatefulWidget {
  const RiderLoginContent({super.key});

  @override
  ConsumerState<RiderLoginContent> createState() => _RiderLoginContentState();
}

class _RiderLoginContentState extends ConsumerState<RiderLoginContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isRememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    if (!RememberMeService.isEnabled()) return;
    if (!RememberMeService.matchesAccountType('rider')) return;

    final email = RememberMeService.savedEmail;
    if (!mounted) return;

    setState(() {
      isRememberMe = true;
      if (email != null) _emailController.text = email;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await ref.read(riderAuthProvider.notifier).login(
          email,
          password,
          rememberMe: isRememberMe,
          accountType: 'rider',
        );

    if (!mounted) return;

    if (success) {
      final user = ref.read(riderAuthProvider).user;

      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      if (user != null && (user.isMerchant || user.isStaff)) {
        AppRouter.pushReplacement(context, MainRoutes.merchantMain);
      } else {
        AppRouter.pushReplacement(context, MainRoutes.riderMain);
      }
    } else {
      final error = ref.read(riderAuthProvider).error ?? 'Login failed';
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
        key: const ValueKey('rider_login_form'),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  Expanded(
                    child: Text(
                      'Remember for 30 days',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: authState.isLoading
                      ? null
                      : () {
                          ref
                              .read(forgotPasswordReturnViewProvider.notifier)
                              .state = AuthView.riderLogin;
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
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          PrimaryButton(
            text: authState.isLoading ? 'Logging in...' : 'Log In',
            semanticsLabel: authState.isLoading
                ? 'Logging in, please wait'
                : 'Log in to rider account',
            onPressed: authState.isLoading ? null : _handleLogin,
          ),
        ],
      ),
    );
  }
}
