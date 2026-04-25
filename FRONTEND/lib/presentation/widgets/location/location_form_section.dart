import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../provider/main/location/controller/location_controller.notifier.dart';
import '../auth/register/address/address_form_fields.dart';

class LocationFormSection extends StatelessWidget {
  final LocationControllers controllers;
  final VoidCallback onDefaultChanged;

  const LocationFormSection({
    super.key,
    required this.controllers,
    required this.onDefaultChanged,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Expanded(
      child: Form(
        key: controllers.formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            horizontalPadding,
            horizontalPadding,
            90.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AddressFormFields(
                houseNumberController: controllers.houseNumberController,
                subdivisionController: controllers.subdivisionController,
                cityController: controllers.cityController,
                zipCodeController: controllers.zipCodeController,
                landmarkController: controllers.landmarkController,
                isDefault: controllers.isDefault,
                onDefaultChanged: (value) => onDefaultChanged(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
