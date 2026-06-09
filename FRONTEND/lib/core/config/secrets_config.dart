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

  static bool get isGeminiConfigured =>
      geminiApiKey.isNotEmpty &&
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
