import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../provider/main/booking/lesgo_location_provider.dart';
import '../../../../core/utils/booking_geo_utils.dart';
import '../../../../core/utils/marker_utils.dart';

/// Map for LesGo — stable [GoogleMap] instance; marker/polyline updates only.
class LesgoMapWidget extends ConsumerStatefulWidget {
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onToggleFullscreen;
  final Function(LatLng) onMapTap;
  final bool isFullscreen;
  final bool showPickupDestination;

  const LesgoMapWidget({
    super.key,
    required this.onMapCreated,
    required this.onUseCurrentLocation,
    required this.onToggleFullscreen,
    required this.onMapTap,
    required this.isFullscreen,
    this.showPickupDestination = true,
  });

  @override
  ConsumerState<LesgoMapWidget> createState() => _LesgoMapWidgetState();
}

class _LesgoMapWidgetState extends ConsumerState<LesgoMapWidget> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _purpleMarker;
  BitmapDescriptor? _redMarker;
  BitmapDescriptor? _roseMarker;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    _purpleMarker = await MarkerUtils.violetMarker;
    _redMarker = await MarkerUtils.redMarker;
    _roseMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/marker_rose.png',
    ).catchError((_) async {
      return MarkerUtils.createColoredMarker(const Color(0xFFFF69B4));
    });
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers({
    required LatLng? pickup,
    required LatLng? destination,
    required LatLng? selected,
  }) {
    final markers = <Marker>{};
    if (!widget.showPickupDestination || _purpleMarker == null) {
      return markers;
    }

    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: _purpleMarker!,
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }

    if (destination != null &&
        _redMarker != null &&
        destination != pickup) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destination,
          icon: _redMarker!,
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }

    if (widget.isFullscreen &&
        selected != null &&
        _roseMarker != null &&
        selected != pickup &&
        selected != destination) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: selected,
          icon: _roseMarker!,
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final pickup = ref.watch(
      lesgoLocationProvider.select((s) => s.pickupLocation),
    );
    final destination = ref.watch(
      lesgoLocationProvider.select((s) => s.destinationLocation),
    );
    final selected = ref.watch(
      lesgoLocationProvider.select((s) => s.selectedLocation),
    );
    final polylines = ref.watch(
      lesgoLocationProvider.select((s) => s.routePolylines),
    );
    final isLoadingRoute = ref.watch(
      lesgoLocationProvider.select((s) => s.isLoadingRoute),
    );
    final distanceKm = ref.watch(
      lesgoLocationProvider.select((s) => s.distanceInKm),
    );
    final durationSec = ref.watch(
      lesgoLocationProvider.select((s) => s.durationInSeconds),
    );

    final markers = _buildMarkers(
      pickup: pickup,
      destination: destination,
      selected: selected,
    );
    final initialTarget = selected ?? BookingGeoUtils.defaultLatLng;

    return RepaintBoundary(
      child: Stack(
        children: [
          GoogleMap(
            key: const ValueKey('lesgo_map_stable'),
            onMapCreated: (controller) {
              _mapController = controller;
              widget.onMapCreated(controller);
            },
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 16.0,
            ),
            onTap: widget.onMapTap,
            markers: markers,
            polylines: polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),
          if (pickup != null && destination != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _RouteInfoBanner(
                isLoadingRoute: isLoadingRoute,
                distanceKm: distanceKm,
                durationSec: durationSec,
              ),
            ),
          Positioned(
            right: 16,
            bottom: 100,
            child: _MapControls(
              onZoomIn: () => _mapController?.animateCamera(
                CameraUpdate.zoomIn(),
              ),
              onZoomOut: () => _mapController?.animateCamera(
                CameraUpdate.zoomOut(),
              ),
              onMyLocation: widget.onUseCurrentLocation,
              onFitRoute: () => _fitMarkersInView(pickup!, destination!),
            ),
          ),
        ],
      ),
    );
  }

  void _fitMarkersInView(LatLng pickup, LatLng destination) {
    if (_mapController == null) return;
    final bounds = LatLngBounds(
      southwest: LatLng(
        pickup.latitude < destination.latitude
            ? pickup.latitude
            : destination.latitude,
        pickup.longitude < destination.longitude
            ? pickup.longitude
            : destination.longitude,
      ),
      northeast: LatLng(
        pickup.latitude > destination.latitude
            ? pickup.latitude
            : destination.latitude,
        pickup.longitude > destination.longitude
            ? pickup.longitude
            : destination.longitude,
      ),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }
}

class _RouteInfoBanner extends StatelessWidget {
  const _RouteInfoBanner({
    required this.isLoadingRoute,
    required this.distanceKm,
    required this.durationSec,
  });

  final bool isLoadingRoute;
  final double? distanceKm;
  final int? durationSec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isLoadingRoute
          ? const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Calculating route...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : distanceKm != null
              ? Row(
                  children: [
                    const Icon(Icons.route, color: Color(0xFF4285F4), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Route: ${distanceKm!.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (durationSec != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        '${(durationSec! / 60).ceil()} min',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                )
              : const Text(
                  'Tap "Confirm location" to calculate route',
                  style: TextStyle(fontSize: 14),
                ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
    required this.onFitRoute,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;
  final VoidCallback onFitRoute;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniFab(Icons.zoom_in, onZoomIn, 'lesgo_zoom_in'),
        const SizedBox(height: 8),
        _miniFab(Icons.zoom_out, onZoomOut, 'lesgo_zoom_out'),
        const SizedBox(height: 8),
        _miniFab(Icons.my_location, onMyLocation, 'lesgo_my_location'),
        const SizedBox(height: 8),
        _miniFab(Icons.center_focus_strong, onFitRoute, 'lesgo_center_map'),
      ],
    );
  }

  Widget _miniFab(IconData icon, VoidCallback onPressed, String heroTag) {
    return FloatingActionButton(
      mini: true,
      heroTag: heroTag,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF4285F4),
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}
