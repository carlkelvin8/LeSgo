import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';

import '../../../widgets.dart';

class MerchantInfoFormFields extends StatelessWidget {
  final TextEditingController restaurantNameController;
  final TextEditingController ownerFirstNameController;
  final TextEditingController ownerLastNameController;
  final TextEditingController emailController;
  final TextEditingController contactNumberController;
  final TextEditingController addressController;
  final TextEditingController zipCodeController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const MerchantInfoFormFields({
    super.key,
    required this.restaurantNameController,
    required this.ownerFirstNameController,
    required this.ownerLastNameController,
    required this.emailController,
    required this.contactNumberController,
    required this.addressController,
    required this.zipCodeController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(context, 'Restaurant Name'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: restaurantNameController,
          hintText: '',
          validator: (value) => value == null || value.isEmpty
              ? 'Restaurant Name is required'
              : null,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        _buildSectionLabel(context, 'Last Name (Restaurant Owner)'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: ownerLastNameController,
          hintText: '',
          validator: RegisterValidator.lastName,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        _buildSectionLabel(context, 'First Name (Restaurant Owner)'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: ownerFirstNameController,
          hintText: '',
          validator: RegisterValidator.firstName,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        _buildSectionLabel(context, 'Email'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: emailController,
          hintText: 'LeSgoPartner@gmail.com',
          validator: RegisterValidator.email,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        _buildSectionLabel(context, 'Additional Contact Numbers'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        _buildPhoneField(context),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        _buildSectionLabel(context, 'Restaurant Address'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: addressController,
          hintText: '',
          validator: (value) =>
              value == null || value.isEmpty ? 'Address is required' : null,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        _buildSectionLabel(context, 'Zip Code'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: zipCodeController,
          hintText: '',
          validator: (value) =>
              value == null || value.isEmpty ? 'Zip Code is required' : null,
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        _buildSectionLabel(context, 'Password'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: passwordController,
          hintText: 'Enter your password',
          obscureText: true,
          validator: RegisterValidator.password,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        _buildSectionLabel(context, 'Confirm Password'),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: confirmPasswordController,
          hintText: 'Re-enter your password',
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
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

  Widget _buildPhoneField(BuildContext context) {
    return FormField<String>(
      validator: (value) {
        return RegisterValidator.phoneNumber(contactNumberController.text);
      },
      initialValue: contactNumberController.text,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.spacing(context, 12),
                ),
                border: Border.all(
                  color: state.hasError ? Colors.red : Colors.grey.shade300,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.spacing(context, 16),
                vertical: ResponsiveUtils.spacing(context, 4),
              ),
              child: Row(
                children: [
                  Image.network(
                    'https://flagcdn.com/w40/ph.png', // Fallback or use asset
                    width: 24,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.flag, size: 24),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    '+63',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  Expanded(
                    child: TextField(
                      controller: contactNumberController,
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        state.didChange(value);
                      },
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.black87,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isDense: false,
                        border: InputBorder.none,
                        hintText: 'Main Contact Number',
                        hintStyle: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                          color: Colors.grey.shade400,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: ResponsiveUtils.spacing(context, 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (state
                .hasError) // Optionally show error text if design changes, but currently hidden requested
              Padding(
                // But wait, user requested "remove the error message beneath" in Step 399.
                padding: const EdgeInsets.only(top: 5.0),
                child:
                    Container(), // Keeping implementation clean of text as requested.
              ),
          ],
        );
      },
    );
  }
}
