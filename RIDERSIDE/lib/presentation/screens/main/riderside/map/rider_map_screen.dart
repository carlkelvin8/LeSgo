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
// import '../../../../core/services/api_service.dart'; // TODO: Implement API service
import '../../../../../core/utils/responsive_utils.dart';

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

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    try {
      _mapController?.dispose();
    } catch (_) {}
    _mapController = null;
    super.dispose();
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
        // TODO: Implement API service for location updates
        // await ApiService.updateDriverLocation(
        //   driverProfileId,
        //   position.latitude,
        //   position.longitude,
        // );
        print('Location update: $driverProfileId at ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      print('Error updating location: $e');
    } finally {
      _isLocationUpdating = false;
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
        // Add pickup marker
        markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(order.pickupLat, order.pickupLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: 'Pickup: ${order.pickupAddress}'),
          ),
        );
        
        // Add dropoff marker
        markers.add(
          Marker(
            markerId: const MarkerId('dropoff'),
            position: LatLng(order.dropoffLat, order.dropoffLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: 'Dropoff: ${order.dropoffAddress}'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
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

  Widget _buildBottomSheet() {
    final ordersState = ref.read(riderOrdersProvider);
    final currentOrder = widget.orderId != null
        ? ordersState.availableOrders.cast<RiderOrder?>().firstWhere(
            (order) => order?.id == widget.orderId,
            orElse: () => null,
          )
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.6,
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
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  
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
          widget.orderId != null ? 'Order Navigation' : 'Map View',
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
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Color(0xFF5F2D82)),
            onPressed: () {
              if (_currentPosition != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(12.8797, 121.7740), // Philippines center
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              if (mounted) {
                _mapController = controller;
                _mapReady = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fitBounds();
                });
              }
            },
          ),
          
          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSheet(),
          ),
        ],
      ),
    );
  }
}