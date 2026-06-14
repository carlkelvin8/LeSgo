import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/utils.dart';
import '../../../widgets.dart';

class InfoFormFields extends ConsumerWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController birthdayController;
  final TextEditingController emailController;
  final TextEditingController phoneNumberController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController licenseNumberController;
  final TextEditingController licenseExpiryController;

  const InfoFormFields({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.birthdayController,
    required this.emailController,
    required this.phoneNumberController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.licenseNumberController,
    required this.licenseExpiryController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, 'First Name'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: firstNameController,
          hintText: '',
          validator: RegisterValidator.firstName,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _label(context, 'Last Name'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: lastNameController,
          hintText: '',
          validator: RegisterValidator.lastName,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _label(context, 'Birthday'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: birthdayController,
          hintText: 'MM/DD/YYYY',
          validator: RegisterValidator.birthday,
          readOnly: true,
          suffixIcon: Icon(
            Icons.calendar_today_outlined,
            color: const Color(0xFF9B59F0),
            size: ResponsiveUtils.imageHeight(context, 20),
          ),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF5F2D82),
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              birthdayController.text =
                  '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
            }
          },
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _label(context, 'Email'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: emailController,
          hintText: '',
          validator: RegisterValidator.email,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _label(context, 'Contact Number'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: phoneNumberController,
          hintText: '9XX XXX XXXX',
          keyboardType: TextInputType.phone,
          validator: RegisterValidator.phoneNumber,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _label(context, 'Password'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: passwordController,
          hintText: 'Min 8 chars, uppercase + number',
          isPassword: true,
          validator: RegisterValidator.password,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _label(context, 'Confirm Password'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: confirmPasswordController,
          hintText: '',
          isPassword: true,
          validator: (value) => RegisterValidator.confirmPassword(
            value,
            passwordController.text,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _label(context, 'Driver License Number'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: licenseNumberController,
          hintText: 'e.g. N01-12-345678',
          validator: RegisterValidator.licenseNumber,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _label(context, 'License Expiry (optional)'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: licenseExpiryController,
          hintText: 'MM/DD/YYYY',
          readOnly: true,
          suffixIcon: Icon(
            Icons.calendar_today_outlined,
            color: const Color(0xFF9B59F0),
            size: ResponsiveUtils.imageHeight(context, 20),
          ),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 365)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
            );
            if (picked != null) {
              licenseExpiryController.text =
                  '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
            }
          },
        ),
      ],
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 14),
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}
