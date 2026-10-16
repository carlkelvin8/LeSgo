import 'package:flutter/foundation.dart';

class AppConfig {
  static const int leseatServiceId = 3;
  static const int lesRideServiceId = 2;
  static const int lesBuyServiceId = 4;
  static const int defaultEstimatedDistanceM = 1500;

  /// Whether dev-only affordances (e.g. displaying the fallback OTP) are
  /// surfaced to the user. On by default in debug builds; can be forced with
  /// `--dart-define=DEV_MODE=true|false` in any build mode.
  static const bool isDevMode =
      bool.fromEnvironment('DEV_MODE', defaultValue: kDebugMode);

  AppConfig._();
}
