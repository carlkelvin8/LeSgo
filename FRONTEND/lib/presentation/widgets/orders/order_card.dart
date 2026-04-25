import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/data_source/dto/order/order_dto.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../screens/tracking/live_tracking_screen.dart';
import '../../../data/data_source/tracking_remote_datasource.dart';
import '../../../core/di/injection.dart';

class OrderCard extends StatefulWidget {
  final OrderDto order;
  final VoidCallback onTap;

  const OrderCard({
    Key? key,
    required this.order,
    required this.onTap,
  }) : super(key: key);

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  List<LatLng> _routePolyline = [];
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    if (_shouldShowMap(widget.order.status)) {
      _loadRoute();
    }
  }

  Future<void> _loadRoute() async {
    if (_isLoadingRoute) return;
    
    setState(() => _isLoadingRoute = true);
    
    try {
      final trackingDataSource = getIt<TrackingRemoteDataSource>();
      final result = await trackingDataSource.getRoute(
        widget.order.pickupLat,
        widget.order.pickupLng,
        widget.order.dropoffLat,
        widget.order.dropoffLng,
      );
      
      if (result['success'] == true && result['data'] != null) {
        final polylineData = result['data']['polyline'];
        if (polylineData is List && polylineData.isNotEmpty) {
          final points = polylineData.map((point) {
            return LatLng(
              (point['lat'] as num).toDouble(),
              (point['lng'] as num).toDouble(),
            );
          }).toList();
          
          if (mounted) {
            setState(() {
              _routePolyline = points;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading route: $e');
      // Fallback to straight line if route fails
    } finally {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'picked_up':
      case 'in_transit':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Finding Driver';
      case 'accepted':
        return 'Accepted';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'On The Way';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'failed':
        return 'Failed';
      default:
        return status.toUpperCase();
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'picked_up':
        return Icons.shopping_bag_outlined;
      case 'in_transit':
        return Icons.local_shipping_outlined;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
      case 'failed':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getServiceName(int serviceId) {
    switch (serviceId) {
      case 1:
        return 'LesGo';
      case 2:
        return 'LesRide';
      case 3:
        return 'LesEat';
      case 4:
        return 'LesBuy';
      case 5:
        return 'LesTransport';
      default:
        return 'Order';
    }
  }

  bool _shouldShowMap(String status) {
    // Show map for active orders
    return status.toLowerCase() == 'accepted' ||
        status.toLowerCase() == 'picked_up' ||
        status.toLowerCase() == 'in_transit' ||
        status.toLowerCase() == 'driver_arrived_at_pickup' ||
        status.toLowerCase() == 'in_progress';
  }

  Set<Marker> _buildMapMarkers() {
    final markers = <Marker>{};
    
    // Pickup marker (green)
    markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: LatLng(widget.order.pickupLat, widget.order.pickupLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ));
    
    // Dropoff marker (red)
    markers.add(Marker(
      markerId: const MarkerId('dropoff'),
      position: LatLng(widget.order.dropoffLat, widget.order.dropoffLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));
    
    return markers;
  }

  Set<Polyline> _buildMapPolylines() {
    final polylines = <Polyline>{};
    
    // Use actual route if available, otherwise fallback to straight line
    final points = _routePolyline.isNotEmpty
        ? _routePolyline
        : [
            LatLng(widget.order.pickupLat, widget.order.pickupLng),
            LatLng(widget.order.dropoffLat, widget.order.dropoffLng),
          ];
    
    polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      points: points,
      color: const Color(0xFF5F2D82),
      width: 3,
      // Use solid line for actual route, dashed for straight line
      patterns: _routePolyline.isEmpty 
          ? [PatternItem.dash(15), PatternItem.gap(8)]
          : [],
    ));
    
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.order.status);
    final createdAt = DateTime.parse(widget.order.createdAt);
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Service badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F2D82).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getServiceName(widget.order.serviceId),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 11),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5F2D82),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Order ID
                Text(
                  '#${widget.order.id}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(widget.order.status),
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(widget.order.status),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 11),
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Map preview for active orders
            if (_shouldShowMap(widget.order.status)) ...[
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveTrackingScreen(orderId: widget.order.id),
                    ),
                  );
                },
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              (widget.order.pickupLat + widget.order.dropoffLat) / 2,
                              (widget.order.pickupLng + widget.order.dropoffLng) / 2,
                            ),
                            zoom: 13,
                          ),
                          markers: _buildMapMarkers(),
                          polylines: _buildMapPolylines(),
                          myLocationEnabled: false,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          compassEnabled: false,
                          rotateGesturesEnabled: false,
                          scrollGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          zoomGesturesEnabled: false,
                        ),
                        // Loading indicator
                        if (_isLoadingRoute)
                          Container(
                            color: Colors.black.withValues(alpha: 0.1),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF5F2D82),
                                ),
                              ),
                            ),
                          ),
                        // Tap overlay hint
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Tap to track',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: ResponsiveUtils.fontSize(context, 10),
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Addresses
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 20,
                      color: Colors.grey[300],
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.order.pickupAddress,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.order.dropoffAddress,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Footer row
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  '₱${widget.order.estimatedFare.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5F2D82),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
