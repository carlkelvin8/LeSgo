import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/data_source/tracking_remote_datasource.dart';
import '../../../data/data_source/dto/tracking/tracking_dto.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/utils/notification_helper.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class LiveTrackingState {
  final TrackingDto? tracking;
  final LatLng? driverLocation;
  final LatLng? pickupLocation;
  final LatLng? dropoffLocation;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final bool isLoading;
  final bool isLoadingRoute;
  final String? error;
  final String? eta;
  final String? distance;
  final String orderStatus;
  final DriverInfo? driverInfo;
  final bool isTracking;
  final double? driverHeading;

  LiveTrackingState({
    this.tracking,
    this.driverLocation,
    this.pickupLocation,
    this.dropoffLocation,
    this.markers = const {},
    this.polylines = const {},
    this.isLoading = false,
    this.isLoadingRoute = false,
    this.error,
    this.eta,
    this.distance,
    this.orderStatus = 'pending',
    this.driverInfo,
    this.isTracking = false,
    this.driverHeading = 0.0,
  });

  LiveTrackingState copyWith({
    TrackingDto? tracking,
    LatLng? driverLocation,
    LatLng? pickupLocation,
    LatLng? dropoffLocation,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    bool? isLoading,
    bool? isLoadingRoute,
    String? error,
    String? eta,
    String? distance,
    String? orderStatus,
    DriverInfo? driverInfo,
    bool? isTracking,
    double? driverHeading,
  }) {
    return LiveTrackingState(
      tracking: tracking ?? this.tracking,
      driverLocation: driverLocation ?? this.driverLocation,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      isLoading: isLoading ?? this.isLoading,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      error: error,
      eta: eta ?? this.eta,
      distance: distance ?? this.distance,
      orderStatus: orderStatus ?? this.orderStatus,
      driverInfo: driverInfo ?? this.driverInfo,
      isTracking: isTracking ?? this.isTracking,
      driverHeading: driverHeading ?? this.driverHeading,
    );
  }

  bool get hasDriverLocation => driverLocation != null;
  bool get hasRoute => polylines.isNotEmpty;
  bool get isOrderActive => 
      orderStatus != 'completed' && 
      orderStatus != 'cancelled' &&
      orderStatus != 'failed';
}

class DriverInfo {
  final String name;
  final String? phone;
  final String? vehicleNumber;
  final String? vehicleType;
  final String? photoUrl;
  final double? rating;

  DriverInfo({
    required this.name,
    this.phone,
    this.vehicleNumber,
    this.vehicleType,
    this.photoUrl,
    this.rating,
  });
}

class LiveTrackingNotifier extends StateNotifier<LiveTrackingState> {
  Timer? _locationTimer;
  Timer? _etaTimer;
  final int orderId;
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropoffIcon;
  StreamSubscription? _orderEventSubscription;
  final WebSocketService _webSocketService = getIt<WebSocketService>();
  bool _useWebSocket = true; // Flag to enable/disable WebSocket
  BuildContext? _context;

