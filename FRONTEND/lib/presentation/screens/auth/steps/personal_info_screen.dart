import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/common/common_widgets.dart';
import '../../../provider/register/controller/personal_info.controller.notifier.dart';
import '../../../../core/utils/google_auth_helper.dart';
import '../../../../core/utils/validators/register_validator.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/validators/otp_validator.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/routers/register/register_routes.dart';
import '../../../../core/constants/routers/app_router.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  late final PersonalInfoControllers _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = PersonalInfoControllers();
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_controllers.validateAndSave(ref)) {
      AppRouter.push(context, RegisterRoutes.otpVerification);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface(context, Colors.white),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final horizontalPadding = ResponsiveUtils.horizontalPadding(
              context,
            );
            return Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Form(
                key: _controllers.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(title: 'SIGN UP'),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: SvgPicture.asset(
                                'assets/images/register/7.svg',
                                height: ResponsiveUtils.imageHeight(
                                  context,
                                  250,
                                ),
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 32),
                            ),

                            // Sign up with Google (quick option)
                            SocialLoginButton(
                              text: 'Sign up with Google',
                              iconUrl: 'https://www.google.com/favicon.ico',
                              iconData: Icons.g_mobiledata,
                              onPressed: () => GoogleAuthHelper.signIn(
                                context,
                                ref,
                                mode: GoogleAuthMode.signup,
                              ),
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 20),
                            ),

                            // OR divider
                            Row(
                              children: [
                                const Expanded(child: Divider(thickness: 1)),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveUtils.spacing(
                                      context,
                                      12,
                                    ),
                                  ),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: ResponsiveUtils.fontSize(
                                        context,
                                        12,
                                      ),
                                      color: AppColors.foreground(context, Colors.grey[500]!),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider(thickness: 1)),
                              ],
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 20),
                            ),

                            // First Name with real-time validation
                            ValidatedTextField(
                              label: 'First Name',
                              hint: 'Enter your first name',
                              controller: _controllers.firstNameController,
                              validator: (value) => Validators.name(
                                value,
                                fieldName: 'First name',
                              ),
                              textCapitalization: TextCapitalization.words,
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AppColors.foreground(context, Colors.grey[600]!),
                              ),
                              required: true,
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),

                            // Last Name with real-time validation
                            ValidatedTextField(
                              label: 'Last Name',
                              hint: 'Enter your last name',
                              controller: _controllers.lastNameController,
                              validator: (value) => Validators.name(
                                value,
                                fieldName: 'Last name',
                              ),
                              textCapitalization: TextCapitalization.words,
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AppColors.foreground(context, Colors.grey[600]!),
                              ),
                              required: true,
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),

                            // Birthday field (keep existing widget)
                            BirthdayField(
                              controller: _controllers.birthdayController,
                              labelText: 'Birthday',
                              validator: RegisterValidator.birthday,
                              focusedBorderColor: const Color(0xFF7C3AED),
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),

                            // Email with real-time validation
                            ValidatedTextField(
                              label: 'Email',
                              hint: 'Enter your email address',
                              controller: _controllers.emailController,
                              validator: Validators.email,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.foreground(context, Colors.grey[600]!),
                              ),
                              required: true,
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),

                            ValidatedTextField(
                              label: 'Phone Number',
                              hint: '+63 XXX XXX XXXX',
                              controller: _controllers.phoneController,
                              validator: OtpValidator.phoneNumber,
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: AppColors.foreground(context, Colors.grey[600]!),
                              ),
                              required: true,
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),

                            // Password with strength indicator
                            PasswordField(
                              label: 'Password',
                              hint: 'Create a strong password',
                              controller: _controllers.passwordController,
                              showStrengthIndicator: true,
                              required: true,
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),

                            // Confirm Password
                            PasswordConfirmField(
                              label: 'Confirm Password',
                              hint: 'Re-enter your password',
                              controller:
                                  _controllers.confirmPasswordController,
                              passwordController:
                                  _controllers.passwordController,
                              required: true,
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),

                            // Referral Code (optional)
                            ValidatedTextField(
                              label: 'Referral Code',
                              hint: 'Enter referral code (optional)',
                              controller: _controllers.referralCodeController,
                              validator: RegisterValidator.referralCode,
                              prefixIcon: Icon(
                                Icons.card_giftcard_outlined,
                                color: AppColors.foreground(context, Colors.grey[600]!),
                              ),
                              required: false,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 24)),

                    PrimaryButton(
                      text: 'Next',
                      onPressed: _handleNext,
                      backgroundColor: const Color(0xFF5F2D82),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
