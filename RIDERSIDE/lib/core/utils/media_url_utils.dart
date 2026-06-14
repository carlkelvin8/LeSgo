import '../constants/api_constants.dart';

class MediaUrlUtils {
  MediaUrlUtils._();

  static String get _apiBase => ApiConstants.baseUrl;

  /// Laravel Cloud object storage public CDN (menu/profile uploads).
  static const objectStoragePublicBase =
      'https://fls-a1f3a0d3-8dcf-4aa4-a31e-a5a91cc91c92.laravel.cloud';

  static bool isHttpUrl(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  /// Paths returned by the API (not device file paths).
  static bool isApiMediaPath(String? path) {
    if (path == null || path.isEmpty) return false;
    if (isHttpUrl(path)) return true;
    if (path.startsWith('content://') || path.startsWith('file://')) {
      return false;
    }
    if (path.startsWith('/storage/emulated/')) return false;
    if (path.startsWith('/data/') || path.startsWith('/sdcard/')) {
      return false;
    }
    if (path.contains(':\\')) return false;
    if (path.startsWith('/storage/') || path.startsWith('storage/')) {
      return true;
    }
    if (path.contains('/v1/storage/')) return true;
    if (path.startsWith('uploads/') ||
        path.startsWith('menu_items/') ||
        path.startsWith('profile_pictures/') ||
        path.startsWith('public/')) {
      return true;
    }
    return false;
  }

  /// Local file from image picker or camera.
  static bool isLocalFilePath(String? path) {
    if (path == null || path.isEmpty) return false;
    if (path.startsWith('content://') ||
        path.startsWith('file://') ||
        path.startsWith('/data/') ||
        path.startsWith('/sdcard/') ||
        path.contains(':\\')) {
      return true;
    }
    if (isApiMediaPath(path)) return false;
    if (path.startsWith('assets/')) return false;
    if (path.startsWith('/')) return true;
    return false;
  }

  /// Build URL for Laravel `/api/v1/storage/{path}` (CORS-enabled file serving).
  static String apiStorageUrl(String relativePath) {
    var p = relativePath.trim();
    while (p.startsWith('/')) {
      p = p.substring(1);
    }
    if (p.startsWith('storage/')) {
      p = p.substring('storage/'.length);
    }
    if (p.startsWith('public/')) {
      p = p.substring('public/'.length);
    }
    return '$_apiBase/v1/storage/$p';
  }

  static String? _rewriteHttpStorageUrl(String url) {
    if (url.contains('/api/v1/storage/')) return url;

    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    const marker = '/storage/';
    final path = uri.path;
    final idx = path.indexOf(marker);
    if (idx >= 0) {
      final relative = path.substring(idx + marker.length);
      return apiStorageUrl(relative);
    }
    return url;
  }

  /// Build URL for Laravel `/api/v1/proof-images/{orderId}/{filename}`.
  static String? proofImageApiUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;

    var relative = path.trim().replaceAll('\\', '/');
    while (relative.startsWith('/')) {
      relative = relative.substring(1);
    }

    const marker = '/api/v1/proof-images/';
    if (isHttpUrl(relative)) {
      final idx = relative.indexOf(marker);
      if (idx >= 0) return relative;
      return null;
    }

    final match = RegExp(r'^proof_images/(\d+)/([^/]+)$').firstMatch(relative);
    if (match == null) return null;

    return '$_apiBase/v1/proof-images/${match.group(1)}/${match.group(2)}';
  }

  /// Prefer API-resolved `proof_image_urls`, then normalize `proof_images`.
  static List<String> parseProofImageUrls(Map<String, dynamic> order) {
    final resolved = order['proof_image_urls'];
    if (resolved is List && resolved.isNotEmpty) {
      return resolved
          .map((item) => item.toString())
          .where((url) => url.isNotEmpty)
          .map((url) => resolveProofImageUrl(url))
          .whereType<String>()
          .toList();
    }

    final raw = order['proof_images'];
    if (raw == null) return [];

    if (raw is String && raw.isNotEmpty) {
      final url = resolveProofImageUrl(raw);
      return url == null ? [] : [url];
    }

    if (raw is List) {
      return raw
          .map((item) => item.toString())
          .where((url) => url.isNotEmpty)
          .map((url) => resolveProofImageUrl(url))
          .whereType<String>()
          .toList();
    }

    return [];
  }

  static String? resolveProofImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;

    final trimmed = path.trim();
    if (isHttpUrl(trimmed)) {
      if (trimmed.contains('/api/v1/proof-images/')) return trimmed;
      return resolve(trimmed) ?? trimmed;
    }

    if (trimmed.startsWith('proof_images/')) {
      return objectStorageUrl(trimmed) ??
          proofImageApiUrl(trimmed) ??
          apiStorageUrl(trimmed);
    }

    return resolve(trimmed) ?? proofImageApiUrl(trimmed);
  }

  /// Returns an absolute URL suitable for [Image.network].
  static String? resolve(String? path) {
    if (path == null || path.trim().isEmpty) return null;

    final trimmed = path.trim();
    if (isLocalFilePath(trimmed)) return null;

    if (isHttpUrl(trimmed)) {
      const apiMarker = '/api/v1/storage/';
      final apiIdx = trimmed.indexOf(apiMarker);
      if (apiIdx >= 0) {
        final relative = trimmed.substring(apiIdx + apiMarker.length);
        return objectStorageUrl(relative) ?? apiStorageUrl(relative);
      }
      return _rewriteHttpStorageUrl(trimmed);
    }

    return objectStorageUrl(trimmed) ?? apiStorageUrl(trimmed);
  }

  /// Normalize API/upload paths to absolute URLs for API `*_url` fields.
  static String? toAbsoluteUrl(String? path) => resolve(path);

  /// Build Laravel Cloud object storage URL from a relative upload path.
  static String? objectStorageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;

    var relative = path.trim().replaceAll('\\', '/');
    if (isHttpUrl(relative)) {
      const apiMarker = '/api/v1/storage/';
      final apiIdx = relative.indexOf(apiMarker);
      if (apiIdx >= 0) {
        relative = relative.substring(apiIdx + apiMarker.length);
      } else {
        final base = '$objectStoragePublicBase/';
        if (relative.startsWith(base)) {
          relative = relative.substring(base.length);
        } else {
          return relative;
        }
      }
    }

    while (relative.startsWith('/')) {
      relative = relative.substring(1);
    }
    if (relative.startsWith('storage/')) {
      relative = relative.substring('storage/'.length);
    }
    if (relative.startsWith('public/')) {
      relative = relative.substring('public/'.length);
    }

    return '$objectStoragePublicBase/$relative';
  }
}
