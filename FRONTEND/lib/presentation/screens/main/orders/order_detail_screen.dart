import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../provider/main/orders/order_history_provider.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/orders/cancel_order_dialog.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../data/data_source/dto/order/order_dto.dart';
import '../../tracking/live_tracking_screen.dart';
import '../../../../data/data_source/tracking_remote_datasource.dart';
import '../../../../core/di/injection.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final int orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  }) : super(key: key);

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isCancelling = false;
  bool _isReordering = false;
  List<LatLng> _routePolyline = [];
  bool _isLoadingRoute = false;

  OrderDto? get _order {
    final orders = ref.watch(orderHistoryProvider).orders;
    try {
      return orders.firstWhere((o) => o.id == widget.orderId);
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Load route when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final order = _order;
      if (order != null && _shouldShowMap(order.status)) {
        _loadRoute(order);
      }
    });
  }

  Future<void> _loadRoute(OrderDto order) async {
    if (_isLoadingRoute) return;
    
    setState(() => _isLoadingRoute = true);
    
    try {
      final trackingDataSource = getIt<TrackingRemoteDataSource>();
      final result = await trackingDataSource.getRoute(
        order.pickupLat,
        order.pickupLng,
        order.dropoffLat,
        order.dropoffLng,
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

  bool get _canCancel {
    final order = _order;
    if (order == null) return false;
    return order.status == 'pending' || order.status == 'accepted';
  }

  bool get _canReorder {
    final order = _order;
    if (order == null) return false;
    return order.status == 'completed' || order.status == 'cancelled';
  }

  bool get _canTrack {
    final order = _order;
    if (order == null) return false;
    return order.status != 'completed' &&
        order.status != 'cancelled' &&
        order.status != 'failed';
  }

  Future<void> _handleCancelOrder() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => CancelOrderDialog(
        onConfirm: (reason) {
          Navigator.of(context).pop(reason);
        },
      ),
    );

    if (result != null && mounted) {
      setState(() => _isCancelling = true);

      final success = await ref
          .read(orderHistoryProvider.notifier)
          .cancelOrder(widget.orderId, result);

      if (mounted) {
        setState(() => _isCancelling = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleReorder() async {
    setState(() => _isReordering = true);

    final success =
        await ref.read(orderHistoryProvider.notifier).reorder(widget.orderId);

    if (mounted) {
      setState(() => _isReordering = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reorder'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleTrackOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveTrackingScreen(orderId: widget.orderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    if (order == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: AuthHeader(title: 'Order Details'),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text('Order not found'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: AuthHeader(title: 'Order Details'),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: Colors.grey[300]),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(order),
                    const SizedBox(height: 16),
                    // Map preview for active orders
                    if (_shouldShowMap(order.status)) ...[
                      _buildMapPreview(order),
                      const SizedBox(height: 16),
                    ],
                    _buildOrderInfo(order),
                    const SizedBox(height: 16),
                    _buildAddressInfo(order),
                    const SizedBox(height: 16),
                    _buildPriceBreakdown(order),
                    if (order.cancelReason != null) ...[
                      const SizedBox(height: 16),
                      _buildCancellationInfo(order),
                    ],
                  ],
                ),
              ),
            ),

            // Action buttons
            if (_canCancel || _canReorder || _canTrack)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_canTrack)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleTrackOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5F2D82),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Track Order',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (_canTrack && _canCancel) const SizedBox(width: 12),
                    if (_canCancel)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isCancelling ? null : _handleCancelOrder,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[700],
                            side: BorderSide(color: Colors.red[700]!),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isCancelling
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Cancel Order',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    if (_canReorder)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isReordering ? null : _handleReorder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5F2D82),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isReordering
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Reorder',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(OrderDto order) {
    final statusColor = _getStatusColor(order.status);
    final statusText = _getStatusText(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(order.status),
            color: statusColor,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order #${order.id}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(OrderDto order) {
    final createdAt = DateTime.parse(order.createdAt);
    final formattedDate = DateFormat('MMMM dd, yyyy • hh:mm a').format(createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Information',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Service', _getServiceName(order.serviceId)),
          _buildInfoRow('Order ID', '#${order.id}'),
          _buildInfoRow('Date', formattedDate),
          _buildInfoRow('Payment Method', order.paymentMethod.toUpperCase()),
          _buildInfoRow(
            'Payment Status',
            order.paymentStatus.toUpperCase(),
            valueColor: order.paymentStatus == 'paid'
                ? Colors.green
                : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInfo(OrderDto order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Addresses',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
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
                    const Text(
                      'Pickup',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      order.pickupAddress?.address ?? 'N/A',
                      style: const TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Dropoff',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      order.dropoffAddress?.address ?? 'N/A',
                      style: const TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(OrderDto order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Breakdown',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow('Estimated Fare', order.estimatedFare),
          if (order.actualFare != null)
            _buildPriceRow('Actual Fare', order.actualFare!),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₱${(order.actualFare ?? order.estimatedFare).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5F2D82),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationInfo(OrderDto order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Cancellation Reason',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.cancelReason!,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13,
              color: Colors.red[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
        return 'Driver Accepted';
      case 'picked_up':
        return 'Order Picked Up';
      case 'in_transit':
        return 'On The Way';
      case 'completed':
        return 'Delivered';
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
        return Icons.check_circle;
      case 'picked_up':
        return Icons.shopping_bag;
      case 'in_transit':
        return Icons.local_shipping;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.info;
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

  Widget _buildMapPreview(OrderDto order) {
    return GestureDetector(
      onTap: _handleTrackOrder,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    (order.pickupLat + order.dropoffLat) / 2,
                    (order.pickupLng + order.dropoffLng) / 2,
                  ),
                  zoom: 13,
                ),
                markers: _buildMapMarkers(order),
                polylines: _buildMapPolylines(order),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                rotateGesturesEnabled: false,
                scrollGesturesEnabled: false,
                tiltGesturesEnabled: false,
                zoomGesturesEnabled: false,
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
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Tap to track live',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Status badge overlay
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(order.status),
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(order.status),
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Set<Marker> _buildMapMarkers(OrderDto order) {
    final markers = <Marker>{};
    
    // Pickup marker (green)
    markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: LatLng(order.pickupLat, order.pickupLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Pickup Location'),
    ));
    
    // Dropoff marker (red)
    markers.add(Marker(
      markerId: const MarkerId('dropoff'),
      position: LatLng(order.dropoffLat, order.dropoffLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Dropoff Location'),
    ));
    
    return markers;
  }

  Set<Polyline> _buildMapPolylines(OrderDto order) {
    final polylines = <Polyline>{};
    
    // Use actual route if available, otherwise fallback to straight line
    final points = _routePolyline.isNotEmpty
        ? _routePolyline
        : [
            LatLng(order.pickupLat, order.pickupLng),
            LatLng(order.dropoffLat, order.dropoffLng),
          ];
    
    polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      points: points,
      color: const Color(0xFF5F2D82),
      width: 4,
      // Use solid line for actual route, dashed for straight line
      patterns: _routePolyline.isEmpty 
          ? [PatternItem.dash(20), PatternItem.gap(10)]
          : [],
    ));
    
    return polylines;
  }
}
