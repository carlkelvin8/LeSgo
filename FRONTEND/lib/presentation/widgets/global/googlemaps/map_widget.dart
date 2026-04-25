import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../provider/register/register_provider.dart';

class MapWidget extends ConsumerWidget {
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onToggleFullscreen;
  final Function(LatLng) onMapTap;
  final bool isFullscreen;

  const MapWidget({
    super.key,
    required this.onMapCreated,
    required this.onUseCurrentLocation,
    required this.onToggleFullscreen,
    required this.onMapTap,
    required this.isFullscreen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registerState = ref.watch(registerProvider);

    return GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: CameraPosition(
        target: registerState.selectedLocation ?? const LatLng(14.5995, 120.9842),
        zoom: 16.0,
      ),
      onTap: onMapTap,
      markers: registerState.selectedLocation != null
          ? {
              Marker(
                markerId: const MarkerId('selected'),
                position: registerState.selectedLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueViolet,
                ),
                infoWindow: const InfoWindow(title: 'Selected Location'),
              ),
            }
          : {},
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      // Temporarily disable advanced markers to fix booking issue
      // markerType: GoogleMapMarkerType.advancedMarker,
    );
  }
}

class LocationButton extends StatelessWidget {
  final VoidCallback onUseCurrentLocation;

  const LocationButton({
    super.key,
    required this.onUseCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onUseCurrentLocation,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.my_location,
                size: 16,
                color: Color(0xFF5F2D82),
              ),
              const SizedBox(width: 4),
              Text(
                'Use my current location',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
