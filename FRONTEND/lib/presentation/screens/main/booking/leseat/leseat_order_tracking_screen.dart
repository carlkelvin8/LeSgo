import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../../core/utils/driver_display_utils.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/api_error_mapper.dart';
import '../../../../../core/utils/order_cancel_utils.dart';
import '../../../../../core/utils/order_line_items_parser.dart';
import '../../../../../data/data_source/order_remote_datasource.dart';
import '../../../../../core/di/injection.dart';
import '../../../../provider/tracking/live_tracking_provider.dart';
import '../../../../widgets/tracking/order_status_timeline.dart';
import '../../../../widgets/tracking/driver_info_card.dart';
import '../../../../widgets/orders/cancel_order_dialog.dart';
import '../../../../../core/utils/cart_cleanup.dart';
import '../../../../widgets/chat/order_chat_widget.dart';
import '../../../../widgets/chat/chat_button_widget.dart';
import '../../../../widgets/tracking/live_rider_map.dart';
import 'package:url_launcher/url_launcher.dart';

class LeseatOrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String orderType;
  final Map<String, dynamic>? orderData;

  const LeseatOrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.orderType,
    this.orderData,
  });

  @override
  ConsumerState<LeseatOrderTrackingScreen> createState() => _LeseatOrderTrackingScreenState();
}

