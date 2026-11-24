import '../../../../../core/utils/map_pins.dart';
import 'package:lesgo/core/utils/money.dart';
import '../../../../../core/utils/leseat_status_text.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../../core/constants/map_styles.dart';
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
import '../../../../../core/utils/booking_geo_utils.dart';
import '../../../../widgets/chat/order_chat_widget.dart';
import '../../../../widgets/chat/chat_button_widget.dart';
import '../../../../widgets/tracking/live_rider_map.dart';
import '../../../../widgets/orders/order_style.dart';
import '../../../../widgets/orders/premium_order_widgets.dart';
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
  ConsumerState<LeseatOrderTrackingScreen> createState() =>
      _LeseatOrderTrackingScreenState();
}

class _LeseatOrderTrackingScreenState
    extends ConsumerState<LeseatOrderTrackingScreen> {
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
      ref
          .read(liveTrackingProvider(int.parse(widget.orderId)).notifier)
          .setContext(context);
      ref
          .read(liveTrackingProvider(int.parse(widget.orderId)).notifier)
          .setPinKinds(pickup: MapPinKind.store, dropoff: MapPinKind.customer);
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
          if (foodSubtotal == 0)
            foodSubtotal = _safeToDouble(meta?['subtotal']);
        }

        // Use effective delivery fee
        final deliveryFee = order.effectiveDeliveryFee;

        // Use effective total amount
        final grandTotal = order.effectiveTotalAmount;

        final branch = meta?['branch'];
        final branchName = branch is Map
            ? branch['name']?.toString().trim()
            : null;
        final pickupContact = order.pickupContactName?.trim();
        final pickupBranch = branchName?.isNotEmpty == true
            ? (pickupContact?.isNotEmpty == true ? pickupContact : branchName)
            : null;
        final restaurantName =
            pickupBranch ??
            widget.orderData?['restaurantName'] ??
            meta?['restaurant_name'] ??
            order.pickupContactName ??
            'Restaurant';

        setState(() {
          _orderDriverInfo = DriverInfo.fromOrder(order);
          _currentOrderData = {
            'restaurantName': restaurantName,
            if (pickupBranch != null)
              'pickupBranchAddress': order.pickupAddress,
            'subtotal': foodSubtotal,
            'deliveryFee': deliveryFee,
            'total': grandTotal,
            'deliveryAddress': order.dropoffAddress,
            'estimated_fare': order.estimatedFare,
            'status': order.status,
            'driver_id': order.driverId,
            'pickup_contact_phone': order.pickupContactPhone,
            'lesbuy_items': order.effectiveItems
                .map(
                  (item) => {
                    'id': item.id,
                    'name': item.name,
                    'quantity': item.quantity,
                    'estimated_price': item.estimatedPrice,
                    'actual_price': item.actualPrice,
                  },
                )
                .toList(),
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
    final driverInfo = ref
        .read(liveTrackingProvider(int.parse(widget.orderId)))
        .driverInfo;
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

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(
      liveTrackingProvider(int.parse(widget.orderId)),
    );
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
        if (next.markers.isNotEmpty &&
            _mapReady &&
            previous?.markers != next.markers) {
          _fitBounds();
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.surface(context, Colors.white),
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
            style: MapStyles.darkIfDark(context),
            initialCameraPosition: CameraPosition(
              target:
                  trackingState.pickupLocation ?? BookingGeoUtils.defaultLatLng,
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
              color: AppColors.surface(
                context,
                Colors.black,
              ).withValues(alpha: 0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accent(context, const Color(0xFF5F2D82)),
                  ),
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
                        color: AppColors.surface(context, Colors.white),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back),
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
                          color: AppColors.surface(context, Colors.white),
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
                            color: AppColors.foreground(
                              context,
                              Colors.black87,
                            ),
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
            bottom:
                (_isBottomSheetExpanded
                    ? (MediaQuery.sizeOf(context).height * 0.8).clamp(440, 640)
                    : (MediaQuery.sizeOf(context).height * 0.28).clamp(
                        160,
                        280,
                      )) +
                8,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface(context, Colors.white),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.my_location,
                  color: AppColors.accent(context, const Color(0xFF5F2D82)),
                ),
                onPressed: _fitBounds,
              ),
            ),
          ),

          // Bottom Sheet with Order Details
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isBottomSheetExpanded
                  ? (MediaQuery.sizeOf(context).height * 0.8).clamp(440, 640)
                  : (MediaQuery.sizeOf(context).height * 0.28).clamp(160, 280),
              decoration: BoxDecoration(
                color: AppColors.surface(context, Colors.white),
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
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(
                      () => _isBottomSheetExpanded = !_isBottomSheetExpanded,
                    ),
                    onVerticalDragUpdate: (details) {
                      final delta = details.primaryDelta ?? 0;
                      if (delta < -5) {
                        setState(() => _isBottomSheetExpanded = true);
                      } else if (delta > 5) {
                        setState(() => _isBottomSheetExpanded = false);
                      }
                    },
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          margin: EdgeInsets.only(top: 4),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.surface(
                              context,
                              Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(
                        ResponsiveUtils.spacing(context, 20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ETA Section (if available)
                          if (trackingState.eta != null) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(
                                ResponsiveUtils.spacing(context, 16),
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.blue.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                      ResponsiveUtils.spacing(context, 12),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.access_time,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  SizedBox(
                                    width: ResponsiveUtils.spacing(context, 16),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Estimated Arrival',
                                          style: TextStyle(
                                            fontFamily: 'TT Fors',
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(
                                          height: ResponsiveUtils.spacing(
                                            context,
                                            4,
                                          ),
                                        ),
                                        Text(
                                          trackingState.eta!,
                                          style: TextStyle(
                                            fontFamily: 'TT Fors',
                                            color: Colors.white,
                                            fontSize: ResponsiveUtils.fontSize(
                                              context,
                                              24,
                                            ),
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),
                          ],

                          // Delivery Status Banner
                          Builder(
                            builder: (_) {
                              final raw = trackingState.orderStatus
                                  .trim()
                                  .toLowerCase();
                              return StatusBanner(
                                icon: OrderStyle.status(raw).icon,
                                title: LesEatStatusText.title(
                                  trackingState.orderStatus,
                                ),
                                subtitle: LesEatStatusText.subtext(
                                  trackingState.orderStatus,
                                ),
                                tone:
                                    const {
                                      'cancelled',
                                      'canceled',
                                      'failed',
                                    }.contains(raw)
                                    ? HeroTone.danger
                                    : const {
                                        'completed',
                                        'delivered',
                                      }.contains(raw)
                                    ? HeroTone.success
                                    : HeroTone.active,
                              );
                            },
                          ),

                          SizedBox(
                            height: ResponsiveUtils.spacing(context, 16),
                          ),

                          // Restaurant Section
                          _buildRestaurantSection(context, orderData),

                          SizedBox(
                            height: ResponsiveUtils.spacing(context, 16),
                          ),

                          // Receipt: items, fees and total
                          _buildReceipt(context, orderData),

                          SizedBox(
                            height: ResponsiveUtils.spacing(context, 20),
                          ),

                          // Driver Info
                          if (driverInfo != null)
                            DriverInfoCard(
                              driverInfo: driverInfo,
                              onCall: _callDriver,
                              // Chat is available from the floating chat button.
                            ),

                          SizedBox(
                            height: ResponsiveUtils.spacing(context, 20),
                          ),

                          // Contact Driver Button
                          PremiumButton(
                            label: 'Contact driver',
                            icon: Icons.chat_bubble_outline_rounded,
                            onPressed: _contactDriver,
                          ),

                          // Cancel Order Button (if applicable)
                          if (canCustomerCancelOrderStatus(
                            trackingState.orderStatus,
                          )) ...[
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 12),
                            ),
                            PremiumButton(
                              label: 'Cancel order',
                              danger: true,
                              outlined: true,
                              loading: _isCancelling,
                              onPressed: _handleCancelOrder,
                            ),
                          ],

                          // Live Rider Map (when driver is assigned)
                          if ([
                                'accepted',
                                'driver_arrived_at_pickup',
                                'in_progress',
                                'picked_up',
                              ].contains(
                                trackingState.orderStatus.toLowerCase(),
                              ) &&
                              trackingState.dropoffLocation != null) ...[
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 20),
                            ),
                            LiveRiderMap(
                              orderId: int.parse(widget.orderId),
                              dropoffLat:
                                  trackingState.dropoffLocation!.latitude,
                              dropoffLng:
                                  trackingState.dropoffLocation!.longitude,
                              pickupLat: trackingState.pickupLocation?.latitude,
                              pickupLng:
                                  trackingState.pickupLocation?.longitude,
                            ),
                          ],

                          // Order Timeline (when expanded)
                          if (_isBottomSheetExpanded) ...[
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 20),
                            ),
                            const Divider(),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 20),
                            ),
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
        ],
      ),
    );
  }

  Widget _buildRestaurantSection(
    BuildContext context,
    Map<String, dynamic> orderData,
  ) {
    final restaurantName = '${orderData['restaurantName'] ?? 'Restaurant'}';
    final branchAddress = orderData['pickupBranchAddress'] as String?;
    return PlaceCard(
      label: branchAddress == null ? 'Restaurant' : 'Pickup branch',
      name: restaurantName,
      address: branchAddress,
    );
  }

  Widget _buildReceipt(BuildContext context, Map<String, dynamic> orderData) {
    final items = OrderLineItemsParser.fromOrderDataMap(orderData);
    final subtotal = _safeToDouble(orderData['subtotal']);
    final deliveryFee = _safeToDouble(orderData['deliveryFee']);
    final total = _safeToDouble(orderData['total']);
    final muted = AppColors.foreground(context, Colors.grey[600]!);
    return ReceiptCard(
      items: [
        for (final item in items)
          ReceiptItem(
            qty: item.quantity,
            name: item.name,
            price: Money.format(item.price * item.quantity),
          ),
      ],
      rows: [
        ReceiptRow('Subtotal', Money.format(subtotal)),
        ReceiptRow('Delivery fee', Money.format(deliveryFee)),
      ],
      total: Money.format(total),
      footer: items.isEmpty
          ? Text(
              'Item details will appear once the restaurant confirms your order.',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12.5),
                color: muted,
              ),
            )
          : null,
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
}
