import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lesgo/core/theme/app_colors.dart';

import '../../../core/utils/menu_image_utils.dart';

/// Renders local assets, SVG assets, or remote API/storage images.
class MediaImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;

  const MediaImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
  });

  bool get _isAsset => imagePath.startsWith('assets/');
  bool get _isSvgAsset =>
      _isAsset && imagePath.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    if (_isSvgAsset) {
      return SvgPicture.asset(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        placeholderBuilder: (_) => _fallback(context: context),
      );
    }

    if (_isAsset) {
      return Image.asset(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _fallback(context: context),
      );
    }

    final candidates = MenuImageUtils.candidateUrls(imagePath);
    if (candidates.isEmpty) {
      return _fallback(context: context);
    }

    return _NetworkMediaImage(
      urls: candidates,
      fit: fit,
      width: width,
      height: height,
      fallback: ({bool showProgress = false}) =>
          _fallback(showProgress: showProgress, context: context),
    );
  }

  Widget _fallback({bool showProgress = false, BuildContext? context}) {
    if (placeholder != null) return placeholder!;
    final bgColor = context != null
        ? AppColors.surface(context, Colors.grey[200]!)
        : Colors.grey[200]!;
    final iconColor = context != null
        ? AppColors.foreground(context, Colors.grey[400]!)
        : Colors.grey[400]!;
    return Container(
      width: width,
      height: height,
      color: bgColor,
      child: Center(
        child: showProgress
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.image_not_supported, color: iconColor, size: 24),
      ),
    );
  }
}

class _NetworkMediaImage extends StatefulWidget {
  final List<String> urls;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function({bool showProgress}) fallback;

  const _NetworkMediaImage({
    required this.urls,
    required this.fit,
    required this.width,
    required this.height,
    required this.fallback,
  });

  @override
  State<_NetworkMediaImage> createState() => _NetworkMediaImageState();
}

class _NetworkMediaImageState extends State<_NetworkMediaImage> {
  int _urlIndex = 0;

  @override
  void didUpdateWidget(covariant _NetworkMediaImage oldWidget) {
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
      width: widget.width,
      height: widget.height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return widget.fallback(showProgress: true);
      },
      errorBuilder: (_, __, ___) {
        if (_urlIndex + 1 < widget.urls.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _urlIndex += 1);
            }
          });
          return widget.fallback(showProgress: true);
        }
        return widget.fallback();
      },
    );
  }
}
