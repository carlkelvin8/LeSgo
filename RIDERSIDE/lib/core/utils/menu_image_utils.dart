import 'media_url_utils.dart';

class MenuImageUtils {
  MenuImageUtils._();

  /// Resolve a menu/partner/profile image field to a loadable absolute URL.
  static String? resolve(dynamic imageData) {
    if (imageData == null) return null;

    if (imageData is Map) {
      for (final key in ['url', 'image_url', 'icon_url', 'path', 'full_url', 'src']) {
        final nested = imageData[key];
        final resolved = resolve(nested);
        if (resolved != null && resolved.isNotEmpty) return resolved;
      }
      return null;
    }

    final raw = imageData.toString().trim();
    if (raw.isEmpty) return null;

    if (MediaUrlUtils.isHttpUrl(raw)) {
      return MediaUrlUtils.resolve(raw) ?? raw;
    }

    final normalized = raw.replaceAll('\\', '/').replaceAll(RegExp('^/+'), '');
    return MediaUrlUtils.resolve(normalized);
  }

  /// Alternate URLs to try when the primary image fails to load.
  static List<String> candidateUrls(String? path) {
    if (path == null || path.trim().isEmpty) return const [];

    final primary = resolve(path) ?? path.trim();
    final urls = <String>{primary};

    final objectUrl = MediaUrlUtils.objectStorageUrl(path);
    if (objectUrl != null) urls.add(objectUrl);

    if (MediaUrlUtils.isHttpUrl(primary)) {
      final uri = Uri.tryParse(primary);
      if (uri != null) {
        const apiMarker = '/api/v1/storage/';
        final apiIdx = uri.path.indexOf(apiMarker);
        if (apiIdx >= 0) {
          final relative = uri.path.substring(apiIdx + apiMarker.length);
          urls.add(MediaUrlUtils.apiStorageUrl(relative));
          final cloud = MediaUrlUtils.objectStorageUrl(relative);
          if (cloud != null) urls.add(cloud);
        }
      }
    } else {
      final resolved = MediaUrlUtils.resolve(primary);
      if (resolved != null) urls.add(resolved);
      final cloud = MediaUrlUtils.objectStorageUrl(primary);
      if (cloud != null) urls.add(cloud);
    }

    return urls.where((url) => url.isNotEmpty).toList();
  }

  /// Normalize partner menu JSON so item images resolve consistently.
  static Map<String, dynamic> normalizeMenuJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json);
    final payload = data['data'];
    if (payload is! Map) return data;

    final root = Map<String, dynamic>.from(payload);
    final categories = root['categories'];
    if (categories is! List) {
      data['data'] = root;
      return data;
    }

    root['categories'] = categories.map((category) {
      if (category is! Map) return category;
      final cat = Map<String, dynamic>.from(category);
      final resolvedCategoryImage = resolve(cat['icon_url'] ?? cat['image_url'] ?? cat['image']);
      if (resolvedCategoryImage != null) {
        cat['icon_url'] = resolvedCategoryImage;
        cat['image_url'] = resolvedCategoryImage;
      }

      final items = cat['available_items'];
      if (items is! List) return cat;

      cat['available_items'] = items.map((item) {
        if (item is! Map) return item;
        final map = Map<String, dynamic>.from(item);
        final resolved = resolve(map['image_url'] ?? map['image']);
        if (resolved != null) {
          map['image_url'] = resolved;
        }
        return map;
      }).toList();

      return cat;
    }).toList();

    data['data'] = root;
    return data;
  }
}
