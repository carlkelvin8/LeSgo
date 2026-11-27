import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../config/secrets_config.dart';
import '../constants/api_constants.dart';

/// Restricts the API host to its pinned leaf certificate or its known CAs, on
/// top of the platform TLS trust checks.
///
/// Keep at least two comma-separated pins during certificate rotation. An
/// untrusted certificate is rejected by the platform before this callback is
/// reached; this service never installs a permissive badCertificateCallback.
@lazySingleton
class SslPinningService {
  static Set<String> get _certificateFingerprints => SecretsConfig
      .apiCertificateSha256Pins
      .split(',')
      .map(_normalizeFingerprint)
      .where((pin) => pin.isNotEmpty)
      .toSet();

  void configureSslPinning(Dio dio) {
    final apiUri = Uri.parse(ApiConstants.baseUrl);
    if (apiUri.scheme != 'https') {
      debugPrint('SSL pinning is not applicable to ${apiUri.scheme} URLs.');
      return;
    }

    final adapter = dio.httpClientAdapter;
    if (adapter is! IOHttpClientAdapter) {
      debugPrint('SSL pinning is unavailable for this HTTP adapter.');
      return;
    }

    adapter.validateCertificate = (certificate, host, port) {
      if (host.toLowerCase() != pinnedApiHost.toLowerCase()) {
        return true;
      }

      if (certificate == null) {
        debugPrint('SSL pinning rejected $host:$port: no certificate.');
        return false;
      }

      final fingerprint = _sha256Fingerprint(certificate);
      // The API certificate is renewed automatically every ~90 days, so a
      // leaf pin alone would lock every installed app out on renewal. Accept
      // the pinned leaf, or any certificate issued by the CAs our host uses.
      final accepted =
          validateCertificate(fingerprint) ||
          isTrustedIssuer(certificate.issuer);
      if (!accepted) {
        debugPrint(
          'SSL pinning rejected an unexpected certificate for $host:$port.',
        );
      }
      return accepted;
    };
  }

  static String _sha256Fingerprint(X509Certificate certificate) {
    final digest = sha256.convert(certificate.der);
    return digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
  }

  bool validateCertificate(String fingerprint) {
    return _certificateFingerprints.contains(
      _normalizeFingerprint(fingerprint),
    );
  }

  /// Certificate authorities the API host's provider issues from.
  static const trustedIssuerOrganizations = [
    'Google Trust Services',
    "Let's Encrypt",
    'SSL Corporation',
    'Sectigo Limited',
  ];

  /// Whether [issuer] (an X.509 issuer DN) names one of our host's CAs.
  /// The platform has already verified the chain before this is consulted.
  static bool isTrustedIssuer(String issuer) {
    final organization = RegExp(r'(?:^|[,/])\s*O=([^,/]+)')
        .firstMatch(issuer)
        ?.group(1)
        ?.trim();
    if (organization == null) return false;
    return trustedIssuerOrganizations.contains(organization);
  }

  static String _normalizeFingerprint(String value) {
    final compact = value.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toUpperCase();
    if (compact.length != 64) return '';

    return List.generate(
      32,
      (index) => compact.substring(index * 2, index * 2 + 2),
    ).join(':');
  }

  static String get pinnedApiHost => Uri.parse(ApiConstants.baseUrl).host;
}
