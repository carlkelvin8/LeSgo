import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/utils/order_contact_actions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/order_status_utils.dart';
import '../../../../core/services/order_polling_service.dart';
import '../../../../data/data_source/order_remote_datasource.dart';
import '../../../../data/data_source/dto/order/order_dto.dart';
import '../../../../core/di/injection.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/chat/order_chat_widget.dart';
import '../../../widgets/chat/chat_button_widget.dart';
import '../../../provider/tracking/live_tracking_provider.dart';
import '../../../widgets/tracking/driver_info_card.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/cart_cleanup.dart';

class SimpleOrderTrackingScreen extends ConsumerStatefulWidget {
  final int orderId;

  const SimpleOrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<SimpleOrderTrackingScreen> createState() => _SimpleOrderTrackingScreenState();
}

class _SimpleOrderTrackingScreenState extends ConsumerState<SimpleOrderTrackingScreen> {
  OrderDto? order;
  bool isLoading = true;
  String? error;
  GoogleMapController? _mapController;
  bool _mapReady = false;
  bool _showMap = false;
  VoidCallback? _cancelOrderPoll;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
    _cancelOrderPoll = getIt<OrderPollingService>().watchOrder(
      widget.orderId,
      listener: _handleOrderPoll,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set context for notifications
      ref.read(liveTrackingProvider(widget.orderId).notifier).setContext(context);
    });
  }

  @override
  void dispose() {
    _cancelOrderPoll?.call();
    try {
      _mapController?.dispose();
    } catch (_) {}
    _mapController = null;
    super.dispose();
  }

  void _handleOrderPoll(OrderPollUpdate update) {
    if (!mounted) return;
    if (!_isOrderActive(update.status) && !OrderStatusUtils.isTerminal(update.status)) {
      return;
    }

    final previousStatus = order?.status;
    final newStatus = update.status;

    setState(() {
      order = update.order;
      isLoading = false;
      _showMap = _isOrderActive(newStatus);
    });

    if (previousStatus != null && previousStatus != newStatus) {
      if (newStatus.toLowerCase() == 'cancelled') {
        unawaited(CartCleanup.clearAllCarts(ref));
      }
      _showStatusChangeNotification(previousStatus, newStatus);
    }
  }

  Future<void> _loadOrderDetails() async {
    try {
      if (!mounted) return;
      
      // Don't show loading spinner on refresh
      if (order == null) {
        setState(() {
          isLoading = true;
          error = null;
        });
      }

      final orderDataSource = getIt<OrderRemoteDataSource>();
      final response = await orderDataSource.getOrder(widget.orderId);
      
      if (response.success && mounted) {
        final previousStatus = order?.status;
        final newStatus = response.data.status;
        
        setState(() {
          order = response.data;
          isLoading = false;
          // Show map if order is active
          _showMap = _isOrderActive(response.data.status);
        });
        
        // Show notification if status changed
        if (previousStatus != null && previousStatus != newStatus) {
          _showStatusChangeNotification(previousStatus, newStatus);
        }
      } else if (mounted) {
        setState(() {
          if (order == null) {
            error = 'Failed to load order details';
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (order == null) {
            error = 'Error: $e';
          }
          isLoading = false;
        });
      }
    }
  }

  void _showStatusChangeNotification(String oldStatus, String newStatus) {
    String message = '';
    Color backgroundColor = Colors.blue;
    
    switch (newStatus.toLowerCase()) {
      case 'accepted':
        message = 'Driver has accepted your order!';
        backgroundColor = Colors.green;
        break;
      case 'picked_up':
      case 'pickedup':
        message = 'Your order has been picked up!';
        backgroundColor = Colors.blue;
        break;
      case 'in_transit':
      case 'intransit':
      case 'on_the_way':
        message = 'Your order is on the way!';
        backgroundColor = Colors.blue;
        break;
      case 'completed':
      case 'delivered':
        message = 'Your order has been delivered!';
        backgroundColor = Colors.green;
        break;
      case 'cancelled':
        message = 'Your order has been cancelled.';
        backgroundColor = Colors.red;
        break;
      default:
        return; // Don't show notification for other status changes
    }
    
    if (mounted && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  bool _isOrderActive(String status) {
    final activeStatuses = ['accepted', 'picked_up', 'in_transit', 'on_the_way'];
    return activeStatuses.contains(status.toLowerCase());
  }

  void _fitBounds() {
    if (!_mapReady || _mapController == null) return;
    final bounds = ref
        .read(liveTrackingProvider(widget.orderId).notifier)
        .getCameraBounds();
    if (bounds != null) {
      try {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      } catch (_) {}
    }
  }

  void _callDriver() {
    final driverInfo = ref.read(liveTrackingProvider(widget.orderId)).driverInfo;
    if (driverInfo?.phone != null) {
      launchUrl(Uri.parse('tel:${driverInfo!.phone}'));
    }
  }

  void _contactDriver() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderChatWidget(
        orderId: widget.orderId,
        orderType: OrderContactActions.normalizeOrderType(
          order?.serviceType ?? 'leseat',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(liveTrackingProvider(widget.orderId));

    // Listen for tracking state changes to update map
    ref.listen<LiveTrackingState>(
      liveTrackingProvider(widget.orderId),
      (previous, next) {
        if (next.markers.isNotEmpty && _mapReady && previous?.markers != next.markers) {
          _fitBounds();
        }
      },
    );
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: order != null && _isOrderActive(order!.status)
          ? FloatingChatButton(
              orderId: widget.orderId,
              orderType: 'lesride',
            )
          : null,
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
                  Expanded(
                    child: Text(
                      'Order #${widget.orderId}',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 18),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            Container(height: 1, color: Colors.grey[300]),

            // Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                error!,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadOrderDetails,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : order != null
                          ? _showMap
                              ? _buildTrackingView(trackingState)
                              : _buildOrderDetails()
                          : const Center(child: Text('Order not found')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingView(LiveTrackingState trackingState) {
    return Stack(
      children: [
        // Google Maps
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: trackingState.pickupLocation ?? const LatLng(8.4542, 124.6319),
            zoom: 14,
          ),
          markers: trackingState.markers,
          polylines: trackingState.polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          onMapCreated: (controller) {
            if (mounted) {
              _mapController = controller;
              _mapReady = true;
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) _fitBounds();
              });
            }
          },
        ),

        // Loading overlay
        if (trackingState.isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),

        // My location button
        Positioned(
          right: 16,
          bottom: 280,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location, color: Color(0xFF5F2D82)),
              onPressed: _fitBounds,
            ),
          ),
        ),

        // Bottom sheet with order info
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ETA Section
                  if (trackingState.eta != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estimated Arrival',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  trackingState.eta!,
                                  style: const TextStyle(
                                    fontFamily: 'TT Fors',
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (trackingState.distance != null)
                                  Text(
                                    trackingState.distance!,
                                    style: const TextStyle(
                                      fontFamily: 'TT Fors',
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Status
                  _buildStatusCard(),
                  const SizedBox(height: 16),

                  // Driver Info
                  if (trackingState.driverInfo != null)
                    DriverInfoCard(
                      driverInfo: trackingState.driverInfo!,
                      onCall: _callDriver,
                      onChat: _contactDriver,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails() {
    if (order == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildOrderInfo(),
          const SizedBox(height: 16),
          _buildAddressInfo(),
          const SizedBox(height: 16),
          _buildPriceInfo(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor(order!.status);
    final statusText = _getStatusText(order!.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(order!.status),
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
                  'Order #${order!.id}',
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

  Widget _buildOrderInfo() {
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
          _buildInfoRow('Service', _getServiceName(order!.serviceId)),
          _buildInfoRow('Payment Method', order!.paymentMethod.toUpperCase()),
          _buildInfoRow('Payment Status', order!.paymentStatus.toUpperCase()),
          if (order!.notes != null && order!.notes!.isNotEmpty)
            _buildInfoRow('Notes', order!.notes!),
        ],
      ),
    );
  }

  Widget _buildAddressInfo() {
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
                      order!.pickupAddress,
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
                      order!.dropoffAddress,
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

  Widget _buildPriceInfo() {
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
          _buildPriceRow('Estimated Fare', order!.estimatedFare),
          if (order!.actualFare != null)
            _buildPriceRow('Actual Fare', order!.actualFare!),
          if (order!.discountAmount > 0)
            _buildPriceRow('Discount', -order!.discountAmount),
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
                '₱${(order!.actualFare ?? order!.estimatedFare).toStringAsFixed(2)}',
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

  Widget _buildInfoRow(String label, String value) {
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
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
}