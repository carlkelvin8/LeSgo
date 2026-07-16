/// PayMongo configuration for LesPay top-up.
///
/// Prefer passing the key at build time:
/// `flutter run --dart-define=PAYMONGO_SECRET_KEY=your_key`
class PayMongoConfig {
  static const String secretKey = String.fromEnvironment(
    'PAYMONGO_SECRET_KEY',
    defaultValue: '',
  );

  static const String publicKey = String.fromEnvironment(
    'PAYMONGO_PUBLIC_KEY',
    defaultValue: '',
  );

  static const String apiBaseUrl = 'https://api.paymongo.com/v1';

  /// Deep-link style URLs used by PayMongo checkout redirect.
  static const String successRedirectUrl = 'lesgo://lespay/topup/success';
  static const String failureRedirectUrl = 'lesgo://lespay/topup/failure';

  static bool get isConfigured => secretKey.isNotEmpty;

  PayMongoConfig._();
}
