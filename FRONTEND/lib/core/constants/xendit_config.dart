/// Xendit configuration for LesPay top-up.
///
/// Prefer passing the key at build time (keeps secrets out of source when possible):
/// `flutter run --dart-define=XENDIT_SECRET_KEY=your_key`
class XenditConfig {
  static const String secretKey = String.fromEnvironment(
    'XENDIT_SECRET_KEY',
    defaultValue:
        'xnd_development_0oY0lkbRUCEtOJS4tI8Z3emBEy4iY0qpi8GqHa3PaJ4doJapAQqWBWC6oFbjkAQ',
  );

  static const String apiBaseUrl = 'https://api.xendit.co';

  /// Deep-link style URLs used by Xendit invoice redirect (mobile opens app via intent).
  static const String successRedirectUrl = 'lesgo://lespay/topup/success';
  static const String failureRedirectUrl = 'lesgo://lespay/topup/failure';

  XenditConfig._();
}
