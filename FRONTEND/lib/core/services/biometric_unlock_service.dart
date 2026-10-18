import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../constants/app_info.dart';
import '../di/injection.dart';
import 'app_preferences_service.dart';

final biometricUnlockServiceProvider = Provider<BiometricUnlockService>((ref) {
  return BiometricUnlockService(
    LocalAuthentication(),
    getIt<AppPreferencesService>(),
  );
});

/// Device authentication stays on the device; no biometric template is uploaded.
class BiometricUnlockService {
  BiometricUnlockService(this.auth, this.preferences);

  final LocalAuthentication auth;
  final AppPreferencesService preferences;
  bool isAuthenticating = false;

  Future<bool> isSupported() async {
    try {
      return await auth.canCheckBiometrics && await auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({bool enrolling = false}) async {
    if (isAuthenticating) return false;
    isAuthenticating = true;
    try {
      if (enrolling && (await auth.getAvailableBiometrics()).isEmpty) {
        throw PlatformException(code: 'NotEnrolled');
      }
      return await auth.authenticate(
        localizedReason: enrolling
            ? 'Enable biometric unlock for ${AppInfo.appName}'
            : 'Unlock ${AppInfo.appName}',
        options: AuthenticationOptions(
          // A device PIN/passcode lets the owner recover from biometric lockout.
          biometricOnly: enrolling,
          stickyAuth: true,
          useErrorDialogs: false,
        ),
      );
    } finally {
      isAuthenticating = false;
    }
  }

  static String errorMessage(Object error) {
    if (error is PlatformException) {
      switch (error.code) {
        case 'NotEnrolled':
          return 'Add a fingerprint or Face ID in your device settings first.';
        case 'PasscodeNotSet':
          return 'Set up a device PIN or passcode in your device settings first.';
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          return 'Biometrics are locked. Unlock your device with its PIN or passcode, then try again.';
        case 'NotAvailable':
          return 'Biometric authentication is unavailable. Check your device settings or sign in again.';
      }
    }
    return 'Could not authenticate. Please try again or sign in again.';
  }
}
