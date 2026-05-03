import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../provider/main/riderside/rider_orders_provider.dart';
import '../../../../provider/main/riderside/rider_duty_provider.dart';
import '../../../../provider/main/riderside/rider_location_provider.dart';
import '../../../../provider/auth/rider_auth_provider.dart';
import '../../../../widgets/main/riderside/map/map_zoom_controls.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../core/utils/responsive_utils.dart';

// Custom painter for map pattern
class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    // Draw grid pattern
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for route line
class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.2, 170);
    path.quadraticBezierTo(
      size.width * 0.4, 150,
      size.width * 0.4, 220,
    );
    path.quadraticBezierTo(
      size.width * 0.6, 280,
      size.width * 0.8, 320,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class RiderMapScreen extends ConsumerStatefulWidget {
  final int? orderId; // Optional: if viewing a specific order

  const RiderMapScreen({
    super.key,
    this.orderId,
  });

  @override
  ConsumerState<RiderMapScreen> createState() => _RiderMapScreenState();
}

class _RiderMapScreenState extends ConsumerState<RiderMapScreen> {
  GoogleMapController? _mapController;
  bool _mapReady = false;
  Position? _currentPosition;
  bool _isLocationUpdating = false;
  Timer? _locationUpdateTimer;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final Completer<GoogleMapController> _controller = Completer();
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    print('🗺️ RiderMapScreen initState called - FIXED ZOOM CONTROLS v2');
    _initializeMap();
  }

  @override
  void dispose() {
    print('🗺️ RiderMapScreen dispose called');
    _stopLocationUpdates();
    _mapController = null;
    super.dispose();
  }

  Future<void> _initializeMap() async {
    await _requestLocationPermission();
    _startLocationUpdates();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required for map functionality'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _updateMarkers();
        _sendLocationToBackend(position);
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _startLocationUpdates() {
    // Update location every 30 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentPosition != null) {
        _sendLocationToBackend(_currentPosition!);
      }
      // Also refresh current location
      _getCurrentLocation();
    });
  }

  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  Future<void> _sendLocationToBackend(Position position) async {
    if (_isLocationUpdating) return;
    
    try {
      _isLocationUpdating = true;
      final authState = ref.read(riderAuthProvider);
      final driverProfileId = authState.user?.driverProfileId;
      
      if (driverProfileId != null) {
        await ApiService.updateDriverLocation(
          driverProfileId,
          position.latitude,
          position.longitude,
        );
        print('✅ Location update sent: $driverProfileId at ${position.latitude}, ${position.longitude}');
        
        // If we have an active order, fetch live tracking data
        if (widget.orderId != null) {
          _fetchLiveTrackingData();
        }
      }
    } catch (e) {
      print('❌ Error updating location: $e');
    } finally {
      _isLocationUpdating = false;
    }
  }

  /// Fetch live tracking data for the current order
  Future<void> _fetchLiveTrackingData() async {
    if (widget.orderId == null) return;
    
    try {
      final trackingData = await ApiService.getLiveOrderTracking(widget.orderId!);
      if (trackingData != null && mounted) {
        print('📍 Live tracking data received: $trackingData');
        
        // Update markers with live driver location if available
        if (trackingData['driver_location'] != null) {
          final driverLoc = trackingData['driver_location'];
          final driverLat = driverLoc['latitude'] as double?;
          final driverLng = driverLoc['longitude'] as double?;
          
          if (driverLat != null && driverLng != null) {
            // Update current position with live driver location
            setState(() {
              _currentPosition = Position(
                latitude: driverLat,
                longitude: driverLng,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                altitudeAccuracy: 0,
                heading: 0,
                headingAccuracy: 0,
                speed: 0,
                speedAccuracy: 0,
              );
            });
            _updateMarkers();
            print('🚗 Updated driver position from live tracking: $driverLat, $driverLng');
          }
        }
        
        // Update ETA if available
        if (trackingData['eta'] != null) {
          print('⏱️ ETA: ${trackingData['eta']} minutes');
        }
      }
    } catch (e) {
      print('❌ Error fetching live tracking data: $e');
    }
  }

  void _updateMarkers() {
    final markers = <Marker>{};
    
    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Add order markers if viewing a specific order
    if (widget.orderId != null) {
      final ordersState = ref.read(riderOrdersProvider);
      final order = ordersState.availableOrders.cast<RiderOrder?>().firstWhere(
        (order) => order?.id == widget.orderId,
        orElse: () => null,
      );
      
      if (order != null) {
        // Add pickup marker (Green)
        markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(order.pickupLat, order.pickupLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: 'Pickup: ${order.pickupAddress}'),
          ),
        );
        
        // Add dropoff marker (Red)
        markers.add(
          Marker(
            markerId: const MarkerId('dropoff'),
            position: LatLng(order.dropoffLat, order.dropoffLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: 'Dropoff: ${order.dropoffAddress}'),
          ),
        );

        // Fetch route if we have current location
        if (_currentPosition != null && !_isLoadingRoute) {
          _fetchRouteToOrder(order);
        }
      }
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  Future<void> _fetchRouteToOrder(RiderOrder order) async {
    if (_currentPosition == null || _isLoadingRoute) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      print('🗺️ Fetching route for order ${order.id}');
      
      // Determine the destination based on order status
      LatLng destination;
      String routeType;
      
      // Check order status to determine where to navigate
      if (order.status == 'accepted' || order.status == 'driver_arrived_at_pickup') {
        // Navigate to pickup location
        destination = LatLng(order.pickupLat, order.pickupLng);
        routeType = 'to_pickup';
        print('🎯 Route to pickup location');
      } else if (order.status == 'picked_up' || order.status == 'in_progress') {
        // Navigate to dropoff location
        destination = LatLng(order.dropoffLat, order.dropoffLng);
        routeType = 'to_dropoff';
        print('🎯 Route to dropoff location');
      } else {
        print('⚠️ Order status ${order.status} - no route needed');
        setState(() {
          _isLoadingRoute = false;
        });
        return;
      }

      final origin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      
      // Try to get actual route from backend
      final routeData = await ApiService.getRoute(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destLat: destination.latitude,
        destLng: destination.longitude,
      );
      
      final polylines = <Polyline>{};
      
      if (routeData != null && routeData['polyline'] != null) {
        // Use actual route from backend
        final polylinePoints = routeData['polyline'] as List<dynamic>;
        final points = polylinePoints.map((point) => 
          LatLng(point['lat'] as double, point['lng'] as double)
        ).toList();
        
        polylines.add(
          Polyline(
            polylineId: PolylineId('route_$routeType'),
            points: points,
            color: routeType == 'to_pickup' ? Colors.blue : Colors.orange,
            width: 4,
            patterns: routeType == 'to_pickup' ? [] : [PatternItem.dash(10), PatternItem.gap(5)],
          ),
        );
        print('✅ Using actual route with ${points.length} points');
      } else {
        // Fallback to simple straight line route
        polylines.add(
          Polyline(
            polylineId: PolylineId('route_$routeType'),
            points: [origin, destination],
            color: routeType == 'to_pickup' ? Colors.blue : Colors.orange,
            width: 4,
            patterns: routeType == 'to_pickup' ? [] : [PatternItem.dash(10), PatternItem.gap(5)],
          ),
        );
        print('⚠️ Using fallback straight line route');
      }

      // If going to dropoff, also show pickup to dropoff route
      if (routeType == 'to_dropoff') {
        final pickupLocation = LatLng(order.pickupLat, order.pickupLng);
        polylines.add(
          Polyline(
            polylineId: const PolylineId('pickup_to_dropoff'),
            points: [pickupLocation, destination],
            color: Colors.grey,
            width: 2,
            patterns: [PatternItem.dot, PatternItem.gap(5)],
          ),
        );
      }

      if (mounted) {
        setState(() {
          _polylines = polylines;
          _isLoadingRoute = false;
        });
        
        // Fit camera to show the route
        _fitBoundsToRoute();
      }

      print('✅ Route created: $routeType');
      
    } catch (e) {
      print('❌ Error fetching route: $e');
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _fitBoundsToRoute() async {
    if (_markers.isEmpty) return;

    try {
      final GoogleMapController controller = await _controller.future;
      final bounds = _calculateBounds();
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    } catch (e) {
      print('❌ Error fitting bounds: $e');
    }
  }

  void _fitBounds() {
    if (!_mapReady || _mapController == null || _markers.isEmpty) return;
    
    try {
      final bounds = _calculateBounds();
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    } catch (_) {}
  }

  LatLngBounds _calculateBounds() {
    final positions = _markers.map((marker) => marker.position).toList();
    
    if (positions.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(12.8797, 121.7740),
        northeast: const LatLng(12.8797, 121.7740),
      );
    }
    
    double minLat = positions[0].latitude;
    double maxLat = positions[0].latitude;
    double minLng = positions[0].longitude;
    double maxLng = positions[0].longitude;
    
    for (final position in positions) {
      minLat = min(minLat, position.latitude);
      maxLat = max(maxLat, position.latitude);
      minLng = min(minLng, position.longitude);
      maxLng = max(maxLng, position.longitude);
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _openNavigation(double lat, double lng, String label) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open navigation to $label')),
      );
    }
  }

  String _getRouteTitle(RiderOrder order) {
    if (order.status == 'accepted' || order.status == 'driver_arrived_at_pickup') {
      return 'Route to Pickup Location';
    } else if (order.status == 'picked_up' || order.status == 'in_progress') {
      return 'Route to Dropoff Location';
    }
    return 'Route Information';
  }

  LatLng _getNavigationDestination(RiderOrder order) {
    if (order.status == 'accepted' || order.status == 'driver_arrived_at_pickup') {
      return LatLng(order.pickupLat, order.pickupLng);
    } else {
      return LatLng(order.dropoffLat, order.dropoffLng);
    }
  }

  String _getNavigationLabel(RiderOrder order) {
    if (order.status == 'accepted' || order.status == 'driver_arrived_at_pickup') {
      return 'Pickup';
    } else {
      return 'Dropoff';
    }
  }

  Future<void> _refreshRoute(RiderOrder order) async {
    if (_currentPosition != null) {
      setState(() {
        _polylines.clear();
      });
      await _fetchRouteToOrder(order);
    }
  }

  Widget _buildBottomSheet() {
    final ordersState = ref.read(riderOrdersProvider);
    final currentOrder = widget.orderId != null
        ? ordersState.availableOrders.cast<RiderOrder?>().firstWhere(
            (order) => order?.id == widget.orderId,
            orElse: () => null,
          )
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.2, // Even smaller initial size
      minChildSize: 0.1, // Very small minimum
      maxChildSize: 0.7, // Allow larger expansion
      snap: true, // Enable snapping
      snapSizes: const [0.1, 0.2, 0.5, 0.7], // More snap positions
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing(context, 8)),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentOrder != null) ...[
                          Text(
                            'Order #${currentOrder.id}',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 18),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5F2D82),
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                          
                          // Route Information
                          if (_polylines.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.navigation,
                                    color: Colors.blue.shade700,
                                    size: ResponsiveUtils.fontSize(context, 20),
                                  ),
                                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getRouteTitle(currentOrder),
                                          style: TextStyle(
                                            fontFamily: 'TT Fors',
                                            fontSize: ResponsiveUtils.fontSize(context, 14),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                        Text(
                                          'Route displayed on map',
                                          style: TextStyle(
                                            fontFamily: 'TT Fors',
                                            fontSize: ResponsiveUtils.fontSize(context, 12),
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_isLoadingRoute)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                          ],
                          
                          // Navigation Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _openNavigation(
                                    _getNavigationDestination(currentOrder).latitude,
                                    _getNavigationDestination(currentOrder).longitude,
                                    _getNavigationLabel(currentOrder),
                                  ),
                                  icon: const Icon(Icons.navigation, size: 18),
                                  label: Text(
                                    'Navigate to ${_getNavigationLabel(currentOrder)}',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: ResponsiveUtils.fontSize(context, 12),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5F2D82),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: ResponsiveUtils.spacing(context, 12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                              ElevatedButton.icon(
                                onPressed: () => _refreshRoute(currentOrder),
                                icon: _isLoadingRoute 
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.refresh, size: 18),
                                label: Text(
                                  'Refresh',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: ResponsiveUtils.fontSize(context, 12),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveUtils.spacing(context, 16),
                                    vertical: ResponsiveUtils.spacing(context, 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                          
                          // Pickup Section
                          _buildLocationCard(
                            icon: Icons.location_on,
                            title: 'Pickup',
                            address: currentOrder.pickupAddress,
                            onNavigate: () => _openNavigation(
                              currentOrder.pickupLat,
                              currentOrder.pickupLng,
                              'Pickup',
                            ),
                          ),
                          
                          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                          
                          // Dropoff Section
                          _buildLocationCard(
                            icon: Icons.flag,
                            title: 'Dropoff',
                            address: currentOrder.dropoffAddress,
                            onNavigate: () => _openNavigation(
                              currentOrder.dropoffLat,
                              currentOrder.dropoffLng,
                              'Dropoff',
                            ),
                          ),
                          
                          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                          
                          // Order Details
                          Container(
                            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Details',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: ResponsiveUtils.fontSize(context, 14),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF5F2D82),
                                  ),
                                ),
                                SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Estimated Fare',
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        fontSize: ResponsiveUtils.fontSize(context, 12),
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      '₱${currentOrder.estimatedFare.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        fontSize: ResponsiveUtils.fontSize(context, 14),
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF5F2D82),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Distance',
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        fontSize: ResponsiveUtils.fontSize(context, 12),
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      '${(currentOrder.estimatedDistanceM / 1000).toStringAsFixed(1)} km',
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        fontSize: ResponsiveUtils.fontSize(context, 14),
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF5F2D82),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // No specific order - show general info
                          Text(
                            'Map View',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 18),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5F2D82),
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                          Text(
                            'Your current location is shown on the map.',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                          
                          // Duty Status
                          Consumer(
                            builder: (context, ref, child) {
                              final isOnDuty = ref.watch(riderDutyProvider);
                              return Container(
                                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                                decoration: BoxDecoration(
                                  color: isOnDuty ? Colors.green.shade50 : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isOnDuty ? Colors.green.shade200 : Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isOnDuty ? Icons.check_circle : Icons.pause_circle,
                                      color: isOnDuty ? Colors.green : Colors.orange,
                                    ),
                                    SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                                    Expanded(
                                      child: Text(
                                        isOnDuty
                                            ? 'You are ON DUTY and receiving orders'
                                            : 'You are OFF DUTY - turn on to receive orders',
                                        style: TextStyle(
                                          fontFamily: 'TT Fors',
                                          fontSize: ResponsiveUtils.fontSize(context, 12),
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required String title,
    required String address,
    required VoidCallback onNavigate,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF5F2D82),
            size: ResponsiveUtils.fontSize(context, 20),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5F2D82),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  address,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
          ElevatedButton(
            onPressed: onNavigate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.spacing(context, 12),
                vertical: ResponsiveUtils.spacing(context, 8),
              ),
            ),
            child: Text(
              'Navigate',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12),
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.orderId != null ? 'Order Navigation' : 'Map View - Interactive',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5F2D82),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5F2D82)),
          onPressed: () {
            print('🔙 Back button pressed');
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          // ACTUAL GOOGLE MAPS - FIXED!
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(8.4542, 124.6319), // Cagayan de Oro default
              zoom: 14,
            ),
            
            // CRITICAL: Enable ALL interactive gestures for zoom and pan
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            
            // Disable built-in controls to use custom ones
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            
            // Enable location features
            myLocationEnabled: true,
            
            // Add markers and polylines
            markers: _markers,
            polylines: _polylines,
            
            onMapCreated: (controller) async {
              if (mounted) {
                _mapController = controller;
                _mapReady = true;
                
                // Complete the completer
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
                
                _updateMarkers();
                
                // Fit bounds after a short delay to ensure markers are loaded
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_markers.isNotEmpty && mounted) {
                      _fitBounds();
                    }
                  });
                });
                
                print('🗺️ REAL Google Maps created and ready with ${_markers.length} markers');
                print('🔑 Using Google Maps API Key: AIzaSyA0s1a7phLN0iaD6-MjnwqfpJFhYhmyNjU');
                print('📍 Current position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
                
                // Try to set a specific style to ensure map loads
                try {
                  await controller.setMapStyle(null); // Reset to default style
                  print('✅ Map style set successfully');
                } catch (e) {
                  print('⚠️ Could not set map style: $e');
                }
              }
            },
            
            onTap: (LatLng position) {
              print('🗺️ Google Maps tapped at: ${position.latitude}, ${position.longitude}');
            },
            
            onCameraMove: (CameraPosition position) {
              print('📷 Google Maps camera moved - Zoom: ${position.zoom.toStringAsFixed(2)}');
            },
            
            onCameraIdle: () {
              print('📷 Google Maps camera idle');
            },
          ),
          
          // Custom Zoom Controls - positioned to NOT overlap map interaction area
          Positioned(
            top: 100,
            right: 20,
            child: MapZoomControls(
              mapController: _mapController,
              onCenterMap: () {
                if (_currentPosition != null && _mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      15,
                    ),
                  );
                  print('🎯 Map centered on current location');
                }
              },
            ),
          ),
          
          // Bottom sheet with order details
          if (widget.orderId != null) _buildBottomSheet(),
        ],
      ),
    );
  }
}