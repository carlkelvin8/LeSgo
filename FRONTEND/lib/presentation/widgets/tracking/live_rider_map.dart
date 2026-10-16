import 'package:lesgo/core/theme/app_colors.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/map_styles.dart';
import '../../../core/di/injection.dart';
import '../../../data/data_source/tracking_remote_datasource.dart';

/// A compact, self-contained map widget that polls the rider's live location
/// every 5 seconds and displays it on a Google Map along with destination
/// and optional pickup markers.
class LiveRiderMap extends StatefulWidget {
  /// The order ID to track.
  final int orderId;

  /// Customer's delivery (dropoff) location.
  final double dropoffLat;
  final double dropoffLng;

  /// Optional restaurant/pickup location.
  final double? pickupLat;
  final double? pickupLng;

  /// Height of the map widget. Defaults to 250.
  final double height;

  const LiveRiderMap({
    super.key,
    required this.orderId,
    required this.dropoffLat,
    required this.dropoffLng,
    this.pickupLat,
    this.pickupLng,
    this.height = 250,
  });

  @override
  State<LiveRiderMap> createState() => _LiveRiderMapState();
}

class _LiveRiderMapState extends State<LiveRiderMap> {
  Timer? _pollTimer;
  GoogleMapController? _mapController;

  bool _isLoading = true;
  bool _hasDriverLocation = false;
  double? _driverLat;
  double? _driverLng;
  String? _eta;
  String? _distance;
  String? _status;

  @override
  void initState() {
    super.initState();
    _fetchLiveTracking();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchLiveTracking();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    try {
      _mapController?.dispose();
    } catch (_) {}
    _mapController = null;
    super.dispose();
  }

  Future<void> _fetchLiveTracking() async {
    try {
      final datasource = getIt<TrackingRemoteDataSource>();
      final data = await datasource.getLiveTracking(widget.orderId);

      if (!mounted) return;

      if (data == null) {
        setState(() {
          _isLoading = false;
          _hasDriverLocation = false;
        });
        return;
      }

      final driverLat = _parseDouble(data['driver_lat']);
      final driverLng = _parseDouble(data['driver_lng']);
      final etaMinutes = data['eta_minutes'];
      final distanceKm = data['distance_to_destination_km'];

      setState(() {
        _isLoading = false;
        _status = data['status']?.toString();
        if (driverLat != null && driverLng != null) {
          _hasDriverLocation = true;
          _driverLat = driverLat;
          _driverLng = driverLng;
          _animateCameraToDriver();
        } else {
          _hasDriverLocation = false;
        }
        _eta = etaMinutes != null ? '${(etaMinutes as num).round()} min' : null;
        _distance = distanceKm != null
            ? '${(distanceKm as num).toStringAsFixed(1)} km'
            : null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _animateCameraToDriver() {
    if (_mapController != null && _driverLat != null && _driverLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(_driverLat!, _driverLng!)),
      );
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Rider marker
    if (_hasDriverLocation && _driverLat != null && _driverLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('rider'),
          position: LatLng(_driverLat!, _driverLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Rider'),
        ),
      );
    }

    // Destination (dropoff) marker
    markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(widget.dropoffLat, widget.dropoffLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Delivery Location'),
      ),
    );

    // Optional pickup marker
    if (widget.pickupLat != null && widget.pickupLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(widget.pickupLat!, widget.pickupLng!),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }

    return markers;
  }

  LatLng _initialCameraTarget() {
    if (_hasDriverLocation && _driverLat != null && _driverLng != null) {
      return LatLng(_driverLat!, _driverLng!);
    }
    if (widget.pickupLat != null && widget.pickupLng != null) {
      return LatLng(widget.pickupLat!, widget.pickupLng!);
    }
    return LatLng(widget.dropoffLat, widget.dropoffLng);
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status label
        _buildStatusLabel(),
        const SizedBox(height: 8),

        // Map container
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: _isLoading
                ? Container(
                    color: AppColors.surface(context, Colors.grey[200]!),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF5F2D82),
                        ),
                      ),
                    ),
                  )
                : GoogleMap(
                    style: MapStyles.darkIfDark(context),
                    initialCameraPosition: CameraPosition(
                      target: _initialCameraTarget(),
                      zoom: 14,
                    ),
                    markers: _buildMarkers(),
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (_hasDriverLocation) {
                        _animateCameraToDriver();
                      }
                    },
                  ),
          ),
        ),

        // Bottom info bar with ETA and distance
        if (_hasDriverLocation && (_eta != null || _distance != null)) ...[
          const SizedBox(height: 8),
          _buildInfoBar(),
        ],
      ],
    );
  }

  Widget _buildStatusLabel() {
    final bool driverAssigned = _hasDriverLocation ||
        (_status != null &&
            ['accepted', 'picked_up', 'in_progress', 'in_transit']
                .contains(_status!.toLowerCase()));

    final String label =
        driverAssigned ? 'Rider is on the way' : 'Waiting for rider...';
    final IconData icon =
        driverAssigned ? Icons.two_wheeler : Icons.hourglass_top;
    final Color color =
        driverAssigned ? const Color(0xFF5F2D82) : Colors.orange[700]!;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent(context, Color(0xFF5F2D82)).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_eta != null) ...[
            const Icon(Icons.access_time, size: 16, color: Color(0xFF5F2D82)),
            const SizedBox(width: 4),
            Text(
              'ETA: $_eta',
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5F2D82),
              ),
            ),
          ],
          if (_eta != null && _distance != null)
            const SizedBox(width: 16),
          if (_distance != null) ...[
            const Icon(Icons.straighten, size: 16, color: Color(0xFF5F2D82)),
            const SizedBox(width: 4),
            Text(
              _distance!,
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5F2D82),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
