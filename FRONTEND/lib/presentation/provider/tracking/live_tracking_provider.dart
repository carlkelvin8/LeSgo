import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/data_source/tracking_remote_datasource.dart';
import '../../../data/data_source/dto/tracking/tracking_dto.dart';
import '../../../core/di/injection.dart';
import '../../../core/di/local_storage_service.dart';
import '../../../core/utils/booking_geo_utils.dart';
import '../../../core/utils/driver_display_utils.dart';
import '../../../core/utils/directions_route_service.dart';
import '../../../core/constants/polling_intervals.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/customer_satisfaction_service.dart';
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
  final bool followDriver;
  final LatLng? displayedDriverLocation;

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
    this.followDriver = true,
    this.displayedDriverLocation,
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
    bool? followDriver,
    LatLng? displayedDriverLocation,
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
      followDriver: followDriver ?? this.followDriver,
      displayedDriverLocation:
          displayedDriverLocation ?? this.displayedDriverLocation,
    );
  }

  bool get hasDriverLocation => driverLocation != null;
  bool get hasRoute => polylines.isNotEmpty;
  bool get isOrderActive =>
      orderStatus != 'completed' &&
      orderStatus != 'cancelled' &&
      orderStatus != 'failed';
}

class LiveTrackingNotifier extends StateNotifier<LiveTrackingState> {
  Timer? _etaTimer;
  final int orderId;
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropoffIcon;
  StreamSubscription? _orderEventSubscription;
  final WebSocketService _webSocketService = getIt<WebSocketService>();
  BuildContext? _context;
  List<LatLng> _activeRoutePoints = [];
  static const _routeDeviationMeters = 120.0;
  Timer? _driverAnimTimer;
  static const _driverAnimSteps = 12;

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
    _dropoffIcon = await _createCustomMarkerIcon(Colors.red, Icons.location_on);
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

    loadTracking();
    unawaited(_setupWebSocketTracking());

