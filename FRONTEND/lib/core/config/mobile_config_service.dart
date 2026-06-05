import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import 'secrets_config.dart';

/// Runtime mobile config from API when compile-time secrets are incomplete.
class MobileConfigService {
  MobileConfigService._();
  static final MobileConfigService instance = MobileConfigService._();

  String? _googleWebClientId;
  String? _googleMapsApiKey;
  String? _firebaseProjectId;
  String? _firebaseMessagingSenderId;
  String? _firebaseAndroidApiKey;
  String? _firebaseAndroidAppId;
  String? _firebaseIosApiKey;
  String? _firebaseIosAppId;
  String? _firebaseIosBundleId;

  String get googleWebClientId =>
      _pick(_googleWebClientId, SecretsConfig.googleWebClientId);

  String get googleMapsApiKey =>
      _pick(_googleMapsApiKey, SecretsConfig.googleMapsApiKey);

  bool get isGoogleSignInConfigured =>
      googleWebClientId.isNotEmpty &&
      !googleWebClientId.startsWith('YOUR_') &&
      !googleWebClientId.startsWith('your-') &&
      googleWebClientId.contains('.apps.googleusercontent.com');

  bool get isFirebaseConfigured {
    final projectId = _pick(_firebaseProjectId, SecretsConfig.firebaseProjectId);
    final senderId =
        _pick(_firebaseMessagingSenderId, SecretsConfig.firebaseMessagingSenderId);
    final androidKey =
        _pick(_firebaseAndroidApiKey, SecretsConfig.firebaseAndroidApiKey);
    final androidAppId =
        _pick(_firebaseAndroidAppId, SecretsConfig.firebaseAndroidAppId);

    return projectId.isNotEmpty &&
        !projectId.startsWith('YOUR_') &&
        !projectId.startsWith('your-') &&
        senderId.isNotEmpty &&
        androidKey.isNotEmpty &&
        androidAppId.isNotEmpty;
  }

  FirebaseOptions get androidFirebaseOptions => FirebaseOptions(
        apiKey: _pick(_firebaseAndroidApiKey, SecretsConfig.firebaseAndroidApiKey),
        appId: _pick(_firebaseAndroidAppId, SecretsConfig.firebaseAndroidAppId),
        messagingSenderId:
            _pick(_firebaseMessagingSenderId, SecretsConfig.firebaseMessagingSenderId),
        projectId: _pick(_firebaseProjectId, SecretsConfig.firebaseProjectId),
        storageBucket:
            '${_pick(_firebaseProjectId, SecretsConfig.firebaseProjectId)}.firebasestorage.app',
      );

  FirebaseOptions get iosFirebaseOptions => FirebaseOptions(
        apiKey: _pick(_firebaseIosApiKey, SecretsConfig.firebaseIosApiKey),
        appId: _pick(_firebaseIosAppId, SecretsConfig.firebaseIosAppId),
        messagingSenderId:
            _pick(_firebaseMessagingSenderId, SecretsConfig.firebaseMessagingSenderId),
        projectId: _pick(_firebaseProjectId, SecretsConfig.firebaseProjectId),
        storageBucket:
            '${_pick(_firebaseProjectId, SecretsConfig.firebaseProjectId)}.firebasestorage.app',
        iosBundleId:
            _pick(_firebaseIosBundleId, SecretsConfig.firebaseIosBundleId),
      );

  FirebaseOptions get currentFirebaseOptions {
    if (kIsWeb) return androidFirebaseOptions;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return iosFirebaseOptions;
      default:
        return androidFirebaseOptions;
    }
  }

  Future<void> loadFromApi() async {
    if (SecretsConfig.isGoogleSignInConfigured && SecretsConfig.isFirebaseConfigured) {
      return;
    }

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ),
      );
      final response = await dio.get('/v1/config/mobile');
      final root = response.data;
      final data = root is Map && root['data'] is Map
          ? Map<String, dynamic>.from(root['data'] as Map)
          : Map<String, dynamic>.from(root as Map);

      _googleWebClientId = data['google_web_client_id'] as String?;
      _googleMapsApiKey = data['google_maps_api_key'] as String?;

      final firebase = data['firebase'];
      if (firebase is Map) {
        final fb = Map<String, dynamic>.from(firebase);
        _firebaseProjectId = fb['project_id'] as String?;
        _firebaseMessagingSenderId = fb['messaging_sender_id'] as String?;
        _firebaseAndroidApiKey = fb['android_api_key'] as String?;
        _firebaseAndroidAppId = fb['android_app_id'] as String?;
        _firebaseIosApiKey = fb['ios_api_key'] as String?;
        _firebaseIosAppId = fb['ios_app_id'] as String?;
        _firebaseIosBundleId = fb['ios_bundle_id'] as String?;
      }
    } catch (e) {
      debugPrint('⚠️ Mobile config API unavailable: $e');
    }
  }

  String _pick(String? runtime, String compileTime) {
    if (runtime != null &&
        runtime.isNotEmpty &&
        !runtime.startsWith('your-') &&
        !runtime.startsWith('YOUR_')) {
      return runtime;
    }
    return compileTime;
  }
}
