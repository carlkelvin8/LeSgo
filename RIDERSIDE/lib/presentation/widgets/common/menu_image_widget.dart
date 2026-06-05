import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/utils/media_url_utils.dart';

/// Displays a menu/partner image from network URL, local file, or asset path.
class MenuImageWidget extends StatelessWidget {
  final String? source;
  final BoxFit fit;
  final Widget? placeholder;

  const MenuImageWidget({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final path = source?.trim();
    if (path == null || path.isEmpty) {
      return placeholder ?? const SizedBox.shrink();
    }

    final networkUrl = MediaUrlUtils.resolve(path);
    if (networkUrl != null) {
      return Image.network(
        networkUrl,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder ?? const SizedBox.shrink(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }

    if (MediaUrlUtils.isLocalFilePath(path)) {
      return Image.file(
        File(path),
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder ?? const SizedBox.shrink(),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder ?? const SizedBox.shrink(),
      );
    }

    return placeholder ?? const SizedBox.shrink();
  }
}
