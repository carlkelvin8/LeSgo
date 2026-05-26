import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../constants/api_constants.dart';

/// SSL certificate pinning for production API hosts.
@lazySingleton
class SslPinningService {
  /// SHA-256 fingerprints (colon-separated, uppercase) for pinned hosts.
  /// Production: lesgo-api-feature-auth-secmes.free.laravel.cloud
  static const List<String> _certificateFingerprints = [
    '3E:EB:26:92:E6:27:BE:9A:10:2A:7A:46:86:9A:A4:28:A6:DF:1D:24:E5:52:F1:5C:70:B7:EA:3B:44:74:EB:D8',
  ];

  static const Set<String> _pinnedHosts = {
    'lesgo-api-feature-auth-secmes.free.laravel.cloud',
  };

  void configureSslPinning(Dio dio) {
    if (kDebugMode) {
      debugPrint('🔒 SSL Pinning: skipped in debug mode');
      return;
    }

    debugPrint('🔒 Configuring SSL certificate pinning...');

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        if (!_pinnedHosts.contains(host)) {
          return true;
        }
        if (_certificateFingerprints.isEmpty) {
          debugPrint('⚠️ SSL Pinning: no fingerprints configured for $host');
          return false;
        }
        final fingerprint = _sha256Fingerprint(cert);
        final isValid = _certificateFingerprints.contains(fingerprint);
        if (!isValid) {
          debugPrint('❌ SSL Pinning failed for $host:$port');
          debugPrint('   Got:      $fingerprint');
          debugPrint('   Expected: ${_certificateFingerprints.first}');
        }
        return isValid;
      };
      return client;
    };
  }

  static String _sha256Fingerprint(X509Certificate cert) {
    final digest = sha256.convert(cert.der);
    return digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
  }

  bool validateCertificate(String fingerprint) {
    return _certificateFingerprints.contains(fingerprint.toUpperCase());
  }

  /// Host derived from [ApiConstants.baseUrl] for documentation/tests.
  static String get pinnedApiHost {
    final uri = Uri.parse(ApiConstants.baseUrl);
    return uri.host;
  }
}