  LiveTrackingNotifier(this.orderId) : super(LiveTrackingState()) {
    _initializeIcons();
    startTracking();
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> _initializeIcons() async {
    // Load custom marker icons
    _driverIcon = await _createCustomMarkerIcon(
      Colors.blue,
      Icons.directions_car,
    );
    _pickupIcon = await _createCustomMarkerIcon(
      Colors.green,
      Icons.location_on,
    );
    _dropoffIcon = await _createCustomMarkerIcon(
      Colors.red,
      Icons.location_on,
    );
  }

  Future<BitmapDescriptor> _createCustomMarkerIcon(
    Color color,
    IconData icon,
  ) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;

    // Draw circle
    canvas.drawCircle(const Offset(50, 50), 40, paint);

    // Draw icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 40,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(30, 30));

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(100, 100);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void startTracking() {
    if (state.isTracking) return;

    state = state.copyWith(isTracking: true);
    
    // Initial load
    loadTracking();

    // Try to use WebSocket for real-time updates
    if (_useWebSocket) {
      _setupWebSocketTracking();
    }

    // Fallback: Poll location every 10 seconds (less frequent since WebSocket is primary)
    _locationTimer = Timer.periodic(
      Duration(seconds: _useWebSocket ? 10 : 5),
      (_) {
        if (state.isOrderActive) {
          loadDriverLocation();
        } else {
          stopTracking();
        }
      },
    );

    // Poll ETA every 30 seconds (less frequent since WebSocket provides updates)
    _etaTimer = Timer.periodic(
      Duration(seconds: _useWebSocket ? 30 : 15),
      (_) {
        if (state.isOrderActive) {
          loadEta();
        }
      },
    );
  }

  /// Set up WebSocket tracking for real-time updates
  Future<void> _setupWebSocketTracking() async {
    try {
      // Initialize WebSocket if not already done
      await _webSocketService.initialize();

      // Subscribe to order channel
      // TODO: Get auth token from secure storage
      await _webSocketService.subscribeToOrder(orderId, '');

      // Listen to order events
      _orderEventSubscription = _webSocketService
          .getOrderEventStream(orderId)
          .listen(_handleOrderEvent);

      debugPrint('✅ WebSocket tracking enabled for order $orderId');
    } catch (e) {
      debugPrint('⚠️ WebSocket setup failed, using polling: $e');
      _useWebSocket = false;
    }
  }

  /// Handle WebSocket order events
  void _handleOrderEvent(dynamic eventData) {
    try {
      final event = eventData['event'] as String;
      final data = eventData['data'];

      debugPrint('📦 Order event received: $event');

      if (event == 'driver.location.updated') {
        _handleDriverLocationUpdate(data);
      } else if (event == 'order.status.updated') {
        _handleOrderStatusUpdate(data);
      }
    } catch (e) {
      debugPrint('❌ Failed to handle order event: $e');
    }
  }

  /// Handle driver location update from WebSocket
  void _handleDriverLocationUpdate(dynamic data) {
    try {
      if (data is String) {
        data = jsonDecode(data);
      }

      final location = data['location'];
      if (location != null) {
        final lat = (location['latitude'] as num).toDouble();
        final lng = (location['longitude'] as num).toDouble();

        final newLocation = LatLng(lat, lng);

        // Update state with new location
        state = state.copyWith(
          driverLocation: newLocation,
        );

        _updateMarkers();
        
        // Reload route with new driver location
        loadRoute();

        debugPrint('📍 Driver location updated via WebSocket: $lat, $lng');
      }
    } catch (e) {
      debugPrint('❌ Failed to handle driver location update: $e');
    }
  }

  /// Handle order status update from WebSocket
  void _handleOrderStatusUpdate(dynamic data) {
    try {
      if (data is String) {
        data = jsonDecode(data);
      }

      final newStatus = data['new_status'] as String?;
      final previousStatus = state.orderStatus;
      
      if (newStatus != null && newStatus != previousStatus) {
        state = state.copyWith(orderStatus: newStatus);
        
        debugPrint('📊 Order status updated via WebSocket: $newStatus');

        // Show appropriate notification based on status change
        if (_context != null && _context!.mounted) {
          _showStatusNotification(newStatus);
        }

        // Stop tracking if order is completed/cancelled
        if (!state.isOrderActive) {
          stopTracking();
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to handle order status update: $e');
    }
  }

  /// Show notification based on order status
  void _showStatusNotification(String status) {
    if (_context == null || !_context!.mounted) return;

    final orderIdStr = orderId.toString();
    final driverName = state.driverInfo?.name;

    switch (status.toLowerCase()) {
      case 'accepted':
        NotificationHelper.showOrderAccepted(
          _context!,
          orderId: orderIdStr,
          driverName: driverName,
        );
        break;
      case 'picked_up':
      case 'pickedup':
        NotificationHelper.showOrderPickedUp(
          _context!,
          orderId: orderIdStr,
          driverName: driverName,
        );
        break;
      case 'in_transit':
      case 'intransit':
      case 'on_the_way':
        NotificationHelper.showOrderInTransit(
          _context!,
          orderId: orderIdStr,
          eta: state.eta,
        );
        break;
      case 'completed':
      case 'delivered':
        NotificationHelper.showOrderDelivered(
          _context!,
          orderId: orderIdStr,
        );
        break;
      case 'cancelled':
        NotificationHelper.showOrderCancelled(
          _context!,
          orderId: orderIdStr,
        );
        break;
    }
  }

  void stopTracking() {
    _locationTimer?.cancel();
    _etaTimer?.cancel();
    _orderEventSubscription?.cancel();
    
    // Unsubscribe from WebSocket
    if (_useWebSocket) {
      _webSocketService.unsubscribeFromOrder(orderId);
    }
    
    state = state.copyWith(isTracking: false);
  }

  Future<void> loadTracking() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dataSource = getIt<TrackingRemoteDataSource>();
      final response = await dataSource.trackOrder(orderId);

      if (response['success'] == true) {
        final trackingData = response['data']['data'] ?? response['data']; // Handle nested data if present

        // Extract real locations with fallback to mock data
        final double pLat = double.tryParse(trackingData['pickup_lat']?.toString() ?? '') ?? 8.4542;
        final double pLng = double.tryParse(trackingData['pickup_lng']?.toString() ?? '') ?? 124.6319;
        final double dLat = double.tryParse(trackingData['dropoff_lat']?.toString() ?? '') ?? 8.4600;
        final double dLng = double.tryParse(trackingData['dropoff_lng']?.toString() ?? '') ?? 124.6400;

        final pickupLoc = LatLng(pLat, pLng);
        final dropoffLoc = LatLng(dLat, dLng);

        // Extract driver info
        DriverInfo? driverInfo;
        final driverProfile = trackingData['driver_profile'];
        if (driverProfile != null) {
          final user = driverProfile['user'];
          driverInfo = DriverInfo(
            name: user?['name'] ?? 'Driver',
            phone: user?['phone'] ?? driverProfile['phone_number'],
            vehicleNumber: driverProfile['plate_number'],
            vehicleType: driverProfile['vehicle_type'],
            photoUrl: user?['avatar'],
            rating: 5.0, // Mock rating for now
          );
        }

        state = state.copyWith(
          pickupLocation: pickupLoc,
          dropoffLocation: dropoffLoc,
          orderStatus: trackingData['status'] ?? 'pending',
          driverInfo: driverInfo,
          isLoading: false,
        );

        // Load driver location and route
        await loadDriverLocation();
        await loadRoute();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load tracking information',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadDriverLocation() async {
    if (!state.isOrderActive) return;

    try {
      final dataSource = getIt<TrackingRemoteDataSource>();
      final response = await dataSource.getEta(orderId);

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        
        final double lat = double.tryParse(data['current_latitude']?.toString() ?? data['currentLatitude']?.toString() ?? '') ?? 8.4542;
        final double lng = double.tryParse(data['current_longitude']?.toString() ?? data['currentLongitude']?.toString() ?? '') ?? 124.6319;
        
        final location = LatLng(lat, lng);
        
        double heading = state.driverHeading ?? 0.0;
        if (state.driverLocation != null && 
            (state.driverLocation!.latitude != lat || state.driverLocation!.longitude != lng)) {
          heading = Geolocator.bearingBetween(
            state.driverLocation!.latitude,
            state.driverLocation!.longitude,
            lat,
            lng,
          );
        }

        state = state.copyWith(
          driverLocation: location,
          driverHeading: heading,
          eta: data['estimatedArrival'] ?? '15 minutes',
        );

        _updateMarkers();
      }
    } catch (e) {
      // Silently fail - don't disrupt tracking
    }
  }

  Future<void> loadEta() async {
    if (!state.isOrderActive) return;

    try {
      final dataSource = getIt<TrackingRemoteDataSource>();
      final response = await dataSource.getEta(orderId);

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        
        // Extract ETA
        String? eta;
        if (data['estimatedArrival'] != null) {
          eta = data['estimatedArrival'] as String;
        } else if (data['estimatedArrivalMinutes'] != null) {
          final minutes = data['estimatedArrivalMinutes'] as num;
          eta = '${minutes.round()} minutes';
        } else if (data['estimated_arrival'] != null) {
          eta = data['estimated_arrival'] as String;
        } else if (data['minutes_remaining'] != null) {
          final minutes = data['minutes_remaining'] as num;
          eta = '${minutes.round()} minutes';
        }
        
        // Extract distance
        String? distance;
        if (data['distanceKm'] != null) {
          final distKm = data['distanceKm'] as num;
          distance = '${distKm.toStringAsFixed(1)} km';
        } else if (data['distance_remaining_m'] != null) {
          final distM = data['distance_remaining_m'] as num;
          distance = '${(distM / 1000).toStringAsFixed(1)} km';
        }
        
        state = state.copyWith(
          eta: eta,
          distance: distance,
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to load ETA: $e');
      // Silently fail - don't disrupt tracking
    }
  }

  Future<void> loadRoute() async {
    if (state.driverLocation == null || state.dropoffLocation == null) return;

    state = state.copyWith(isLoadingRoute: true);

    try {
      final dataSource = getIt<TrackingRemoteDataSource>();
      final response = await dataSource.getRoute(
        state.driverLocation!.latitude,
        state.driverLocation!.longitude,
        state.dropoffLocation!.latitude,
        state.dropoffLocation!.longitude,
      );

      if (response['success'] == true) {
        final data = response['data'];
        
        // Parse polyline points from API response
        List<LatLng> polylinePoints = [];
        
        if (data['polyline'] != null && data['polyline'] is List) {
          polylinePoints = (data['polyline'] as List).map((point) {
            return LatLng(
              (point['latitude'] as num).toDouble(),
              (point['longitude'] as num).toDouble(),
            );
          }).toList();
        }

        // If no polyline points, create a simple straight line
        if (polylinePoints.isEmpty) {
          polylinePoints = [
            state.driverLocation!,
            state.dropoffLocation!,
          ];
        }

        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: Colors.blue,
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        );

        // Extract distance and duration
        String? distance;
        String? duration;
        
        if (data['distance'] != null) {
          distance = data['distance']['text'] ?? '${(data['distance']['value'] / 1000).toStringAsFixed(1)} km';
        }
        
        if (data['duration'] != null) {
          duration = data['duration']['text'] ?? '${(data['duration']['value'] / 60).round()} mins';
        }

        state = state.copyWith(
          polylines: {polyline},
          distance: distance,
          eta: duration,
          isLoadingRoute: false,
        );
      } else {
        state = state.copyWith(isLoadingRoute: false);
      }
    } catch (e) {
      debugPrint('❌ Failed to load route: $e');
      state = state.copyWith(isLoadingRoute: false);
    }
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    // Add driver marker
    if (state.driverLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: state.driverLocation!,
        icon: _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        ),
        infoWindow: InfoWindow(
          title: state.driverInfo?.name ?? 'Driver',
          snippet: state.eta != null ? 'ETA: ${state.eta}' : null,
        ),
        rotation: state.driverHeading ?? 0.0,
        anchor: const Offset(0.5, 0.5), // Center the marker for proper rotation
      ));
    }

