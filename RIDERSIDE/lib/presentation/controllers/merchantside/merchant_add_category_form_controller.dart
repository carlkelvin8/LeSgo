import 'package:flutter/material.dart';

class MerchantAddCategoryFormController {
  late TextEditingController categoryNameController;
  final formKey = GlobalKey<FormState>();

  MerchantAddCategoryFormController({
    String? initialCategoryName,
  }) {
    categoryNameController = TextEditingController(text: initialCategoryName ?? '');
  }

  void dispose() {
    categoryNameController.dispose();
  }
}
