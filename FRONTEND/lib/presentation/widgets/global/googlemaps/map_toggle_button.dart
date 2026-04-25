import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';

class MapToggleButton extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const MapToggleButton({
    super.key,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
            size: ResponsiveUtils.fontSize(context, 20),
            color: const Color(0xFF5F2D82),
          ),
        ),
      ),
    );
  }
}
