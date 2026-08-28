import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../provider/main/riderside/rider_orders_provider.dart';
import '../../../../provider/main/riderside/rider_duty_provider.dart';
import '../../../../provider/main/riderside/rider_location_provider.dart';
import '../../../../provider/auth/rider_auth_provider.dart';
import '../../../../widgets/main/riderside/map/map_zoom_controls.dart';
import '../../../../../core/config/secrets_config.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../../../core/utils/location_permission_utils.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/rider_booking_mapper.dart';
import '../../../../../core/utils/rider_route_utils.dart';
import '../../../../../core/utils/rider_navigation_launcher.dart';
import '../../../../../core/utils/offline_feedback_utils.dart';
import '../rider_booking_detail_screen.dart';
import '../../../../provider/main/riderside/rider_heatmap_provider.dart';

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
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoadingRoute = false;
  ProviderSubscription<RiderLocationState>? _locationSub;
  ProviderSubscription<RiderOrdersState>? _ordersSub;
  ProviderSubscription<RiderHeatmapState>? _heatmapSub;
  Set<Circle> _heatmapCircles = {};

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _locationSub = ref.listenManual<RiderLocationState>(
        riderLocationProvider,
        (previous, next) {
          if (!mounted) return;
          if (next.latitude == null || next.longitude == null) return;
          if (previous?.latitude == next.latitude &&
              previous?.longitude == next.longitude) {
            return;
          }
          setState(() {
            _currentPosition =
                _positionFromCoords(next.latitude!, next.longitude!);
          });
          _updateMarkers();
          _updateActiveOrderRoute();
        },
      );

      _ordersSub = ref.listenManual<RiderOrdersState>(
        riderOrdersProvider,
        (previous, next) {
          if (!mounted) return;
          final activeOrderId = next.activeOrder?.id;
          final prevActiveId = previous?.activeOrder?.id;
          final prevStatus = previous?.activeOrder?.status;
          final nextStatus = next.activeOrder?.status;
          if (activeOrderId != prevActiveId || prevStatus != nextStatus) {
            RiderRouteUtils.clearRouteCache();
          }
          if (ref.read(riderHeatmapProvider).showHeatmap) {
            ref.read(riderHeatmapProvider.notifier).updateZones(
                  RiderHeatmapNotifier.zonesFromOrders(next.availableOrders),
                );
            _updateHeatmapCircles();
          }
          ref
              .read(riderLocationProvider.notifier)
              .setActiveOrderId(activeOrderId);
          _updateMarkers();
          _updateActiveOrderRoute(force: true);
        },
      );

      _heatmapSub = ref.listenManual<RiderHeatmapState>(
        riderHeatmapProvider,
        (previous, next) {
          if (!mounted) return;
          if (next.showHeatmap) {
            _updateHeatmapCircles();
          } else {
            setState(() => _heatmapCircles = {});
          }
        },
      );

      final activeOrderId = ref.read(riderOrdersProvider).activeOrder?.id;
      final notifier = ref.read(riderLocationProvider.notifier);
      notifier.setActiveOrderId(activeOrderId);
      if (!ref.read(riderLocationProvider).isTracking) {
        notifier.startTracking(orderId: activeOrderId);
      }
    });
  }

  @override
  void dispose() {
    _locationSub?.close();
    _ordersSub?.close();
    _heatmapSub?.close();
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
    } else if (mounted) {
      await showLocationPermissionSnackBar(
        context,
        openSettings: permissionNeedsSettings(status),
      );
    }
  }

  String _formatLastRefreshed(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 10) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
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
        _updateActiveOrderRoute();
        _centerMapOnCurrentLocation();
      }
    } catch (e) {
      AppLogger.error('Error getting location', e);
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

  Position _positionFromCoords(double lat, double lng) {
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
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
          infoWindow: InfoWindow(title: AppLocalization.translate('your_location', ref.read(appLanguageProvider))),
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
            title: AppLocalization.translate('pickup', ref.read(appLanguageProvider)),
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
            title: order.serviceId == 3 || order.serviceId == 4
                ? AppLocalization.translate('delivery_address', ref.read(appLanguageProvider))
                : AppLocalization.translate('dropoff', ref.read(appLanguageProvider)),
            snippet: order.dropoffAddress,
          ),
        ),
      );
    }

    // Add available orders markers
    for (var i = 0; i < ordersState.availableOrders.length; i++) {
      final order = ordersState.availableOrders[i];
      markers.add(
        Marker(
          markerId: MarkerId('available_${order.id}'),
          position: LatLng(order.pickupLat, order.pickupLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: 'Order #${order.id}',
            snippet: 'â‚±${order.displayEarnings.toStringAsFixed(0)} â€¢ ${order.distanceKm.toStringAsFixed(1)}km',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
      _updateActiveOrderRoute();
    }
  }

  Future<void> _updateActiveOrderRoute({bool force = false}) async {
    final activeOrder = ref.read(riderOrdersProvider).activeOrder;
    if (activeOrder == null || _currentPosition == null || _isLoadingRoute) {
      if (mounted && activeOrder == null) {
        setState(() => _polylines = {});
      }
      return;
    }

    if (!RiderRouteUtils.hasValidCoordinates(
          activeOrder.pickupLat,
          activeOrder.pickupLng,
        )) {
      return;
    }

    final target = RiderRouteUtils.navigationTarget(activeOrder);
    if (!force &&
        !RiderRouteUtils.needsRouteRefresh(
          riderLat: _currentPosition!.latitude,
          riderLng: _currentPosition!.longitude,
          destLat: target.destination.latitude,
          destLng: target.destination.longitude,
        )) {
      return;
    }

    setState(() => _isLoadingRoute = true);

    try {
      final polylines = await RiderRouteUtils.buildNavigationPolylines(
        order: activeOrder,
        riderLat: _currentPosition!.latitude,
        riderLng: _currentPosition!.longitude,
        forceRefresh: force,
      );
      if (mounted) {
        setState(() {
          _polylines = polylines;
          _isLoadingRoute = false;
        });
        if (polylines.isNotEmpty) {
          _fitBounds();
        }
      }
    } catch (e) {
      AppLogger.error('Error loading active order route', e);
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
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

  void _updateHeatmapCircles() {
    final state = ref.read(riderHeatmapProvider);
    setState(() => _heatmapCircles = RiderHeatmapState.toCircles(state.zones));
  }

  void _handleHeatmapToggle() {
    final notifier = ref.read(riderHeatmapProvider.notifier);
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    if (!notifier.state.showHeatmap) {
      final orders = ref.read(riderOrdersProvider).availableOrders;
      final zones = RiderHeatmapNotifier.zonesFromOrders(orders);
      notifier.updateZones(zones);
      if (zones.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.translate(
                'no_demand_zones_available',
                ref.read(appLanguageProvider),
              ),
            ),
          ),
        );
      }
    }
    notifier.toggleHeatmap();
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
    if (!mounted) return;
    await RiderNavigationLauncher.showChooser(
      context: context,
      destLat: lat,
      destLng: lng,
      destinationLabel: label,
      originLat: _currentPosition?.latitude,
      originLng: _currentPosition?.longitude,
    );
  }

  Widget _buildMapView() {
    AppLogger.debug('ðŸ—ºï¸ Building map view with position: $_currentPosition');
    AppLogger.debug('ðŸ”‘ Google Maps: ${SecretsConfig.googleMapsConfigStatus}');
    
    return Container(
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
        
        // Add markers, polylines, and heatmap circles
        markers: _markers,
        polylines: _polylines,
        circles: _heatmapCircles,
        
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
            AppLogger.debug('ðŸ—ºï¸ Bookings Map created and ready');
            AppLogger.debug('ðŸ”‘ Google Maps: ${SecretsConfig.googleMapsConfigStatus}');
            AppLogger.debug('ðŸ“ Initial position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
          }
        },
        
        onTap: (LatLng position) {
          AppLogger.debug('ðŸ—ºï¸ Bookings Map tapped at: ${position.latitude}, ${position.longitude}');
        },
        
        onCameraMove: (CameraPosition position) {
          AppLogger.debug('ðŸ“· Bookings Map camera moved - Zoom: ${position.zoom.toStringAsFixed(2)}');
        },
      ),
    );
  }

  Widget _buildOrdersSheet(ScrollController scrollController) {
    final ordersState = ref.watch(riderOrdersProvider);
    final isOnDuty = ref.watch(riderDutyProvider);
    final lang = ref.watch(appLanguageProvider);

    if (!isOnDuty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pause_circle_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalization.translate('you_are_off_duty_short', lang),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalization.translate('turn_on_duty_to_receive', lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final sheetChildren = <Widget>[
      Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      if (ordersState.activeOrder != null) ...[
        _buildActiveOrderCard(ordersState.activeOrder!),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalization.translate('available_orders', lang),
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5F2D82),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ordersState.lastRefreshed != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      _formatLastRefreshed(ordersState.lastRefreshed!),
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                if (ordersState.isRefreshing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ];

    if (ordersState.availableOrders.isEmpty) {
      sheetChildren.add(
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalization.translate('no_available_orders_now', lang),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    } else {
      for (var i = 0; i < ordersState.availableOrders.length; i++) {
        if (i > 0) {
          sheetChildren.add(const SizedBox(height: 12));
        }
        sheetChildren.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildAvailableOrderCard(ordersState.availableOrders[i]),
          ),
        );
      }
    }

    sheetChildren.add(const SizedBox(height: 16));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: sheetChildren,
      ),
    );
  }

  Widget _buildActiveOrderCard(RiderOrder order) {
    final rider = ref.read(riderAuthProvider).user;
    // Convert RiderOrder to RiderBooking for detail screen
    final booking = RiderBookingMapper.fromOrder(
      order,
      packageTier: rider?.packageTier,
      riderCommissionRate: rider?.commissionRate,
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
                  'â‚±${order.displayEarnings.toStringAsFixed(2)}',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.serviceId == 3 || order.serviceId == 4
                            ?                     AppLocalization.translate('pick_up_from_merchant', ref.read(appLanguageProvider))
                            : AppLocalization.translate('pickup', ref.read(appLanguageProvider)),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 10.0,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        order.pickupAddress,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 13.0,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.navigation, size: 20, color: const Color(0xFF5F2D82)),
                  onPressed: () => _openNavigation(
                    order.pickupLat,
                    order.pickupLng,
                    AppLocalization.translate('pickup', ref.read(appLanguageProvider)),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.serviceId == 3 || order.serviceId == 4
                            ?                     AppLocalization.translate('deliver_to_customer', ref.read(appLanguageProvider))
                            : AppLocalization.translate('dropoff', ref.read(appLanguageProvider)),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 10.0,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        order.dropoffAddress,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 13.0,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.navigation, size: 20, color: const Color(0xFF5F2D82)),
                  onPressed: () => _openNavigation(
                    order.dropoffLat,
                    order.dropoffLng,
                    AppLocalization.translate('delivery_address', ref.read(appLanguageProvider)),
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
                label: Text(AppLocalization.translate('view_details_track', ref.read(appLanguageProvider))),
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
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: const Color(0xFF5F2D82).withValues(alpha: 0.1),
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
                'â‚±${order.displayEarnings.toStringAsFixed(0)}',
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
          
          // Distance, payment method, and customer name
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: order.paymentMethod.toLowerCase() == 'cash'
                      ? Colors.green.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: order.paymentMethod.toLowerCase() == 'cash'
                        ? Colors.green.shade200
                        : Colors.blue.shade200,
                  ),
                ),
                child: Text(
                  order.paymentMethod.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    color: order.paymentMethod.toLowerCase() == 'cash'
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ),
              if (order.dropoffContactName.isNotEmpty) ...[
                SizedBox(width: 12.0),
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                SizedBox(width: 4.0),
                Expanded(
                  child: Text(
                    order.dropoffContactName,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 12.0,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.0),
          
          // Pickup address
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.green),
              SizedBox(width: 4.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.serviceId == 3 || order.serviceId == 4)
                      Text(
                        'Merchant',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 10.0,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    Text(
                      order.pickupAddress,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 12.0,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.serviceId == 3 || order.serviceId == 4)
                      Text(
                        AppLocalization.translate('delivery_address', ref.read(appLanguageProvider)),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 10.0,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    Text(
                      order.dropoffAddress,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 12.0,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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

                      if (!mounted) return;

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalization.translate('order_accepted', ref.read(appLanguageProvider)).replaceAll('{{rider}}', 'Order #${order.id}')),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _updateMarkers();
                        _fitBounds();
                      } else {
                        showApiErrorSnackBar(
                          context,
                          ref.read(riderOrdersProvider).error,
                          fallback: AppLocalization.translate('failed_to_accept_order', ref.read(appLanguageProvider)),
                        );
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
    final ordersState = ref.watch(riderOrdersProvider);
    final heatmapState = ref.watch(riderHeatmapProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetInitial = constraints.maxHeight < 500
            ? 0.24
            : (constraints.maxHeight < 650 ? 0.30 : 0.35);
        final sheetMax = constraints.maxHeight < 500 ? 0.50 : 0.70;

        return Stack(
          children: [
            _buildMapView(),
            Positioned(
              top: ResponsiveUtils.mapOverlayTop(context),
              right: ResponsiveUtils.spacing(context, 12),
              child: Column(
                children: [
                  MapZoomControls(
                    mapController: _mapController,
                    onCenterMap: _centerMapOnCurrentLocation,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
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
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
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
                        onTap: _handleHeatmapToggle,
                        child: Icon(
                          heatmapState.showHeatmap
                              ? Icons.layers_clear
                              : Icons.layers,
                          color: heatmapState.showHeatmap
                              ? Colors.orange
                              : const Color(0xFF5F2D82),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: DraggableScrollableSheet(
                initialChildSize: sheetInitial,
                minChildSize: 0.18,
                maxChildSize: sheetMax,
                builder: (context, scrollController) {
                  return _buildOrdersSheet(scrollController);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}


