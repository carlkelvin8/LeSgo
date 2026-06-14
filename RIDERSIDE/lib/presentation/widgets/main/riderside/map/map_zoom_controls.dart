import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/utils/app_logger.dart';

class MapZoomControls extends StatelessWidget {
  final GoogleMapController? mapController;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onCenterMap;

  const MapZoomControls({
    super.key,
    this.mapController,
    this.onZoomIn,
    this.onZoomOut,
    this.onCenterMap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildZoomButton(
          semanticsLabel: 'Zoom in on map',
          icon: Icons.add,
          onTap: () async {
            if (mapController == null) return;
            try {
              await mapController!.animateCamera(CameraUpdate.zoomIn());
              onZoomIn?.call();
            } catch (e) {
              AppLogger.error('Error zooming in', e);
            }
          },
        ),
        const SizedBox(height: 8),
        _buildZoomButton(
          semanticsLabel: 'Zoom out on map',
          icon: Icons.remove,
          onTap: () async {
            if (mapController == null) return;
            try {
              await mapController!.animateCamera(CameraUpdate.zoomOut());
              onZoomOut?.call();
            } catch (e) {
              AppLogger.error('Error zooming out', e);
            }
          },
        ),
        const SizedBox(height: 8),
        _buildZoomButton(
          semanticsLabel: 'Center map on current location',
          icon: Icons.my_location,
          onTap: () {
            onCenterMap?.call();
          },
        ),
      ],
    );
  }

  Widget _buildZoomButton({
    required String semanticsLabel,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Icon(
              icon,
              color: const Color(0xFF5F2D82),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
