import 'package:flutter/material.dart';
import 'package:lesgo/core/theme/app_colors.dart';

import '../../../core/utils/validators/address_validator.dart';
import '../../provider/main/location/controller/location_controller.notifier.dart';

class LocationFormSection extends StatelessWidget {
  const LocationFormSection({
    super.key,
    required this.controllers,
    required this.onDefaultChanged,
  });

  final LocationControllers controllers;
  final VoidCallback onDefaultChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Form(
      key: controllers.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Address details',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Check these details so your rider can find you.',
            style: text.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _LocationField(
            label: 'House number, street or phase',
            icon: Icons.home_outlined,
            controller: controllers.houseNumberController,
            validator: AddressValidator.houseNumberStreet,
          ),
          _LocationField(
            label: 'Subdivision or barangay',
            icon: Icons.holiday_village_outlined,
            controller: controllers.subdivisionController,
            validator: AddressValidator.subdivisionBarangay,
          ),
          _LocationField(
            label: 'City or municipality, province',
            icon: Icons.location_city_rounded,
            controller: controllers.cityController,
            validator: AddressValidator.cityProvince,
            maxLines: 2,
          ),
          _LocationField(
            label: 'ZIP code (optional)',
            icon: Icons.markunread_mailbox_outlined,
            controller: controllers.zipCodeController,
            validator: AddressValidator.zipCode,
            keyboardType: TextInputType.number,
          ),
          _LocationField(
            label: 'Landmark (optional)',
            icon: Icons.flag_outlined,
            controller: controllers.landmarkController,
            validator: AddressValidator.landmark,
          ),
          Material(
            color: AppColors.surface(context, const Color(0xFFF6F1F9)),
            borderRadius: BorderRadius.circular(16),
            child: CheckboxListTile(
              value: controllers.isDefault,
              onChanged: (_) => onDefaultChanged(),
              activeColor: AppColors.buttonFill(context),
              checkColor: AppColors.onButton(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Set as default address'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.buttonFill(context);
    final line = AppColors.border(context, const Color(0xFFEAE2EF));
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: color),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.streetAddress,
        validator: validator,
        minLines: 1,
        maxLines: maxLines,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: Icon(icon, size: 20, color: accent),
          filled: true,
          fillColor: AppColors.surface(context, Colors.white),
          border: border(line),
          enabledBorder: border(line),
          focusedBorder: border(accent),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
