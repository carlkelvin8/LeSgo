import 'package:flutter/material.dart';

class MerchantMenuItemFormController {
  late TextEditingController itemNameController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;
  final formKey = GlobalKey<FormState>();

  MerchantMenuItemFormController({
    String? initialItemName,
    String? initialPrice,
    String? initialDescription,
  }) {
    itemNameController = TextEditingController(text: initialItemName ?? '');
    priceController = TextEditingController(text: initialPrice ?? '0.00');
    descriptionController = TextEditingController(text: initialDescription ?? '');
  }

  void dispose() {
    itemNameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
  }
}
