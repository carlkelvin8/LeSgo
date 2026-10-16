import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/utils/responsive_utils.dart';

class MapZoomControls extends StatelessWidget {
  final VoidCallback onToggleFullscreen;
  final bool isFullscreen;
  final GoogleMapController? mapController;
  final VoidCallback? onFitRoute;
  final bool showZoomButtons;

  const MapZoomControls({
    super.key,
    required this.onToggleFullscreen,
    this.isFullscreen = false,
    this.mapController,
    this.onFitRoute,
    this.showZoomButtons = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveUtils.spacing(context, 40);
    final iconSize = ResponsiveUtils.fontSize(context, 20);

    Widget controlButton({
      required IconData icon,
      required VoidCallback? onTap,
    }) {
      return Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: AppColors.surface(context, Colors.white),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: const Color(0xFF5F2D82),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showZoomButtons && mapController != null) ...[
          controlButton(
            icon: Icons.add,
            onTap: () => mapController!.animateCamera(CameraUpdate.zoomIn()),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          controlButton(
            icon: Icons.remove,
            onTap: () => mapController!.animateCamera(CameraUpdate.zoomOut()),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        ],
        if (onFitRoute != null) ...[
          controlButton(icon: Icons.center_focus_strong, onTap: onFitRoute),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        ],
        controlButton(
          icon: isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
          onTap: onToggleFullscreen,
        ),
      ],
    );
  }
}
