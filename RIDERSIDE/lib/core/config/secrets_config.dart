/// Compile-time secrets injected via `--dart-define-from-file=secrets.json`.
class SecretsConfig {
  SecretsConfig._();

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );

  static const String firebaseAndroidApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY_ANDROID',
    defaultValue: '',
  );

  static const String firebaseAndroidAppId = String.fromEnvironment(
    'FIREBASE_APP_ID_ANDROID',
    defaultValue: '',
  );

  static const String firebaseIosApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY_IOS',
    defaultValue: '',
  );

  static const String firebaseIosAppId = String.fromEnvironment(
    'FIREBASE_APP_ID_IOS',
    defaultValue: '',
  );

  static const String firebaseIosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.lesgo.rider',
  );

  /// Optional override, e.g. `https://api.lesgo.com/api`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// `dev` | `staging` | `prod` — used when [apiBaseUrl] is empty.
  static const String apiEnv = String.fromEnvironment(
    'API_ENV',
    defaultValue: '',
  );

  static bool get isGoogleMapsConfigured =>
      googleMapsApiKey.isNotEmpty &&
      googleMapsApiKey != 'your-google-maps-api-key-here';

  /// Safe label for logs/UI — never exposes the key value.
  static String get googleMapsConfigStatus => isGoogleMapsConfigured
      ? 'configured (--dart-define-from-file=secrets.json)'
      : 'missing — add GOOGLE_MAPS_API_KEY to secrets.json';

  static bool get isFirebaseConfigured =>
      firebaseProjectId.isNotEmpty &&
      !firebaseProjectId.startsWith('YOUR_') &&
      !firebaseProjectId.startsWith('your-') &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseAndroidApiKey.isNotEmpty &&
      firebaseAndroidAppId.isNotEmpty &&
      !firebaseAndroidApiKey.startsWith('your-');
}
