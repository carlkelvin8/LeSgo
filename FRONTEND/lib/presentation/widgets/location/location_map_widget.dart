import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../provider/main/location/location_provider.dart';

class LocationMapWidget extends ConsumerWidget {
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onToggleFullscreen;
  final Function(LatLng) onMapTap;
  final bool isFullscreen;
  final bool showPickupDestination;

  const LocationMapWidget({
    super.key,
    required this.onMapCreated,
    required this.onUseCurrentLocation,
    required this.onToggleFullscreen,
    required this.onMapTap,
    required this.isFullscreen,
    this.showPickupDestination = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);

    final markers = <Marker>{};
    if (showPickupDestination && locationState.pickupLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: locationState.pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }
    if (showPickupDestination && locationState.destinationLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: locationState.destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }
    if (locationState.selectedLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: locationState.selectedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      );
    }

    return GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: CameraPosition(
        target:
            locationState.selectedLocation ??
            const LatLng(8.4542, 124.6319), // Cagayan de Oro default
        zoom: 16.0,
      ),
      onTap: onMapTap,
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      scrollGesturesEnabled: isFullscreen,
      zoomGesturesEnabled: isFullscreen,
      rotateGesturesEnabled: isFullscreen,
      tiltGesturesEnabled: isFullscreen,
      // Temporarily disable advanced markers to fix booking issue
      // markerType: GoogleMapMarkerType.advancedMarker,
    );
  }
}