    // Add pickup marker
    if (state.pickupLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: state.pickupLocation!,
        icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
        infoWindow: const InfoWindow(
          title: 'Pickup Location',
        ),
      ));
    }

    // Add dropoff marker
    if (state.dropoffLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: state.dropoffLocation!,
        icon: _dropoffIcon ?? BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
        infoWindow: const InfoWindow(
          title: 'Dropoff Location',
        ),
      ));
    }

    state = state.copyWith(markers: markers);
  }

  Future<void> refreshTracking() async {
    await loadTracking();
  }

  LatLngBounds? getCameraBounds() {
    if (state.markers.isEmpty) return null;

    double? minLat, maxLat, minLng, maxLng;

    for (final marker in state.markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = minLat == null ? lat : (lat < minLat ? lat : minLat);
      maxLat = maxLat == null ? lat : (lat > maxLat ? lat : maxLat);
      minLng = minLng == null ? lng : (lng < minLng ? lng : minLng);
      maxLng = maxLng == null ? lng : (lng > maxLng ? lng : maxLng);
    }

    if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
      return null;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

final liveTrackingProvider = StateNotifierProvider.family<
    LiveTrackingNotifier, LiveTrackingState, int>((ref, orderId) {
  return LiveTrackingNotifier(orderId);
});
