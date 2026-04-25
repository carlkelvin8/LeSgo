import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/validators/profile_validator.dart';
import '../../provider/main/profile/controller/profile.controller.notifier.dart';
import '../widgets.dart';

/// Editable profile section with name and address fields
class ProfileEditSection extends ConsumerWidget {
  final ProfileControllers controllers;

  const ProfileEditSection({
    super.key,
    required this.controllers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Column(
      children: [
        _buildNameField(horizontalPadding),
        SizedBox(height: ResponsiveUtils.spacing(context, 20)),
        _buildAddressField(
          horizontalPadding,
          controllers.address1Controller,
          'Address 1',
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 20)),
        _buildAddressField(
          horizontalPadding,
          controllers.address2Controller,
          'Address 2',
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 20)),
        _buildSaveButton(context, ref, horizontalPadding),
      ],
    );
  }

  Widget _buildNameField(double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: CustomTextField(
        controller: controllers.nameController,
        labelText: 'Full Name',
        validator: (value) => ProfileValidator.name(value, isRequired: false),
      ),
    );
  }

  Widget _buildAddressField(
    double horizontalPadding,
    TextEditingController controller,
    String label,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: CustomTextField(
        controller: controller,
        labelText: label,
        validator: (value) =>
            ProfileValidator.address(value, isRequired: false),
      ),
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    WidgetRef ref,
    double horizontalPadding,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => controllers.updateProfile(context, ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5F2D82),
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.spacing(context, 16),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Save Profile',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
