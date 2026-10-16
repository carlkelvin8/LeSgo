import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'register_state.dart';

mixin VerificationNotifier on StateNotifier<RegisterState> {
  static const List<String> supportedIdTypes = [
    'philippine_national_id',
    'drivers_license',
    'passport',
    'umid',
    'sss_id',
    'postal_id',
    'voters_id',
    'prc_id',
  ];

  void updateSelfie(String selfiePath) {
    state = state.copyWith(data: state.data.copyWith(selfiePath: selfiePath));
  }

  void updateValidIdFront(String path) {
    state = state.copyWith(data: state.data.copyWith(validIdFrontPath: path));
  }

  void updateValidIdBack(String path) {
    state = state.copyWith(data: state.data.copyWith(validIdBackPath: path));
  }

  void updateIdType(String idType) {
    state = state.copyWith(data: state.data.copyWith(idType: idType));
  }

  void updateIdNumber(String idNumber) {
    state = state.copyWith(data: state.data.copyWith(idNumber: idNumber));
  }

  String? validateIdentityVerification() {
    final data = state.data;
    if (data.selfiePath.trim().isEmpty) {
      return 'Kailangan munang kumuha ng live selfie.';
    }
    if (data.idType.trim().isEmpty) {
      return 'Pumili ng uri ng government ID.';
    }
    if (data.idNumber.trim().isEmpty) {
      return 'Ilagay ang ID number.';
    }
    if (data.validIdFrontPath.trim().isEmpty) {
      return 'Kunan ang harap ng government ID.';
    }
    if (data.validIdBackPath.trim().isEmpty) {
      return 'Kunan ang likod ng government ID.';
    }
    return null;
  }
}
