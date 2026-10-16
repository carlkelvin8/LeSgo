import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../common/menu_image_widget.dart';

class MerchantCategoryLivePreviewSection extends StatelessWidget {
  final String categoryName;
  final String? categoryImagePath;
  final int dishCount;
  final AnimationController? previewAnim;
  final bool isDark;
  final bool hideHeader;

  const MerchantCategoryLivePreviewSection({
    super.key,
    required this.categoryName,
    this.categoryImagePath,
    this.dishCount = 0,
    this.previewAnim,
    this.isDark = false,
    this.hideHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasName = categoryName.trim().isNotEmpty;
    final hasImage = categoryImagePath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hideHeader) ...[
          Row(
            children: [
              Text(
                'LIVE PREVIEW',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                color: isDark
                    ? const Color(0xFF9A85B8)
                    : const Color(0xFFAA90C0),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF22A060).withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF22A060),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Live',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF22A060),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ], // end if (!hideHeader)

        // Preview card
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2E2540)
                    : const Color(0xFFEDE9F2),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5F2D82)
                      .withValues(alpha: isDark ? .10 : .06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image area
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: hasImage
                      ? MenuImageWidget(
                          source: categoryImagePath,
                          fit: BoxFit.cover,
                        )
                      : previewAnim != null
                          ? AnimatedBuilder(
                              animation: previewAnim!,
                              builder: (_, __) => CustomPaint(
                                painter: _PreviewBgPainter(
                                  t: previewAnim!.value,
                                ),
                                child: Center(
                                  child: Opacity(
                                    opacity: .35,
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 44,
                                      color: isDark
                                          ? const Color(0xFF9A85B8)
                                          : const Color(0xFF8B55CC),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: isDark
                                  ? const Color(0xFF1E1730)
                                  : const Color(0xFFEDD9FF),
                              child: Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 44,
                                  color: isDark
                                      ? const Color(0xFF9A85B8)
                                      : const Color(0xFF8B55CC),
                                ),
                              ),
                            ),
                ),

                // Text area
                Container(
                  color: isDark ? const Color(0xFF1E1730) : Colors.white,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: hasName
                                    ? (isDark
                                        ? Colors.white
                                        : const Color(0xFF1A0A2E))
                                    : (isDark
                                        ? const Color(0xFF9A85B8)
                                        : const Color(0xFFCCBBDD)),
                              ),
                              child: Text(
                                hasName
                                    ? categoryName.trim()
                                    : 'Category Name',
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$dishCount ${dishCount == 1 ? 'dish' : 'dishes'}',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 11.5,
                                color: isDark
                                    ? const Color(0xFF9A85B8)
                                    : const Color(0xFFAA90C0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5F2D82)
                              .withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5F2D82),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Animated preview background ─────────────────────────────────────────────
class _PreviewBgPainter extends CustomPainter {
  final double t;
  const _PreviewBgPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF8B3FC8).withValues(alpha: .18 + .06 * t),
          const Color(0xFF5A1E88).withValues(alpha: .22 + .06 * t),
          const Color(0xFF2A0850).withValues(alpha: .28),
        ],
      ).createShader(rect),
    );
    // Drifting orb
    final orbX = size.width * (.30 + .40 * t);
    canvas.drawRect(
      rect,
      Paint()..shader = RadialGradient(
        colors: [
          const Color(0xFFBB66EE).withValues(alpha: .18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(orbX, size.height * .3),
        radius: size.width * .55,
      )),
    );
    // Rings
    final rp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    final rc = Offset(size.width * 1.05, -size.height * .05);
    for (var i = 0; i < 4; i++) {
      rp.color = Colors.white.withValues(alpha: .04 + i * .010);
      canvas.drawCircle(rc, size.width * (.25 + i * .14), rp);
    }
    // Shimmer
    final bx = -size.width * .3 + size.width * 1.6 * t;
    canvas.save();
    canvas.transform(Matrix4(
      math.cos(math.pi / 10), math.sin(math.pi / 10), 0, 0,
      -math.sin(math.pi / 10), math.cos(math.pi / 10), 0, 0,
      0, 0, 1, 0, 0, -size.height * .15, 0, 1,
    ).storage);
    canvas.drawRect(
      Rect.fromLTWH(bx, -10, size.width * .16, size.height * 1.4),
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: .06),
          Colors.white.withValues(alpha: .10),
          Colors.white.withValues(alpha: .06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(
          Rect.fromLTWH(bx, 0, size.width * .16, size.height)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PreviewBgPainter old) => old.t != t;
}
