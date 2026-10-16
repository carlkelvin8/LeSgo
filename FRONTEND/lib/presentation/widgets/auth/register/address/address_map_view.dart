import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/constants/map_styles.dart';

class AddressMapView extends StatelessWidget {
  final LatLng? location;
  final Function(GoogleMapController) onMapCreated;
  final Function(LatLng) onMapTap;

  const AddressMapView({
    super.key,
    required this.location,
    required this.onMapCreated,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    if (location == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
      );
    }

    return GoogleMap(
      style: MapStyles.darkIfDark(context),
      onMapCreated: onMapCreated,
      initialCameraPosition: CameraPosition(target: location!, zoom: 16.0),
      onTap: onMapTap,
      markers: {
        Marker(
          markerId: const MarkerId('selected'),
          position: location!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: const InfoWindow(title: 'Selected Address'),
        ),
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      // Temporarily disable advanced markers to fix booking issue
      // markerType: GoogleMapMarkerType.advancedMarker,
    );
  }
}