    _etaTimer = Timer.periodic(PollingIntervals.liveEta, (_) {
      if (state.isOrderActive) {
        loadEta();
      } else {
        stopTracking();
      }
    });
  }

  /// Set up WebSocket tracking for real-time updates
  Future<void> _setupWebSocketTracking() async {
    try {
      // Initialize WebSocket if not already done
      await _webSocketService.initialize();

      // Subscribe to order channel
      final token = getIt<LocalStorageService>().token ?? '';
      await _webSocketService.subscribeToOrder(orderId, token);

      // Listen to order events
      _orderEventSubscription = _webSocketService
          .getOrderEventStream(orderId)
          .listen(_handleOrderEvent);

      debugPrint('✅ Live tracking WebSocket + poll fallback for order $orderId');
    } catch (e) {
      debugPrint('⚠️ Live tracking poller setup failed: $e');
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
        state = state.copyWith(driverLocation: newLocation);
        _animateDriverTo(newLocation);
        _refreshDynamicEta();

        if (_shouldRecalculateRoute(newLocation)) {
          loadRoute();
        }
        loadEta();

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

        debugPrint('📊 Order status updated: $newStatus');
        unawaited(loadTracking());

        // Show appropriate notification based on status change
        if (_context != null && _context!.mounted) {
          _showStatusNotification(newStatus);
        }

        // Stop tracking if order is completed/cancelled
        if (!state.isOrderActive) {
          if (newStatus.toLowerCase() == 'completed') {
            unawaited(
              getIt<CustomerSatisfactionService>().onOrderCompletedFromTracking(),
            );
          }
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
        NotificationHelper.showOrderDelivered(_context!, orderId: orderIdStr);
        break;
      case 'cancelled':
        NotificationHelper.showOrderCancelled(_context!, orderId: orderIdStr);
        break;
    }
  }

  void stopTracking() {
    _etaTimer?.cancel();
    _orderEventSubscription?.cancel();
    _webSocketService.unsubscribeFromOrder(orderId);

    state = state.copyWith(isTracking: false);
  }

  Future<void> loadTracking() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dataSource = getIt<TrackingRemoteDataSource>();
      final response = await dataSource.trackOrder(orderId);

      if (response['success'] == true) {
        final trackingData =
            response['data']['data'] ??
            response['data']; // Handle nested data if present

        // Extract real locations with fallback to mock data
        final double pLat =
            double.tryParse(trackingData['pickup_lat']?.toString() ?? '') ??
            double.tryParse(trackingData['pickup_latitude']?.toString() ?? '') ??
            BookingGeoUtils.defaultLat;
        final double pLng =
            double.tryParse(trackingData['pickup_lng']?.toString() ?? '') ??
            double.tryParse(trackingData['pickup_longitude']?.toString() ?? '') ??
            BookingGeoUtils.defaultLng;
        final double dLat =
            double.tryParse(trackingData['dropoff_lat']?.toString() ?? '') ??
            double.tryParse(trackingData['dropoff_latitude']?.toString() ?? '') ??
            pLat;
        final double dLng =
            double.tryParse(trackingData['dropoff_lng']?.toString() ?? '') ??
            double.tryParse(trackingData['dropoff_longitude']?.toString() ?? '') ??
            pLng;

        final pickupLoc = LatLng(pLat, pLng);
        final dropoffLoc = LatLng(dLat, dLng);

        final driverInfo = DriverInfo.fromDriverProfileMap(
          trackingData['driver_profile'] is Map
              ? Map<String, dynamic>.from(
                  trackingData['driver_profile'] as Map,
                )
              : null,
        );

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
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadDriverLocation() async {
    if (!state.isOrderActive) return;

    try {
      final dataSource = getIt<TrackingRemoteDataSource>();
      LatLng? location;

      try {
        final driverResponse = await dataSource.getDriverLocation(orderId);
        if (driverResponse.success) {
          final lat = driverResponse.data.currentLat;
          final lng = driverResponse.data.currentLng;
          if (lat != null && lng != null) {
            location = LatLng(lat, lng);
          }
        }
      } catch (_) {}

      if (location == null) {
        final etaResponse = await dataSource.getEta(orderId);
        if (etaResponse['success'] == true) {
          final parsed = TrackingRemoteDataSource.parseEtaPayload(
            etaResponse['data'] as Map<String, dynamic>?,
          );
          if (parsed.driverLat != null && parsed.driverLng != null) {
            location = LatLng(parsed.driverLat!, parsed.driverLng!);
          }
          if (parsed.eta != null || parsed.distance != null) {
            state = state.copyWith(
              eta: parsed.eta ?? state.eta,
              distance: parsed.distance ?? state.distance,
            );
          }
        }
      }

      if (location == null) return;

      double heading = state.driverHeading ?? 0.0;
      if (state.driverLocation != null &&
          (state.driverLocation!.latitude != location.latitude ||
              state.driverLocation!.longitude != location.longitude)) {
        heading = Geolocator.bearingBetween(
          state.driverLocation!.latitude,
          state.driverLocation!.longitude,
          location.latitude,
          location.longitude,
        );
      }

      state = state.copyWith(
        driverLocation: location,
        driverHeading: heading,
      );

      if (state.displayedDriverLocation == null) {
        state = state.copyWith(displayedDriverLocation: location);
        _updateMarkers();
      } else {
        _animateDriverTo(location);
      }
      _refreshDynamicEta();
    } catch (e) {
      debugPrint('Failed to load driver location: $e');
    }
  }

  Future<void> loadEta() async {
    if (!state.isOrderActive) return;

    try {
      final dataSource = getIt<TrackingRemoteDataSource>();
      final response = await dataSource.getEta(orderId);

      if (response['success'] == true) {
        final parsed = TrackingRemoteDataSource.parseEtaPayload(
          response['data'] as Map<String, dynamic>?,
        );
        state = state.copyWith(
          eta: parsed.eta ?? state.eta,
          distance: parsed.distance ?? state.distance,
        );
      } else {
        _refreshDynamicEta();
      }
    } catch (e) {
      debugPrint('Failed to load ETA: $e');
      _refreshDynamicEta();
    }
  }

  /// Recompute ETA from driver → dropoff distance (updates every location tick).
  void _refreshDynamicEta() {
    if (!state.isOrderActive) return;
    final computed = _computeEtaFromDriverPosition();
    if (computed != null) {
      state = state.copyWith(eta: computed);
    }
  }

  String? _computeEtaFromDriverPosition() {
    final driver = state.driverLocation;
    final target = state.dropoffLocation ?? state.pickupLocation;
    if (driver == null || target == null) return state.eta;

    final meters = Geolocator.distanceBetween(
      driver.latitude,
      driver.longitude,
      target.latitude,
      target.longitude,
    );

    if (meters < 80) return 'Arriving now / Paparating na';

    final km = meters / 1000;
  final minutes = (km / 35 * 60).ceil().clamp(1, 180);
    return '$minutes min';
  }

  bool _shouldRecalculateRoute(LatLng driver) {
    if (_activeRoutePoints.length < 2) return true;

    var minDistance = double.infinity;
    for (final point in _activeRoutePoints) {
      final d = Geolocator.distanceBetween(
        driver.latitude,
        driver.longitude,
        point.latitude,
        point.longitude,
      );
      if (d < minDistance) minDistance = d;
    }

    return minDistance > _routeDeviationMeters;
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

      List<LatLng> polylinePoints = [];
      String? distance;
      String? duration;

      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map) {
          polylinePoints = _parsePolylinePoints(data);
          distance = _readDistanceText(data);
          duration = _readDurationText(data);
        }
      }

      if (polylinePoints.isEmpty) {
        final directions = await DirectionsRouteService.fetchRoute(
          originLat: state.driverLocation!.latitude,
          originLng: state.driverLocation!.longitude,
          destLat: state.dropoffLocation!.latitude,
          destLng: state.dropoffLocation!.longitude,
        );

        if (directions != null) {
          polylinePoints = directions.points;
          distance ??= directions.distanceText;
          duration ??= directions.durationText;
        }
      }

      if (polylinePoints.isEmpty) {
        state = state.copyWith(isLoadingRoute: false, polylines: const {});
        _activeRoutePoints = [];
        return;
      }

      _activeRoutePoints = polylinePoints;

      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: polylinePoints,
        color: const Color(0xFF1976D2),
        width: 5,
        geodesic: true,
      );

      state = state.copyWith(
        polylines: {polyline},
        distance: distance,
        eta: duration,
        isLoadingRoute: false,
      );
    } catch (e) {
      debugPrint('❌ Failed to load route: $e');
      state = state.copyWith(isLoadingRoute: false, polylines: const {});
    }
  }

  List<LatLng> _parsePolylinePoints(Map<dynamic, dynamic> data) {
    final points = <LatLng>[];

    final encoded = data['encoded_polyline'] ?? data['overview_polyline'];
    if (encoded is String && encoded.isNotEmpty) {
      return DirectionsRouteService.decodePolyline(encoded);
    }

    if (data['polyline'] is String) {
      return DirectionsRouteService.decodePolyline(data['polyline'] as String);
    }

    if (data['polyline'] is List) {
      for (final point in data['polyline'] as List) {
        if (point is Map) {
          final lat = point['latitude'] ?? point['lat'];
          final lng = point['longitude'] ?? point['lng'];
          if (lat != null && lng != null) {
            points.add(
              LatLng(
                (lat as num).toDouble(),
                (lng as num).toDouble(),
              ),
            );
          }
        }
      }
    }

    return points;
  }

  String? _readDistanceText(Map<dynamic, dynamic> data) {
    final distance = data['distance'];
    if (distance is Map) {
      return distance['text']?.toString() ??
          '${((distance['value'] as num? ?? 0) / 1000).toStringAsFixed(1)} km';
    }
    if (distance is num) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return null;
  }

  String? _readDurationText(Map<dynamic, dynamic> data) {
    final duration = data['duration'];
    if (duration is Map) {
      return duration['text']?.toString() ??
          '${((duration['value'] as num? ?? 0) / 60).round()} mins';
    }
    if (duration is num) {
      return '${(duration / 60).round()} mins';
    }
    return null;
  }

  void toggleFollowDriver() {
    state = state.copyWith(followDriver: !state.followDriver);
  }

  String buildShareLocationText() {
    final driver = state.displayedDriverLocation ?? state.driverLocation;
    final pickup = state.pickupLocation;
    final dropoff = state.dropoffLocation;
    final driverName = state.driverInfo?.name ?? 'Driver';
    final lines = <String>[
      'LeSGo live tracking — Order #$orderId',
      if (driver != null)
        'Driver ($driverName): https://maps.google.com/?q=${driver.latitude},${driver.longitude}',
      if (pickup != null)
        'Pickup: https://maps.google.com/?q=${pickup.latitude},${pickup.longitude}',
      if (dropoff != null)
        'Dropoff: https://maps.google.com/?q=${dropoff.latitude},${dropoff.longitude}',
      if (state.eta != null) 'ETA: ${state.eta}',
    ];
    return lines.join('\n');
  }

  void _animateDriverTo(LatLng target) {
    final from = state.displayedDriverLocation ?? state.driverLocation ?? target;
    if (from.latitude == target.latitude && from.longitude == target.longitude) {
      state = state.copyWith(displayedDriverLocation: target);
      _updateMarkers();
      return;
    }

    _driverAnimTimer?.cancel();
    var step = 0;
    _driverAnimTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      step++;
      final t = (step / _driverAnimSteps).clamp(0.0, 1.0);
      final lat = from.latitude + (target.latitude - from.latitude) * t;
      final lng = from.longitude + (target.longitude - from.longitude) * t;
      state = state.copyWith(displayedDriverLocation: LatLng(lat, lng));
      _updateMarkers();

      if (step >= _driverAnimSteps) {
        timer.cancel();
        state = state.copyWith(displayedDriverLocation: target);
        _updateMarkers();
      }
    });
  }

  void _updateMarkers() {
    final markers = <Marker>{};
    final driverPos = state.displayedDriverLocation ?? state.driverLocation;

    if (driverPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driverPos,
          icon:
              _driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: state.driverInfo?.name ?? 'Driver',
            snippet: state.eta != null ? 'ETA: ${state.eta}' : null,
          ),
          rotation: state.driverHeading ?? 0.0,
          anchor: const Offset(
            0.5,
            0.5,
          ), // Center the marker for proper rotation
        ),
      );
    }

    // Add pickup marker
    if (state.pickupLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: state.pickupLocation!,
          icon:
              _pickupIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }

    // Add dropoff marker
    if (state.dropoffLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: state.dropoffLocation!,
          icon:
              _dropoffIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Dropoff Location'),
        ),
      );
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
    _driverAnimTimer?.cancel();
    stopTracking();
    super.dispose();
  }
}

final liveTrackingProvider =
    StateNotifierProvider.family<LiveTrackingNotifier, LiveTrackingState, int>((
      ref,
      orderId,
    ) {
      return LiveTrackingNotifier(orderId);
    });
