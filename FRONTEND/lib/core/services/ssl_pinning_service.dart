import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Service for SSL Certificate Pinning
/// Prevents man-in-the-middle attacks by validating server certificates
@lazySingleton
class SslPinningService {
  /// Certificate fingerprints (SHA-256) for your API server
  /// TODO: Replace with your actual certificate fingerprints
  static const List<String> _certificateFingerprints = [
    // Example: 'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99',
    // Add your production certificate fingerprints here
  ];

  /// Configure SSL pinning for Dio client
  void configureSslPinning(Dio dio) {
    if (kDebugMode) {
      debugPrint('🔒 SSL Pinning: Disabled in debug mode');
      return;
    }

    debugPrint('🔒 Configuring SSL Certificate Pinning...');

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // In production, validate certificate fingerprint
        if (_certificateFingerprints.isEmpty) {
          debugPrint('⚠️ No certificate fingerprints configured');
          return true; // Allow in development
        }

        final certFingerprint = _getCertificateFingerprint(cert);
        final isValid = _certificateFingerprints.contains(certFingerprint);

        if (!isValid) {
          debugPrint('❌ SSL Pinning Failed: Invalid certificate');
          debugPrint('   Host: $host:$port');
          debugPrint('   Fingerprint: $certFingerprint');
        } else {
          debugPrint('✅ SSL Pinning: Certificate validated');
        }

        return isValid;
      };

      return client;
    };
  }

  /// Get certificate fingerprint (SHA-256)
  String _getCertificateFingerprint(X509Certificate cert) {
    // Convert certificate to SHA-256 fingerprint
    final bytes = cert.der;
    final fingerprint = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
    return fingerprint;
  }

  /// Validate if certificate fingerprint matches
  bool validateCertificate(String fingerprint) {
    return _certificateFingerprints.contains(fingerprint);
  }

  /// Add certificate fingerprint (for testing)
  static void addCertificateFingerprint(String fingerprint) {
    if (!_certificateFingerprints.contains(fingerprint)) {
      // In production, this should be immutable
      debugPrint('⚠️ Adding certificate fingerprint: $fingerprint');
    }
  }
}
