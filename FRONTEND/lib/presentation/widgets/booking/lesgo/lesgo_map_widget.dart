import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../provider/main/booking/lesgo_location_provider.dart';
import '../../../../core/utils/marker_utils.dart';

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
      // Fallback to custom marker if asset doesn't exist
      return MarkerUtils.createColoredMarker(const Color(0xFFFF69B4));
    });
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _updateMarkers() async {
    if (_mapController != null) {
      // Force map to refresh by moving camera slightly
      final currentPos = await _mapController!.getVisibleRegion();
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(currentPos.southwest),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(lesgoLocationProvider);
    
    // Debug: Log polylines state
    print('🗺️ LesgoMapWidget: Building with ${locationState.routePolylines.length} polylines');
    if (locationState.routePolylines.isNotEmpty) {
      final polyline = locationState.routePolylines.first;
      print('🗺️ LesgoMapWidget: Polyline has ${polyline.points.length} points');
    }

    final markers = <Marker>{};
    
    // IMPORTANT: Only show markers if we have valid locations
    // This prevents showing stale markers during updates
    if (widget.showPickupDestination && locationState.pickupLocation != null && _purpleMarker != null) {
      print('🎨 LesgoMapWidget: Adding PURPLE pickup marker at ${locationState.pickupLocation}');
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: locationState.pickupLocation!,
          icon: _purpleMarker!,
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }
    
    // Only show destination marker if we have a destination location
    // AND it's different from pickup (to avoid duplicate markers)
    if (widget.showPickupDestination && 
        locationState.destinationLocation != null && 
        _redMarker != null &&
        locationState.destinationLocation != locationState.pickupLocation) {
      print('🎨 LesgoMapWidget: Adding RED destination marker at ${locationState.destinationLocation}');
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: locationState.destinationLocation!,
          icon: _redMarker!,
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }
    
    // Only show selected marker during fullscreen selection
    // AND only if it's different from both pickup and destination
    if (locationState.selectedLocation != null && 
        widget.isFullscreen && 
        _roseMarker != null &&
        locationState.selectedLocation != locationState.pickupLocation &&
        locationState.selectedLocation != locationState.destinationLocation) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: locationState.selectedLocation!,
          icon: _roseMarker!,
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          key: ValueKey('lesgo_map_${locationState.pickupLocation}_${locationState.destinationLocation}_${locationState.routePolylines.length}'),
          onMapCreated: (controller) {
            _mapController = controller;
            widget.onMapCreated(controller);
            // Debug: Log polylines being passed to LesGo map
            print('🗺️ LesgoMapWidget: Map created with ${locationState.routePolylines.length} polylines');
            for (var polyline in locationState.routePolylines) {
              print('🗺️ LesgoMapWidget: Polyline ${polyline.polylineId.value} has ${polyline.points.length} points, color: ${polyline.color}, width: ${polyline.width}');
            }
          },
          initialCameraPosition: CameraPosition(
            target:
                locationState.selectedLocation ?? const LatLng(14.5995, 120.9842), // Manila default
            zoom: 16.0,
          ),
          onTap: widget.onMapTap,
          markers: markers,
          polylines: locationState.routePolylines, // Re-enabled polylines for LesGo
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true, // Enable built-in zoom controls
          mapToolbarEnabled: false,
        ),
        
        // Route info overlay when both locations are set
        if (locationState.pickupLocation != null && 
            locationState.destinationLocation != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: locationState.isLoadingRoute
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF4285F4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Calculating route...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    )
                  : locationState.distanceInKm != null
                      ? Row(
                          children: [
                            const Icon(
                              Icons.route,
                              color: Color(0xFF4285F4),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Route: ${locationState.distanceInKm!.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            if (locationState.durationInSeconds != null) ...[
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.access_time,
                                color: Color(0xFF4285F4),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(locationState.durationInSeconds! / 60).ceil()} min',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF4285F4),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tap "Confirm location" to calculate route',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        
        // Floating action buttons for map controls
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom In Button
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4285F4), // LesGo blue color
                elevation: 4,
                heroTag: "lesgo_zoom_in", // Unique hero tag for LesGo
                onPressed: () async {
                  if (_mapController != null) {
                    await _mapController!.animateCamera(CameraUpdate.zoomIn());
                  }
                },
                child: const Icon(Icons.zoom_in),
              ),
              const SizedBox(height: 8),
              // Zoom Out Button
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4285F4), // LesGo blue color
                elevation: 4,
                heroTag: "lesgo_zoom_out", // Unique hero tag for LesGo
                onPressed: () async {
                  if (_mapController != null) {
                    await _mapController!.animateCamera(CameraUpdate.zoomOut());
                  }
                },
                child: const Icon(Icons.zoom_out),
              ),
              const SizedBox(height: 8),
              // My Location Button
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4285F4), // LesGo blue color
                elevation: 4,
                heroTag: "lesgo_my_location", // Unique hero tag for LesGo
                onPressed: widget.onUseCurrentLocation,
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 8),
              // Center Map Button
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4285F4), // LesGo blue color
                elevation: 4,
                heroTag: "lesgo_center_map", // Unique hero tag for LesGo
                onPressed: () {
                  // Center map on route or current location
                  final locationState = ref.read(lesgoLocationProvider);
                  if (locationState.pickupLocation != null && 
                      locationState.destinationLocation != null) {
                    // Fit both markers
                    _fitMarkersInView(locationState);
                  } else if (locationState.currentLocation != null) {
                    // Center on current location
                    _centerOnLocation(locationState.currentLocation!);
                  }
                },
                child: const Icon(Icons.center_focus_strong),
              ),
              const SizedBox(height: 8),
              // Map Type Toggle Button
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4285F4), // LesGo blue color
                elevation: 4,
                heroTag: "lesgo_map_type", // Unique hero tag for LesGo
                onPressed: () {
                  // Toggle between normal and satellite view
                  // This would require adding map type state management
                },
                child: const Icon(Icons.layers),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to fit markers in view
  void _fitMarkersInView(LesgoLocationState locationState) {
    if (_mapController == null) return;
    
    final pickup = locationState.pickupLocation!;
    final destination = locationState.destinationLocation!;
    
    final bounds = LatLngBounds(
      southwest: LatLng(
        pickup.latitude < destination.latitude ? pickup.latitude : destination.latitude,
        pickup.longitude < destination.longitude ? pickup.longitude : destination.longitude,
      ),
      northeast: LatLng(
        pickup.latitude > destination.latitude ? pickup.latitude : destination.latitude,
        pickup.longitude > destination.longitude ? pickup.longitude : destination.longitude,
      ),
    );
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  // Helper method to center on location
  void _centerOnLocation(LatLng location) {
    if (_mapController == null) return;
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(location, 16.0),
    );
  }
}

