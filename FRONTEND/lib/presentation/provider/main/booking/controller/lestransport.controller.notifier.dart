import 'package:flutter/material.dart';

class LestransportControllers {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController contactController;
  final TextEditingController addressController;
  final TextEditingController branchAddressController;

  LestransportControllers()
      : formKey = GlobalKey<FormState>(),
        nameController = TextEditingController(),
        contactController = TextEditingController(),
        addressController = TextEditingController(),
        branchAddressController = TextEditingController();

  void dispose() {
    nameController.dispose();
    contactController.dispose();
    addressController.dispose();
    branchAddressController.dispose();
  }

  bool validate() {
    return formKey.currentState?.validate() ?? false;
  }

  void reset() {
    nameController.clear();
    contactController.clear();
    addressController.clear();
    branchAddressController.clear();
    formKey.currentState?.reset();
  }
}
