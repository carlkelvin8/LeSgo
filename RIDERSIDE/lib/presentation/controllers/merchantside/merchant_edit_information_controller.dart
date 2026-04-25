import 'package:flutter/material.dart';
import '../../../../core/utils/helpers/fakedata.dart';

class MerchantEditInformationController {
  MerchantEditInformationController()
      : restaurantController = TextEditingController(
          text: merchantProfileInfoData['restaurant'] ?? '',
        ),
        contactController = TextEditingController(
          text: merchantProfileInfoData['contact'] ?? '',
        ),
        addressController = TextEditingController(
          text: merchantProfileInfoData['address'] ?? '',
        ),
        referralController = TextEditingController(
          text: merchantProfileInfoData['referralCode'] ?? '',
        );

  final TextEditingController restaurantController;
  final TextEditingController contactController;
  final TextEditingController addressController;
  final TextEditingController referralController;

  String get restaurantName => restaurantController.text;

  bool saveChanges() {
    final restaurant = restaurantController.text.trim();
    final contact = contactController.text.trim();
    final address = addressController.text.trim();

    if (restaurant.isEmpty || contact.isEmpty || address.isEmpty) {
      return false;
    }

    merchantProfileInfoData['restaurant'] = restaurant;
    merchantProfileInfoData['contact'] = contact;
    merchantProfileInfoData['address'] = address;
    return true;
  }

  void dispose() {
    restaurantController.dispose();
    contactController.dispose();
    addressController.dispose();
    referralController.dispose();
  }
}