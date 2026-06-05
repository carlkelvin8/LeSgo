/// Public app metadata shown on About and legal screens.
class AppInfo {
  AppInfo._();

  static const String appName = 'LeSGo';
  static const String companyName = 'LeSGo Philippines';
  static const String tagline =
      'Your all-in-one super app for rides, food, delivery, and payments.';

  static const String version = '1.0.0';
  static const String buildNumber = '1';

  static const String supportEmail = 'support@lesgo.ph';
  static const String privacyEmail = 'privacy@lesgo.ph';
  static const String website = 'https://lesgo.ph';

  static const String companyAddress =
      'Cagayan de Oro City, Misamis Oriental, Philippines';

  static String get versionLabel => 'Version $version ($buildNumber)';
}
