import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'register_state.dart';


mixin PersonalInfoNotifier on StateNotifier<RegisterState> {
  void updatePersonalInfo({
    required String firstName,
    required String lastName,
    required String birthday,
    required String email,
    required String password,
    required String confirmPassword,
    String? referralCode,
  }) {
    state = state.copyWith(
      data: state.data.copyWith(
        firstName: firstName,
        lastName: lastName,
        birthday: birthday,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        referralCode: referralCode ?? '',
      ),
    );
  }
}
