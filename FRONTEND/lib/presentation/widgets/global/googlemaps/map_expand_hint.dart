import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';

class MapExpandHint extends StatelessWidget {
  final VoidCallback? onTap;

  const MapExpandHint({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: ResponsiveUtils.spacing(context, 12),
      child: IgnorePointer(
        ignoring: onTap == null,
        child: GestureDetector(
          onTap: onTap,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.spacing(context, 14),
                vertical: ResponsiveUtils.spacing(context, 8),
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.open_in_full, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Tap to expand map',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
