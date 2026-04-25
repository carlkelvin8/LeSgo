import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../widgets/widgets.dart';
import '../../../provider/register/controller/personal_info.controller.notifier.dart';
import '../../../../core/utils/validators/register_validator.dart';
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
      AppRouter.push(context, RegisterRoutes.verification);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
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

                    Center(
                      child: SvgPicture.asset(
                        'assets/images/register/7.svg',
                        height: ResponsiveUtils.imageHeight(context, 250),
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 32)),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _controllers.firstNameController,
                              labelText: 'First Name',
                              validator: RegisterValidator.firstName,
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),

                            CustomTextField(
                              controller: _controllers.lastNameController,
                              labelText: 'Last Name',
                              validator: RegisterValidator.lastName,
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),

                            BirthdayField(
                              controller: _controllers.birthdayController,
                              labelText: 'Birthday',
                              validator: RegisterValidator.birthday,
                              focusedBorderColor: const Color(0xFF7C3AED),
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),

                            CustomTextField(
                              controller: _controllers.emailController,
                              labelText: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: RegisterValidator.email,
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),

                            CustomTextField(
                              controller: _controllers.passwordController,
                              labelText: 'Password',
                              obscureText: true,
                              validator: RegisterValidator.password,
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),

                            CustomTextField(
                              controller: _controllers.confirmPasswordController,
                              labelText: 'Confirm Password',
                              obscureText: true,
                              validator: (value) => RegisterValidator.confirmPassword(
                                value,
                                _controllers.passwordController.text,
                              ),
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),

                            CustomTextField(
                              controller: _controllers.referralCodeController,
                              labelText: 'Referral Code',
                              validator: RegisterValidator.referralCode,
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
