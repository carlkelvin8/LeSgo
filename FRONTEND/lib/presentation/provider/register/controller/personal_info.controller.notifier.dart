import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../register_provider.dart';

class PersonalInfoControllers {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController birthdayController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController referralCodeController;

  PersonalInfoControllers()
      : formKey = GlobalKey<FormState>(),
        firstNameController = TextEditingController(),
        lastNameController = TextEditingController(),
        birthdayController = TextEditingController(),
        emailController = TextEditingController(),
        passwordController = TextEditingController(),
        confirmPasswordController = TextEditingController(),
        referralCodeController = TextEditingController();

  /// Validates form and updates personal info in provider
  bool validateAndSave(WidgetRef ref) {
    if (formKey.currentState!.validate()) {
      ref.read(registerProvider.notifier).updatePersonalInfo(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        birthday: birthdayController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        confirmPassword: confirmPasswordController.text.trim(),
        referralCode: referralCodeController.text.trim(),
      );
      return true;
    }
    return false;
  }

  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    birthdayController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    referralCodeController.dispose();
  }
}
