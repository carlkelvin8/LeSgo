import '../constants/api_constants.dart';

class MediaUrlUtils {
  MediaUrlUtils._();

  static String get _apiBase => ApiConstants.baseUrl;

  static bool isHttpUrl(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  /// Paths returned by the API (not device file paths).
  static bool isApiMediaPath(String? path) {
    if (path == null || path.isEmpty) return false;
    if (isHttpUrl(path)) return true;
    if (path.startsWith('/storage/emulated/')) return false;
    if (path.startsWith('/storage/') || path.startsWith('storage/')) {
      return true;
    }
    if (path.contains('/v1/storage/')) return true;
    if (!path.startsWith('/') && !path.contains(':\\')) {
      return true;
    }
    return false;
  }

  /// Local file from image picker or camera.
  static bool isLocalFilePath(String? path) {
    if (path == null || path.isEmpty) return false;
    if (isApiMediaPath(path)) return false;
    if (path.startsWith('assets/')) return false;
    return true;
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

  /// Returns an absolute URL suitable for [Image.network].
  static String? resolve(String? path) {
    if (path == null || path.trim().isEmpty) return null;

    final trimmed = path.trim();
    if (isLocalFilePath(trimmed)) return null;

    if (isHttpUrl(trimmed)) {
      return _rewriteHttpStorageUrl(trimmed);
    }

    return apiStorageUrl(trimmed);
  }

  /// Normalize API/upload paths to absolute URLs for API `*_url` fields.
  static String? toAbsoluteUrl(String? path) => resolve(path);

  /// Resolve API media path or fall back to a bundled asset placeholder.
  static String resolveOrAsset(String? path, String fallbackAsset) {
    if (path == null || path.trim().isEmpty) return fallbackAsset;
    return resolve(path) ?? path;
  }
}