class _LeseatOrderTrackingScreenState extends ConsumerState<LeseatOrderTrackingScreen> {
  GoogleMapController? _mapController;
  bool _isBottomSheetExpanded = false;
  bool _mapReady = false;
  bool _isCancelling = false;
  Map<String, dynamic>? _currentOrderData;
  DriverInfo? _orderDriverInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveTrackingProvider(int.parse(widget.orderId)).notifier).setContext(context);
      _fitBounds();
    });
    _fetchCurrentOrderData();
  }

  Future<void> _fetchCurrentOrderData() async {
    try {
      final dataSource = getIt<OrderRemoteDataSource>();
      final response = await dataSource.getOrder(int.parse(widget.orderId));
      if (response.success && mounted) {
        final order = response.data;
        final meta = order.meta;

        print('===== ORDER DEBUG =====');
        print('Server Order JSON: ${order.toJson()}');
        print('Order Data from widget: ${widget.orderData}');
        print('======================');

        // Food subtotal: calculate from lesbuy_items if available
        double foodSubtotal = 0.0;
        
        // Use the new helper methods for production compatibility
        final items = order.effectiveItems;
        if (items.isNotEmpty) {
          for (final item in items) {
            final itemPrice = item.actualPrice ?? item.estimatedPrice ?? 0.0;
            final itemQuantity = item.quantity;
            foodSubtotal += itemPrice * itemQuantity;
          }
        } else {
          // Fallback to widget.orderData, then meta
          foodSubtotal = _safeToDouble(widget.orderData?['subtotal']);
          if (foodSubtotal == 0) foodSubtotal = _safeToDouble(meta?['subtotal']);
        }

        // Use effective delivery fee
        final deliveryFee = order.effectiveDeliveryFee;

        // Use effective total amount
        final grandTotal = order.effectiveTotalAmount;

        // Restaurant name — backend stores it in pickup_contact_name for LesEat
        final restaurantName = widget.orderData?['restaurantName']
            ?? meta?['restaurant_name']
            ?? order.pickupContactName
            ?? 'Restaurant';

        setState(() {
          _orderDriverInfo = DriverInfo.fromOrder(order);
          _currentOrderData = {
            'restaurantName': restaurantName,
            'subtotal': foodSubtotal,
            'deliveryFee': deliveryFee,
            'total': grandTotal,
            'deliveryAddress': order.dropoffAddress,
            'estimated_fare': order.estimatedFare,
            'status': order.status,
            'driver_id': order.driverId,
            'pickup_contact_phone': order.pickupContactPhone,
            'lesbuy_items': order.effectiveItems.map((item) => {
              'id': item.id,
              'name': item.name,
              'quantity': item.quantity,
              'estimated_price': item.estimatedPrice,
              'actual_price': item.actualPrice,
            }).toList(),
          };
        });
      }
    } catch (e) {
      print('Failed to fetch current order data: $e');
      // Fall back to widget.orderData on error
      if (mounted && widget.orderData != null) {
        setState(() {
          _currentOrderData = widget.orderData;
        });
      }
    }
  }

  @override
  void dispose() {
    try {
      _mapController?.dispose();
    } catch (_) {}
    _mapController = null;
    super.dispose();
  }

  void _fitBounds() {
    if (!_mapReady || _mapController == null) return;
    final bounds = ref
        .read(liveTrackingProvider(int.parse(widget.orderId)).notifier)
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
    final driverInfo = ref.read(liveTrackingProvider(int.parse(widget.orderId))).driverInfo;
    if (driverInfo?.phone != null) {
      launchUrl(Uri.parse('tel:${driverInfo!.phone}'));
    }
  }

  Future<void> _handleCancelOrder() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const CancelOrderDialog(),
    );

    if (result != null && mounted) {
      setState(() => _isCancelling = true);

      try {
        final dataSource = getIt<OrderRemoteDataSource>();
        await dataSource.cancelOrder(int.parse(widget.orderId), result);
        await CartCleanup.clearAllCarts(ref);

        if (mounted) {
          setState(() => _isCancelling = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
    } catch (e) {
        if (mounted) {
          setState(() => _isCancelling = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ApiErrorMapper.message(
                  e,
                  fallbackEn: 'Could not cancel order.',
                  fallbackTl: 'Hindi makansela ang order.',
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _contactDriver() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderChatWidget(
        orderId: int.tryParse(widget.orderId) ?? 0,
        orderType: 'leseat',
      ),
    );
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

  String _getStatusSubtext(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Looking for a nearby rider';
      case 'accepted':
        return 'Your rider is on the way to the restaurant';
      case 'driver_arrived_at_pickup':
        return 'Rider arrived at the restaurant';
      case 'in_progress':
      case 'ready_for_pickup':
        return 'Your food is being prepared';
      case 'picked_up':
        return 'Your order is on its way to you';
      case 'in_transit':
        return 'Your rider is heading to your location';
      case 'completed':
        return 'Your order has been delivered';
      case 'cancelled':
        return 'This order was cancelled';
      case 'failed':
        return 'Something went wrong with this order';
      default:
        return 'Your food is being prepared';
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(liveTrackingProvider(int.parse(widget.orderId)));
    final driverInfo = trackingState.driverInfo ?? _orderDriverInfo;
    // Use current order data from backend if available, otherwise fallback to widget data
    final orderData = _currentOrderData ?? widget.orderData ?? {};

    // Listen for tracking state changes to update map
    ref.listen<LiveTrackingState>(
      liveTrackingProvider(int.parse(widget.orderId)),
      (previous, next) {
        if (previous?.orderStatus != next.orderStatus && mounted) {
          _fetchCurrentOrderData();
        }
        final wasCancelled =
            previous?.orderStatus.toLowerCase() == 'cancelled';
        final isCancelled = next.orderStatus.toLowerCase() == 'cancelled';
        if (isCancelled && !wasCancelled) {
          CartCleanup.clearAllCarts(ref);
        }
        if (next.markers.isNotEmpty && _mapReady && previous?.markers != next.markers) {
          _fitBounds();
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: driverInfo != null
          ? FloatingChatButton(
              orderId: int.parse(widget.orderId),
              orderType: 'leseat',
              driverName: driverInfo.name,
            )
          : null,
      body: Stack(
        children: [
          // Google Maps with real-time tracking
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
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
            onMapCreated: (controller) {
              if (mounted) {
                _mapController = controller;
                _mapReady = true;
                // Fit bounds after a short delay to ensure markers are loaded
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
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
                ),
              ),
            ),

          // Top Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                child: Row(
                  children: [
                    // Back button
                    Container(
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
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 16)),

                    // Order Title
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.spacing(context, 16),
                          vertical: ResponsiveUtils.spacing(context, 12),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          widget.orderType,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveUtils.fontSize(context, 16),
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // My location button
          Positioned(
            right: ResponsiveUtils.spacing(context, 16),
            bottom: _isBottomSheetExpanded ? 400 : 280,
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

          // Bottom Sheet with Order Details
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < -5) {
                  setState(() => _isBottomSheetExpanded = true);
                } else if (details.primaryDelta! > 5) {
                  setState(() => _isBottomSheetExpanded = false);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isBottomSheetExpanded ? 600 : 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: EdgeInsets.only(
                        top: ResponsiveUtils.spacing(context, 12),
                      ),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ETA Section (if available)
                            if (trackingState.eta != null) ...[
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
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
                                    SizedBox(width: ResponsiveUtils.spacing(context, 16)),
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
                                          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                                          Text(
                                            trackingState.eta!,
                                            style: TextStyle(
                                              fontFamily: 'TT Fors',
                                              color: Colors.white,
                                              fontSize: ResponsiveUtils.fontSize(context, 24),
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
                                    if (trackingState.isLoadingRoute)
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                            ],

                            // Delivery Status Banner
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3CD),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFE69C)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFC107),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.restaurant,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getStatusText(trackingState.orderStatus),
                                          style: TextStyle(
                                            fontFamily: 'TT Fors',
                                            fontSize: ResponsiveUtils.fontSize(context, 16),
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF856404),
                                          ),
                                        ),
                                        Text(
                                          _getStatusSubtext(trackingState.orderStatus),
                                          style: TextStyle(
                                            fontFamily: 'TT Fors',
                                            fontSize: ResponsiveUtils.fontSize(context, 12),
                                            color: const Color(0xFF856404),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                            // Restaurant Section
                            _buildRestaurantSection(context, orderData),

                            SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                            // Order Items Section
                            _buildOrderItemsSection(context, orderData),

                            SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                            // Order Summary
                            _buildOrderSummary(context, orderData),

                            SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                            // Driver Info
                            if (driverInfo != null)
                              DriverInfoCard(
                                driverInfo: driverInfo,
                                onCall: _callDriver,
                                onChat: _contactDriver,
                              ),

                            SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                            // Contact Driver Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _contactDriver,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                  padding: EdgeInsets.symmetric(
                                    vertical: ResponsiveUtils.spacing(context, 14),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Contact Driver',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: ResponsiveUtils.fontSize(context, 16),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            // Cancel Order Button (if applicable)
                            if (canCustomerCancelOrderStatus(
                              trackingState.orderStatus,
                            )) ...[
                              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isCancelling ? null : _handleCancelOrder,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red[700],
                                    side: BorderSide(color: Colors.red[700]!),
                                    padding: EdgeInsets.symmetric(
                                      vertical: ResponsiveUtils.spacing(context, 14),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isCancelling
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(
                                          'Cancel Order',
                                          style: TextStyle(
                                            fontFamily: 'TT Fors',
                                            fontSize: ResponsiveUtils.fontSize(context, 16),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],

                            // Live Rider Map (when driver is assigned)
                            if (['accepted', 'driver_arrived_at_pickup', 'in_progress', 'picked_up']
                                .contains(trackingState.orderStatus.toLowerCase()) &&
                                trackingState.dropoffLocation != null) ...[
                              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                              LiveRiderMap(
                                orderId: int.parse(widget.orderId),
                                dropoffLat: trackingState.dropoffLocation!.latitude,
                                dropoffLng: trackingState.dropoffLocation!.longitude,
                                pickupLat: trackingState.pickupLocation?.latitude,
                                pickupLng: trackingState.pickupLocation?.longitude,
                              ),
                            ],

                            // Order Timeline (when expanded)
                            if (_isBottomSheetExpanded) ...[
                              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                              const Divider(),
                              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                              if (trackingState.tracking != null)
                                OrderStatusTimeline(
                                  tracking: trackingState.tracking!,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantSection(BuildContext context, Map<String, dynamic> orderData) {
    final restaurantName = orderData['restaurantName'] ?? 'Restaurant';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restaurant',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant,
                  color: Colors.orange[700],
                  size: 20,
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              Expanded(
                child: Text(
                  restaurantName,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemsSection(BuildContext context, Map<String, dynamic> orderData) {
    final items = OrderLineItemsParser.fromOrderDataMap(orderData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Order',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        if (items.isEmpty)
          Text(
            'Item details will appear once the restaurant confirms your order.',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              color: Colors.grey[600],
            ),
          )
        else
          ...items.map((item) {
            final itemTotal = item.price * item.quantity;
            return _buildOrderItem(
              context,
              item.name,
              'Php ${item.price.toStringAsFixed(2)}',
              item.quantity,
              itemTotal: itemTotal,
            );
          }),
      ],
    );
  }

  Widget _buildOrderItem(BuildContext context, String name, String price, int quantity, {double? itemTotal}) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 8)),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fastfood,
              size: 12,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (quantity > 1)
                  Text(
                    '$price x $quantity',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Text(
            itemTotal != null && quantity > 1 
                ? 'Php ${itemTotal.toStringAsFixed(2)}'
                : price,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, Map<String, dynamic> orderData) {
    // Safely convert to double with proper type checking
    final subtotal = _safeToDouble(orderData['subtotal']);
    final deliveryFee = _safeToDouble(orderData['deliveryFee']);
    final total = _safeToDouble(orderData['total']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildSummaryRow(context, 'Subtotal', 'Php ${subtotal.toStringAsFixed(2)}'),
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              _buildSummaryRow(context, 'Delivery Fee', 'Php ${deliveryFee.toStringAsFixed(2)}'),
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              Divider(color: Colors.grey[300]),
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              _buildSummaryRow(
                context, 
                'Total', 
                'Php ${total.toStringAsFixed(2)}',
                isTotal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to safely convert values to double
  double _safeToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper method to safely convert values to int

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, isTotal ? 16 : 14),
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, isTotal ? 16 : 14),
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isTotal ? const Color(0xFF5F2D82) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
