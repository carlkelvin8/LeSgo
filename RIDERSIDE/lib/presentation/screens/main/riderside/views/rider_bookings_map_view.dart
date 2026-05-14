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
import '../../../../provider/auth/rider_auth_provider.dart';
import '../../../../widgets/main/riderside/map/map_zoom_controls.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../domain/entities/rider_booking.dart';
import '../rider_booking_detail_screen.dart';

/// Enhanced Bookings View with integrated Waze-style map and ongoing orders
class RiderBookingsMapView extends ConsumerStatefulWidget {
  const RiderBookingsMapView({super.key});

  @override
  ConsumerState<RiderBookingsMapView> createState() => _RiderBookingsMapViewState();
}

class _RiderBookingsMapViewState extends ConsumerState<RiderBookingsMapView> {
  GoogleMapController? _mapController;
  bool _mapReady = false;
  Position? _currentPosition;
  bool _isLocationUpdating = false;
  Timer? _locationUpdateTimer;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _showOrdersList = true;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required for map functionality'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _updateMarkers();
        _sendLocationToBackend(position);
        _centerMapOnCurrentLocation();
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _centerMapOnCurrentLocation() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        ),
      );
    }
  }

  void _startLocationUpdates() {
    // Update location every 30 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
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
        print('📍 Location updated: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      print('❌ Error updating location: $e');
    } finally {
      _isLocationUpdating = false;
    }
  }

  void _updateMarkers() {
    final markers = <Marker>{};
    final ordersState = ref.read(riderOrdersProvider);
    
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

    // Add active order markers
    if (ordersState.activeOrder != null) {
      final order = ordersState.activeOrder!;
      
      // Pickup marker
      markers.add(
        Marker(
          markerId: MarkerId('pickup_${order.id}'),
          position: LatLng(order.pickupLat, order.pickupLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: order.pickupAddress,
          ),
        ),
      );
      
      // Dropoff marker
      markers.add(
        Marker(
          markerId: MarkerId('dropoff_${order.id}'),
          position: LatLng(order.dropoffLat, order.dropoffLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Dropoff',
            snippet: order.dropoffAddress,
          ),
        ),
      );
    }

    // Add available orders markers (first 5)
    for (var i = 0; i < ordersState.availableOrders.length && i < 5; i++) {
      final order = ordersState.availableOrders[i];
      markers.add(
        Marker(
          markerId: MarkerId('available_${order.id}'),
          position: LatLng(order.pickupLat, order.pickupLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: 'Order #${order.id}',
            snippet: '₱${order.displayEarnings.toStringAsFixed(0)} • ${order.distanceKm.toStringAsFixed(1)}km',
          ),
        ),
      );
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
        southwest: const LatLng(8.4, 124.6), // Cagayan de Oro area
        northeast: const LatLng(8.5, 124.7),
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
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open navigation to $label')),
        );
      }
    }
  }

  Widget _buildMapView() {
    print('🗺️ Building map view with position: $_currentPosition');
    print('🔑 Google Maps API Key: AIzaSyA0s1a7phLN0iaD6-MjnwqfpJFhYhmyNjU');
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 2), // Debug border
      ),
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: _currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : const LatLng(8.4542, 124.6319), // Cagayan de Oro default
          zoom: 14,
        ),
        
        // CRITICAL: Enable ALL interactive gestures
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
        
        onMapCreated: (controller) {
          if (mounted) {
            _mapController = controller;
            _mapReady = true;
            _updateMarkers();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_markers.isNotEmpty) {
                _fitBounds();
              }
            });
            print('🗺️ Bookings Map created and ready');
            print('🔑 Google Maps API Key: AIzaSyA0s1a7phLN0iaD6-MjnwqfpJFhYhmyNjU');
            print('📍 Initial position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
          }
        },
        
        onTap: (LatLng position) {
          print('🗺️ Bookings Map tapped at: ${position.latitude}, ${position.longitude}');
        },
        
        onCameraMove: (CameraPosition position) {
          print('📷 Bookings Map camera moved - Zoom: ${position.zoom.toStringAsFixed(2)}');
        },
      ),
    );
  }

  Widget _buildOrdersList() {
    final ordersState = ref.watch(riderOrdersProvider);
    final isOnDuty = ref.watch(riderDutyProvider);

    if (!isOnDuty) {
      return Container(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pause_circle_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 12.0),
              Text(
                'You are OFF DUTY',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 4.0),
              Text(
                'Turn ON DUTY to receive bookings',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 14.0,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Active Order Section
          if (ordersState.activeOrder != null) ...[
            _buildActiveOrderCard(ordersState.activeOrder!),
            Divider(height: 1, color: Colors.grey.shade200),
          ],

          // Available Orders Section
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Orders',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5F2D82),
                  ),
                ),
                if (ordersState.isRefreshing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF5F2D82),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Available Orders List
          if (ordersState.availableOrders.isEmpty)
            Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No available orders at the moment',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 14.0,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: 16.0,
              ),
              itemCount: min(ordersState.availableOrders.length, 3),
              separatorBuilder: (context, index) => SizedBox(
                height: 12.0,
              ),
              itemBuilder: (context, index) {
                final order = ordersState.availableOrders[index];
                return _buildAvailableOrderCard(order);
              },
            ),

          SizedBox(height: 16.0),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(RiderOrder order) {
    // Convert RiderOrder to RiderBooking for detail screen
    final booking = RiderBooking(
      id: order.id.toString(),
      restaurantName: order.serviceName,
      address: order.dropoffAddress,
      pickupAddress: order.pickupAddress,
      deliveryAddress: order.dropoffAddress,
      distance: '${order.distanceKm.toStringAsFixed(1)} km',
      estimatedTime: _calculateEstimatedTime(order.distanceKm),
      earnings: 'Total: PHP ${order.displayTotalAmount.toStringAsFixed(2)} | Your Earnings: PHP ${order.driverEarnings.toStringAsFixed(2)}',
      paymentMethod: order.paymentMethod.toUpperCase(),
      items: order.parsedItems,
      pickupLat: order.pickupLat,
      pickupLng: order.pickupLng,
      dropoffLat: order.dropoffLat,
      dropoffLng: order.dropoffLng,
      billingAmount: 'PHP ${order.displayTotalAmount.toStringAsFixed(2)}',
      deliveryFee: 'PHP ${order.estimatedFare.toStringAsFixed(2)}',
      billingMethod: order.paymentMethod.toUpperCase(),
      currentStatus: _mapApiStatusToBookingStatus(order.status, order.serviceId),
    );
    
    return GestureDetector(
      onTap: () {
        // Navigate to booking detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RiderBookingDetailScreen(
              booking: booking,
              currentApiStatus: order.status, // Pass the actual API status
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border(
            left: BorderSide(
              color: Colors.green,
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                Text(
                  'Order #${order.id}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5F2D82),
                  ),
                ),
                const Spacer(),
                Text(
                  '₱${order.displayEarnings.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.0),
            
            // Pickup
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 20,
                  color: Colors.green,
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    order.pickupAddress,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 13.0,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.navigation, size: 20, color: const Color(0xFF5F2D82)),
                  onPressed: () => _openNavigation(
                    order.pickupLat,
                    order.pickupLng,
                    'Pickup',
                  ),
                ),
              ],
            ),
            
            // Dropoff
            Row(
              children: [
                Icon(
                  Icons.flag,
                  size: 20,
                  color: Colors.red,
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    order.dropoffAddress,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 13.0,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.navigation, size: 20, color: const Color(0xFF5F2D82)),
                  onPressed: () => _openNavigation(
                    order.dropoffLat,
                    order.dropoffLng,
                    'Dropoff',
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8.0),
            
            // View Details Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RiderBookingDetailScreen(
                        booking: booking,
                        currentApiStatus: order.status, // Pass the actual API status
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.visibility, size: 18),
                label: Text('View Details & Track'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5F2D82),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateEstimatedTime(double distanceKm) {
    // Average speed in city: 30 km/h
    final hours = distanceKm / 30;
    final minutes = (hours * 60).round();
    
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hrs = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hrs}h ${mins}min';
    }
  }

  // Map API status to BookingStatus enum
  BookingStatus _mapApiStatusToBookingStatus(String apiStatus, int serviceId) {
    // For LesRide (serviceId: 2)
    if (serviceId == 2) {
      switch (apiStatus.toLowerCase()) {
        case 'accepted':
          return BookingStatus.onTheWay;
        case 'picked_up':
          return BookingStatus.onTheWayGoing;
        case 'completed':
          return BookingStatus.complete;
        default:
          return BookingStatus.onTheWay;
      }
    }
    
    // For LesEat (serviceId: 3)
    if (serviceId == 3) {
      switch (apiStatus.toLowerCase()) {
        case 'pending':
          return BookingStatus.pending;
        case 'accepted':
          return BookingStatus.cooking;
        case 'picked_up':
          return BookingStatus.forPickUp;
        case 'completed':
          return BookingStatus.delivered;
        default:
          return BookingStatus.pending;
      }
    }
    
    // For LesBuy (serviceId: 4)
    if (serviceId == 4) {
      switch (apiStatus.toLowerCase()) {
        case 'pending':
          return BookingStatus.pending;
        case 'accepted':
          return BookingStatus.toBuy;
        case 'picked_up':
          return BookingStatus.forDelivery;
        case 'completed':
          return BookingStatus.delivered;
        default:
          return BookingStatus.pending;
      }
    }
    
    // Default
    return BookingStatus.pending;
  }

  Widget _buildAvailableOrderCard(RiderOrder order) {
    final ordersState = ref.watch(riderOrdersProvider);
    final isAccepting = ordersState.action == RiderOrderAction.accepting &&
        ordersState.actionOrderId == order.id;

    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5F2D82).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.serviceName,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5F2D82),
                  ),
                ),
              ),
              SizedBox(width: 8.0),
              Text(
                'Order #${order.id}',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Text(
                '₱${order.displayEarnings.toStringAsFixed(0)}',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5F2D82),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.0),
          
          // Distance and payment
          Row(
            children: [
              Icon(Icons.straighten, size: 14, color: Colors.grey.shade600),
              SizedBox(width: 4.0),
              Text(
                '${order.distanceKm.toStringAsFixed(1)} km',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 12.0,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(width: 12.0),
              Icon(Icons.payment, size: 14, color: Colors.grey.shade600),
              SizedBox(width: 4.0),
              Text(
                order.paymentMethod.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 12.0,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.0),
          
          // Pickup address
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.green),
              SizedBox(width: 4.0),
              Expanded(
                child: Text(
                  order.pickupAddress,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12.0,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.0),
          
          // Dropoff address
          Row(
            children: [
              Icon(Icons.flag, size: 16, color: Colors.red),
              SizedBox(width: 4.0),
              Expanded(
                child: Text(
                  order.dropoffAddress,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12.0,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.0),
          
          // Accept button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isAccepting
                  ? null
                  : () async {
                      final success = await ref
                          .read(riderOrdersProvider.notifier)
                          .acceptOrder(order.id);
                      
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Order #${order.id} accepted!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _updateMarkers();
                        _fitBounds();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: 12.0,
                ),
              ),
              child: isAccepting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Accept Order',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to orders changes and update markers
    ref.listen<RiderOrdersState>(riderOrdersProvider, (previous, next) {
      _updateMarkers();
    });

    final ordersState = ref.watch(riderOrdersProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Map View
          _buildMapView(),
          
          // Top Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Column(
              children: [
                // Zoom Controls
                MapZoomControls(
                  mapController: _mapController,
                  onCenterMap: _centerMapOnCurrentLocation,
                ),
                SizedBox(height: 12),
                
                // Refresh button
                Container(
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
                      onTap: () {
                        ref.read(riderOrdersProvider.notifier).loadOrders();
                      },
                      child: ordersState.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF5F2D82),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.refresh,
                              color: Color(0xFF5F2D82),
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Orders List
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DraggableScrollableSheet(
              initialChildSize: 0.35,
              minChildSize: 0.2,
              maxChildSize: 0.7,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: _buildOrdersList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

