import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/map_styles.dart';
import '../../../core/utils/marker_utils.dart';
import '../../../core/utils/booking_geo_utils.dart';
import '../../provider/main/location/location_provider.dart';

class LocationMapWidget extends ConsumerStatefulWidget {
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onToggleFullscreen;
  final Function(LatLng) onMapTap;
  final Function(LatLng)? onMarkerDragEnd;
  final bool isFullscreen;
  final bool showPickupDestination;

  const LocationMapWidget({
    super.key,
    required this.onMapCreated,
    required this.onUseCurrentLocation,
    required this.onToggleFullscreen,
    required this.onMapTap,
    this.onMarkerDragEnd,
    required this.isFullscreen,
    this.showPickupDestination = true,
  });

  @override
  ConsumerState<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends ConsumerState<LocationMapWidget> {
  BitmapDescriptor? _roseMarker;

  @override
  void initState() {
    super.initState();
    _loadMarker();
  }

  Future<void> _loadMarker() async {
    _roseMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/marker_rose.png',
    ).catchError((_) async {
      return MarkerUtils.createColoredMarker(const Color(0xFFFF69B4));
    });
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);

    final markers = <Marker>{};
    if (widget.showPickupDestination && locationState.pickupLocation != null) {
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
    if (widget.showPickupDestination && locationState.destinationLocation != null) {
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
      final draggable = widget.isFullscreen && widget.onMarkerDragEnd != null;
      markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: locationState.selectedLocation!,
          icon: _roseMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: InfoWindow(
            title: 'Selected Location',
            snippet: draggable ? 'Drag to adjust pin' : null,
          ),
          draggable: draggable,
          onDragEnd: draggable
              ? (position) => widget.onMarkerDragEnd!(position)
              : null,
        ),
      );
    }

    return GoogleMap(
      onMapCreated: widget.onMapCreated,
      initialCameraPosition: CameraPosition(
        target:
            locationState.selectedLocation ??
            BookingGeoUtils.defaultLatLng,
        zoom: 16.0,
      ),
      onTap: widget.onMapTap,
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      style: MapStyles.darkIfDark(context),
      scrollGesturesEnabled: widget.isFullscreen,
      zoomGesturesEnabled: widget.isFullscreen,
      rotateGesturesEnabled: widget.isFullscreen,
      tiltGesturesEnabled: widget.isFullscreen,
    );
  }
}

