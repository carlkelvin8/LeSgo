import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/utils/media_url_utils.dart';
import '../../../core/utils/menu_image_utils.dart';

/// Displays a menu/partner/profile image from network URL, local file, or asset path.
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

    final candidates = MenuImageUtils.candidateUrls(path);
    if (candidates.isEmpty) {
      return placeholder ?? const SizedBox.shrink();
    }

    return _NetworkMenuImage(
      urls: candidates,
      fit: fit,
      placeholder: placeholder,
    );
  }
}

class _NetworkMenuImage extends StatefulWidget {
  final List<String> urls;
  final BoxFit fit;
  final Widget? placeholder;

  const _NetworkMenuImage({
    required this.urls,
    required this.fit,
    this.placeholder,
  });

  @override
  State<_NetworkMenuImage> createState() => _NetworkMenuImageState();
}

class _NetworkMenuImageState extends State<_NetworkMenuImage> {
  int _urlIndex = 0;

  @override
  void didUpdateWidget(covariant _NetworkMenuImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urls.join('|') != widget.urls.join('|')) {
      _urlIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.urls[_urlIndex];
    return Image.network(
      url,
      fit: widget.fit,
      errorBuilder: (_, __, ___) {
        if (_urlIndex + 1 < widget.urls.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _urlIndex++);
          });
          return widget.placeholder ??
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
        }
        return widget.placeholder ?? const SizedBox.shrink();
      },
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
}
