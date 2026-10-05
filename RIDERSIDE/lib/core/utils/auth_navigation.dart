import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/routers/app_router.dart';
import '../constants/routers/auth/auth_routes.dart';
import '../../presentation/provider/auth/auth_provider.dart';
import '../../presentation/provider/auth/rider_auth_provider.dart';

void navigateToLoginAfterLogout(
  BuildContext context,
  WidgetRef ref, {
  required AuthViewTarget target,
}) {
  ref.read(authViewProvider.notifier).state = target == AuthViewTarget.merchant
      ? AuthView.merchantLogin
      : AuthView.riderLogin;
  AppRouter.pushAndRemoveUntil(context, AuthRoutes.auth);
}
