import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/validators/profile_validator.dart';
import '../../provider/main/profile/controller/profile.controller.notifier.dart';
import '../widgets.dart';

class ProfileAddressSection extends ConsumerWidget {
  final TextEditingController nameController;
  final TextEditingController address1Controller;
  final TextEditingController address2Controller;
  final ProfileControllers controllers;

  const ProfileAddressSection({
    super.key,
    required this.nameController,
    required this.address1Controller,
    required this.address2Controller,
    required this.controllers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: CustomTextField(
            controller: nameController,
            labelText: 'Full Name',
            validator: (value) =>
                ProfileValidator.name(value, isRequired: false),
          ),
        ),

        SizedBox(height: ResponsiveUtils.spacing(context, 20)),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: CustomTextField(
            controller: address1Controller,
            labelText: 'Address 1',
            validator: (value) =>
                ProfileValidator.address(value, isRequired: false),
          ),
        ),

        SizedBox(height: ResponsiveUtils.spacing(context, 20)),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: CustomTextField(
            controller: address2Controller,
            labelText: 'Address 2',
            validator: (value) =>
                ProfileValidator.address(value, isRequired: false),
          ),
        ),

        SizedBox(height: ResponsiveUtils.spacing(context, 20)),

        Padding(
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
        ),
      ],
    );
  }
}
