import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'register_state.dart';

mixin TermsNotifier on StateNotifier<RegisterState> {

  void acceptTerms() {
    state = state.copyWith(
      data: state.data.copyWith(termsAccepted: true),
    );
  }
}
