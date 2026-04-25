import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';

class MapZoomControls extends StatelessWidget {
  final VoidCallback onToggleFullscreen;
  final bool isFullscreen;

  const MapZoomControls({
    super.key,
    required this.onToggleFullscreen,
    this.isFullscreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onToggleFullscreen,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: ResponsiveUtils.spacing(context, 40),
          height: ResponsiveUtils.spacing(context, 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            size: ResponsiveUtils.fontSize(context, 20),
            color: const Color(0xFF5F2D82),
          ),
        ),
      ),
    );
  }
}
