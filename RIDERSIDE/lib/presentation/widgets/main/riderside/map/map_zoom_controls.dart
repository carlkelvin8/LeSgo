import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
        // Zoom In Button
        _buildZoomButton(
          icon: Icons.add,
          onTap: () async {
            if (mapController != null) {
              try {
                await mapController!.animateCamera(CameraUpdate.zoomIn());
                if (onZoomIn != null) onZoomIn!();
                print('🔍 Zoomed In');
              } catch (e) {
                print('❌ Error zooming in: $e');
              }
            }
          },
        ),
        const SizedBox(height: 8),
        
        // Zoom Out Button
        _buildZoomButton(
          icon: Icons.remove,
          onTap: () async {
            if (mapController != null) {
              try {
                await mapController!.animateCamera(CameraUpdate.zoomOut());
                if (onZoomOut != null) onZoomOut!();
                print('🔍 Zoomed Out');
              } catch (e) {
                print('❌ Error zooming out: $e');
              }
            }
          },
        ),
        const SizedBox(height: 8),
        
        // Center Map Button
        _buildZoomButton(
          icon: Icons.my_location,
          onTap: () {
            if (onCenterMap != null) {
              onCenterMap!();
              print('🎯 Map Centered');
            }
          },
        ),
      ],
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
    );
  }
}