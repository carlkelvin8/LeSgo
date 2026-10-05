import 'package:flutter/material.dart';
import '../../../core/utils/utils.dart';

class TopBar extends StatelessWidget {
  final String? title;
  final Widget? centerWidget;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const TopBar({
    super.key,
    this.title,
    this.centerWidget,
    this.onBackPressed,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: ResponsiveUtils.imageHeight(context, 40),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Center content - either title text or custom widget
            Align(
              alignment: Alignment.center,
              child: centerWidget ??
                  Text(
                    title ?? '',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 18),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
            ),

            // Back button (left)
            if (showBackButton)
              Positioned(
                left: 0,
                child: GestureDetector(
                  onTap: onBackPressed ??
                      () {
                        Navigator.of(context).maybePop();
                      },
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: ResponsiveUtils.imageHeight(context, 32),
                    color: const Color(0xFF5F2D82),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
