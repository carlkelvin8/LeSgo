import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/register/controller/address.controller.notifier.dart';
import '../../../../provider/register/notifier/register_state.dart';
import 'address_form_fields.dart';

class AddressFormPanel extends StatelessWidget {
  const AddressFormPanel({
    super.key,
    required this.controllers,
    required this.registerState,
    required this.onDefaultChanged,
  });

  final AddressControllers controllers;
  final RegisterState registerState;
  final Function(bool?) onDefaultChanged;

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.horizontalPadding(context);
    return Expanded(
      child: Form(
        key: controllers.formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, padding, padding, 90.0),
          child: AddressFormFields(
            houseNumberController: controllers.houseNumberController,
            subdivisionController: controllers.subdivisionController,
            cityController: controllers.cityController,
            zipCodeController: controllers.zipCodeController,
            landmarkController: controllers.landmarkController,
            isDefault: registerState.data.address?.isDefault ?? false,
            onDefaultChanged: onDefaultChanged,
          ),
        ),
      ),
    );
  }
}
