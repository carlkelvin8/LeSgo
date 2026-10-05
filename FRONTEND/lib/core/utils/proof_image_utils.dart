import 'dart:convert';

import '../constants/api_constants.dart';
import 'media_url_utils.dart';

class ProofImageUtils {
  ProofImageUtils._();

  /// Extract proof URLs from an order JSON payload.
  static List<String> fromOrderMap(Map<String, dynamic> json) {
    final orderId = _orderIdFromJson(json);
    final fromUrls = parseUrls(json['proof_image_urls'], orderId: orderId);
    if (fromUrls.isNotEmpty) return fromUrls;
    return parseUrls(json['proof_images'], orderId: orderId);
  }

  /// Normalize order JSON so DTO parsing always gets resolved proof URLs.
  static Map<String, dynamic> normalizeOrderJson(Map<String, dynamic> json) {
    final proofs = fromOrderMap(json);
    if (proofs.isEmpty) return json;
    return {
      ...json,
      'proof_images': proofs,
      'proof_image_urls': proofs,
    };
  }

  /// Parse `proof_images` from API (list, JSON string, map, or single path).
  static List<String> parseUrls(dynamic proofData, {int? orderId}) {
    if (proofData == null) return [];

    dynamic raw = proofData;
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return [];
      if (trimmed.startsWith('[')) {
        try {
          raw = jsonDecode(trimmed);
        } catch (_) {
          return [_resolve(trimmed, orderId: orderId)];
        }
      } else {
        return [_resolve(trimmed, orderId: orderId)];
      }
    }

    if (raw is Map) {
      final url = raw['url'] ?? raw['path'] ?? raw['image_url'];
      if (url != null) {
        return [_resolve(url.toString(), orderId: orderId)];
      }
      return [];
    }

    if (raw is List) {
      return raw
          .expand((item) {
            if (item is Map) {
              final url = item['url'] ?? item['path'] ?? item['image_url'];
              if (url != null) {
                return [_resolve(url.toString(), orderId: orderId)];
              }
              return const <String>[];
            }
            final path = item?.toString() ?? '';
            if (path.isEmpty) return const <String>[];
            return [_resolve(path, orderId: orderId)];
          })
          .where((url) => url.isNotEmpty)
          .toList();
    }

    return [];
  }

  static String _resolve(String path, {int? orderId}) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return trimmed;

    if (MediaUrlUtils.isHttpUrl(trimmed)) {
      return MediaUrlUtils.resolve(trimmed) ?? trimmed;
    }

    final normalized = trimmed.replaceAll('\\', '/').replaceAll(RegExp('^/+'), '');

    final proofMatch =
        RegExp(r'^proof_images/(\d+)/([^/]+)$').firstMatch(normalized);
    if (proofMatch != null) {
      return MediaUrlUtils.apiStorageUrl(normalized);
    }

    if (orderId != null && !normalized.contains('/')) {
      return MediaUrlUtils.apiStorageUrl('proof_images/$orderId/$normalized');
    }

    final storageUrl = MediaUrlUtils.resolve(normalized);
    if (storageUrl != null && storageUrl.isNotEmpty) {
      return storageUrl;
    }

    return normalized;
  }

  /// Alternate URL if primary proof image host fails (storage vs proof-images).
  static String? alternateProofUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    final proofEndpoint = RegExp(r'/v1/proof-images/(\d+)/([^/?#]+)');
    final proofMatch = proofEndpoint.firstMatch(trimmed);
    if (proofMatch != null) {
      return MediaUrlUtils.apiStorageUrl(
        'proof_images/${proofMatch.group(1)}/${proofMatch.group(2)}',
      );
    }

    final storageEndpoint = RegExp(r'/v1/storage/proof_images/(\d+)/([^/?#]+)');
    final storageMatch = storageEndpoint.firstMatch(trimmed);
    if (storageMatch != null) {
      return '${ApiConstants.baseUrl}/v1/proof-images/${storageMatch.group(1)}/${storageMatch.group(2)}';
    }

    return null;
  }

  static int? _orderIdFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is num) return id.toInt();
    return int.tryParse(id?.toString() ?? '');
  }
}
