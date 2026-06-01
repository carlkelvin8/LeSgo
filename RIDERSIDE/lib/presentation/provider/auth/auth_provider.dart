import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthView {
  welcome,
  login,
  register,
  riderLogin,
  merchantLogin,
  forgotPassword,
}

/// Controls which view is shown on the AuthScreen.
final authViewProvider = StateProvider<AuthView>((ref) => AuthView.welcome);
