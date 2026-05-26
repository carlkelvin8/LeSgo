import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../provider/main/booking/lesride_location_provider.dart';
import '../../../../core/utils/booking_geo_utils.dart';
import '../../../../core/utils/marker_utils.dart';

class LesrideMapWidget extends ConsumerStatefulWidget {
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onToggleFullscreen;
  final Function(LatLng) onMapTap;
  final bool isFullscreen;
  final bool showPickupDestination;

  const LesrideMapWidget({
    super.key,
    required this.onMapCreated,
    required this.onUseCurrentLocation,
    required this.onToggleFullscreen,
    required this.onMapTap,
    required this.isFullscreen,
    this.showPickupDestination = true,
  });

  @override
  ConsumerState<LesrideMapWidget> createState() => _LesrideMapWidgetState();
}

class _LesrideMapWidgetState extends ConsumerState<LesrideMapWidget> {
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

  @override
  Widget build(BuildContext context) {
    final pickup = ref.watch(
      lesrideLocationProvider.select((s) => s.pickupLocation),
    );
    final destination = ref.watch(
      lesrideLocationProvider.select((s) => s.destinationLocation),
    );
    final selected = ref.watch(
      lesrideLocationProvider.select((s) => s.selectedLocation),
    );
    final polylines = ref.watch(
      lesrideLocationProvider.select((s) => s.routePolylines),
    );
    final isLoadingRoute = ref.watch(
      lesrideLocationProvider.select((s) => s.isLoadingRoute),
    );
    final distanceKm = ref.watch(
      lesrideLocationProvider.select((s) => s.distanceInKm),
    );
    final durationSec = ref.watch(
      lesrideLocationProvider.select((s) => s.durationInSeconds),
    );

    final markers = <Marker>{};
    
    // IMPORTANT: Only show markers if we have valid locations
    // This prevents showing stale markers during updates
    if (widget.showPickupDestination && pickup != null && _purpleMarker != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: _purpleMarker!,
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }
    
    // Only show destination marker if we have a destination location
    // AND it's different from pickup (to avoid duplicate markers)
    if (widget.showPickupDestination &&
        destination != null &&
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
    
    // Only show selected marker during fullscreen selection
    // AND only if it's different from both pickup and destination
    if (selected != null &&
        widget.isFullscreen &&
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

    return RepaintBoundary(
      child: Stack(
      children: [
        GoogleMap(
          key: const ValueKey('lesride_map_stable'),
          mapType: MapType.normal,
          onMapCreated: (controller) {
            _mapController = controller;
            widget.onMapCreated(controller);
          },
          initialCameraPosition: CameraPosition(
            target: selected ?? BookingGeoUtils.defaultLatLng,
            zoom: 16.0,
          ),
          onTap: widget.onMapTap,
          markers: markers,
          polylines: polylines,
          myLocationEnabled: true, // Re-enabled
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true, // Enable built-in zoom controls
          mapToolbarEnabled: false,
          compassEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          trafficEnabled: false,
          buildingsEnabled: false,
          indoorViewEnabled: false,
          liteModeEnabled: false,
        ),
        
        // Route info overlay when both locations are set
        if (pickup != null && destination != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isLoadingRoute
                  ? Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF7B1FA2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Calculating route...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    )
                  : distanceKm != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7B1FA2).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.route,
                                    color: Color(0xFF7B1FA2),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${distanceKm!.toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (durationSec != null)
                                        Text(
                                          '${(durationSec! / 60).ceil()} min estimated',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Route Ready',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: const Text(
                                'Tap "Confirm location" to calculate route',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        
        // Red line overlay removed - only using blue polylines now
        
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
                foregroundColor: const Color(0xFF7B1FA2),
                elevation: 4,
                heroTag: "zoom_in", // Unique hero tag
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
                foregroundColor: const Color(0xFF7B1FA2),
                elevation: 4,
                heroTag: "zoom_out", // Unique hero tag
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
                foregroundColor: const Color(0xFF7B1FA2),
                elevation: 4,
                heroTag: "my_location", // Unique hero tag
                onPressed: widget.onUseCurrentLocation,
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 8),
              // Center Map Button
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF7B1FA2),
                elevation: 4,
                heroTag: "center_map", // Unique hero tag
                onPressed: () {
                  if (pickup != null && destination != null) {
                    _fitMarkersInView(pickup, destination);
                  } else {
                    final current =
                        ref.read(lesrideLocationProvider).currentLocation;
                    if (current != null) _centerOnLocation(current);
                  }
                },
                child: const Icon(Icons.center_focus_strong),
              ),
              const SizedBox(height: 8),
              // Map Type Toggle Button
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF7B1FA2),
                elevation: 4,
                heroTag: "map_type", // Unique hero tag
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
    ),
    );
  }

  void _fitMarkersInView(LatLng pickup, LatLng destination) {
    if (_mapController == null) return;
    
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

// RouteLinePainter and RouteLineOverlay removed - using only Google Maps polylines now

// Pulsing marker painter for animated pickup marker
class PulsingMarkerPainter extends CustomPainter {
  final LatLng location;
  final GoogleMapController? mapController;
  final double pulseScale;
  final Color color;

  PulsingMarkerPainter({
    required this.location,
    this.mapController,
    required this.pulseScale,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (mapController == null) return;

    try {
      // Convert LatLng to screen coordinates
      // Note: This is a simplified approach - in production you'd use proper coordinate conversion
      final centerX = size.width * 0.5;
      final centerY = size.height * 0.5;
      
      // Draw pulsing circle around pickup marker
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final radius = 30.0 * pulseScale;
      canvas.drawCircle(
        Offset(centerX, centerY),
        radius,
        paint,
      );

      // Draw inner ring
      final ringPaint = Paint()
        ..color = color.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(
        Offset(centerX, centerY),
        radius * 0.7,
        ringPaint,
      );
    } catch (e) {
      // Ignore painting errors
    }
  }

  @override
  bool shouldRepaint(covariant PulsingMarkerPainter oldDelegate) {
    return oldDelegate.pulseScale != pulseScale ||
           oldDelegate.location != location;
  }
}
