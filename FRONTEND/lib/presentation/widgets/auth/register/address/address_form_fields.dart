import 'package:flutter/material.dart';
import '../../../global/custom_text_field.dart';
import 'default_address_checkbox.dart';
import '../../../../../core/utils/validators/address_validator.dart';
import '../../../../../core/utils/responsive_utils.dart';

class AddressFormFields extends StatelessWidget {
  final TextEditingController houseNumberController;
  final TextEditingController subdivisionController;
  final TextEditingController cityController;
  final TextEditingController zipCodeController;
  final TextEditingController landmarkController;
  final bool isDefault;
  final Function(bool?) onDefaultChanged;

  const AddressFormFields({
    super.key,
    required this.houseNumberController,
    required this.subdivisionController,
    required this.cityController,
    required this.zipCodeController,
    required this.landmarkController,
    required this.isDefault,
    required this.onDefaultChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          controller: houseNumberController,
          labelText: 'House no. Street Name, Phase',
          validator: AddressValidator.houseNumberStreet,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        CustomTextField(
          controller: subdivisionController,
          labelText: 'Subdivision, Barangay',
          validator: AddressValidator.subdivisionBarangay,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        CustomTextField(
          controller: cityController,
          labelText: 'City/Municipality, Province',
          validator: AddressValidator.cityProvince,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        CustomTextField(
          controller: zipCodeController,
          labelText: 'Zip Code',
          keyboardType: TextInputType.number,
          validator: AddressValidator.zipCode,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        CustomTextField(
          controller: landmarkController,
          labelText: 'Landmark',
          validator: AddressValidator.landmark,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        DefaultAddressCheckbox(
          isDefault: isDefault,
          onChanged: onDefaultChanged,
        ),
      ],
    );
  }
}
