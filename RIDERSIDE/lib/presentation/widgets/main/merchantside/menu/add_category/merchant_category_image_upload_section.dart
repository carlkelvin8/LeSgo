

import 'package:flutter/material.dart';
import '../../../../common/menu_image_widget.dart';

class MerchantCategoryImageUploadSection extends StatefulWidget {
  final VoidCallback onTap;
  final String? uploadedImagePath;
  final bool isDark;
  final bool compact;

  const MerchantCategoryImageUploadSection({
    super.key,
    required this.onTap,
    this.uploadedImagePath,
    this.isDark = false,
    this.compact = false,
  });

  @override
  State<MerchantCategoryImageUploadSection> createState() =>
      _MerchantCategoryImageUploadSectionState();
}

class _MerchantCategoryImageUploadSectionState
    extends State<MerchantCategoryImageUploadSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.uploadedImagePath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.compact) ...[
          // Label is provided by the parent screen
          const SizedBox(height: 0),
        ],
        AnimatedBuilder(
          animation: _press,
          builder: (_, child) => Transform.scale(
            scale: 1.0 - .015 * _press.value,
            child: child,
          ),
          child: GestureDetector(
            onTapDown: (_) => _press.forward(),
            onTapUp: (_) => _press.reverse(),
            onTapCancel: () => _press.reverse(),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: widget.compact ? 160 : 160,
              decoration: BoxDecoration(
                color: hasImage
                    ? Colors.transparent
                    : (widget.isDark
                        ? Colors.white.withValues(alpha: .05)
                        : const Color(0xFFFAF7FD)),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: hasImage
                      ? const Color(0xFF5F2D82).withValues(alpha: .40)
                      : (widget.isDark
                          ? const Color(0xFF2E2540)
                          : const Color(0xFFE0D4F5)),
                  width: hasImage ? 2 : 1.5,
                  style: hasImage ? BorderStyle.solid : BorderStyle.solid,
                ),
                boxShadow: hasImage
                    ? [
                        BoxShadow(
                          color: const Color(0xFF5F2D82)
                              .withValues(alpha: .15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                          spreadRadius: -4,
                        ),
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: hasImage
                    ? Stack(
                        children: [
                          // Image
                          Positioned.fill(
                            child: MenuImageWidget(
                              source: widget.uploadedImagePath,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Change overlay
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .55),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .20),
                                  width: .8,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_rounded,
                                      size: 13, color: Colors.white),
                                  SizedBox(width: 5),
                                  Text(
                                    'Change',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : _EmptyState(isDark: widget.isDark),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final bool compact = false;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: compact ? 40 : 52,
          height: compact ? 40 : 52,
          decoration: BoxDecoration(
            color: const Color(0xFF5F2D82).withValues(alpha: .10),
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
          ),
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: compact ? 18 : 24,
            color: const Color(0xFF8B55CC),
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          compact ? 'Upload photo' : 'Tap to upload photo',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: compact ? 11 : 13.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1A0A2E),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 4),
          Text(
            'Recommended: 400×300px',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 11,
              color: isDark
                  ? const Color(0xFF9A85B8)
                  : const Color(0xFFAA90C0),
            ),
          ),
        ],
      ],
    );
  }
}
