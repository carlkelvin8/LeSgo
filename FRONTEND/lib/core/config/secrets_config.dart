/// Compile-time secrets injected via `--dart-define-from-file=secrets.json`.
///
/// Copy [secrets.example.json] to `secrets.json` and run `tool/sync_secrets.ps1`
/// before building Android/iOS.
class SecretsConfig {
  SecretsConfig._();

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
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
    defaultValue: 'com.lesgo.app',
  );

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Comma-separated leaf certificate SHA-256 pins. Keep the current and next
  /// certificate pins together during planned rotations.
  static const String apiCertificateSha256Pins = String.fromEnvironment(
    'API_CERTIFICATE_SHA256_PINS',
    defaultValue:
        '52:B3:32:BB:4F:90:40:2B:CC:58:3B:56:45:BE:D0:2A:99:23:AD:33:ED:56:E3:86:97:54:E2:4E:B5:11:6F:AD,'
        '51:5A:49:00:DE:74:25:F1:00:35:E7:AB:D3:AF:49:5B:3E:53:76:26:E1:F5:64:E0:54:C9:4E:9E:12:62:8E:65',
  );

  static bool get isGeminiConfigured =>
      geminiApiKey.startsWith('AIza') &&
      geminiApiKey.length >= 35 &&
      !geminiApiKey.startsWith('your-') &&
      geminiApiKey != 'your-gemini-api-key-here';

  static bool get isGoogleMapsConfigured =>
      googleMapsApiKey.isNotEmpty &&
      googleMapsApiKey != 'your-google-maps-api-key-here';

  static bool get isGoogleSignInConfigured =>
      googleWebClientId.isNotEmpty &&
      !googleWebClientId.startsWith('YOUR_') &&
      googleWebClientId.contains('.apps.googleusercontent.com');

  static bool get isFirebaseConfigured =>
      firebaseProjectId.isNotEmpty &&
      !firebaseProjectId.startsWith('YOUR_') &&
      !firebaseProjectId.startsWith('your-') &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseAndroidApiKey.isNotEmpty &&
      firebaseAndroidAppId.isNotEmpty &&
      !firebaseAndroidApiKey.startsWith('your-');
}
