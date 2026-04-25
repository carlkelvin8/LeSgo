import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'notifier/register_state.dart';
import 'notifier/terms_notifier.dart';
import 'notifier/personal_info_notifier.dart';
import 'notifier/verification_notifier.dart';
import 'notifier/otp_notifier.dart';
import 'notifier/address_notifier.dart';
import 'notifier/submit_notifier.dart';

class RegisterNotifier extends StateNotifier<RegisterState>
    with TermsNotifier, PersonalInfoNotifier, VerificationNotifier, OtpNotifier, AddressNotifier, SubmitNotifier {
  RegisterNotifier() : super(RegisterState(
    selectedLocation: const LatLng(14.5995, 120.9842), 
  ));
}


final registerProvider =
    StateNotifierProvider<RegisterNotifier, RegisterState>((ref) {
  return RegisterNotifier();
});
