import '../../../../core/utils/map_pins.dart';
import 'package:lesgo/core/utils/money.dart';
import '../../../../core/utils/order_status_mapper.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/map_styles.dart';
import '../../../provider/main/orders/active_orders_provider.dart';
import '../../../provider/main/orders/order_history_provider.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/orders/cancel_order_dialog.dart';
import '../../../widgets/orders/order_style.dart';
import '../../../widgets/orders/premium_order_widgets.dart';
import '../../../../core/utils/order_progress.dart';
import '../../../../core/utils/order_service_labels.dart';
import '../../../widgets/orders/proof_of_delivery_section.dart';
import '../../../../data/data_source/order_remote_datasource.dart';
import '../../../../core/utils/order_cancel_utils.dart';
import '../../../../core/utils/order_payment_label.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/data_source/dto/order/order_dto.dart';
import '../../tracking/live_tracking_screen.dart';
import '../../../../data/data_source/tracking_remote_datasource.dart';
import '../../../../core/di/injection.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isCancelling = false;
  bool _isReordering = false;
  List<LatLng> _routePolyline = [];
  bool _isLoadingRoute = false;
  OrderDto? _fetchedOrder;
  List<String> _proofImages = const [];

  OrderDto? get _order {
    if (_fetchedOrder != null) return _fetchedOrder;
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
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final dataSource = getIt<OrderRemoteDataSource>();
      var proofs = await dataSource.fetchProofImages(widget.orderId);

      try {
        final response = await dataSource.getOrder(widget.orderId);
        if (!mounted) return;
        if (response.success) {
          if (proofs.isEmpty) {
            proofs = response.data.proofImages;
          }
          setState(() {
            _fetchedOrder = response.data;
            _proofImages = proofs;
          });
          if (_shouldShowMap(response.data.status)) {
            _loadRoute(response.data);
          }
          return;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error loading order details: $e');
      }

      if (!mounted) return;
      if (proofs.isNotEmpty) {
        setState(() => _proofImages = proofs);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading order details: $e');
      if (mounted) {
        final cached = _order;
        if (cached != null && _shouldShowMap(cached.status)) {
          _loadRoute(cached);
        }
      }
    }
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
      if (kDebugMode) debugPrint('Error loading route: $e');
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
    return canCustomerCancelOrderStatus(order.status);
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
      builder: (context) => const CancelOrderDialog(),
    );

    if (result != null && mounted) {
      setState(() => _isCancelling = true);

      final success = await ref
          .read(orderHistoryProvider.notifier)
          .cancelOrder(widget.orderId, result);

      if (mounted) {
        setState(() => _isCancelling = false);

        if (success) {
          // The home "Track your order" banner must drop the cancelled order.
          ref.read(activeOrdersProvider.notifier).loadActiveOrders();
          // Refresh from the server: the screen otherwise keeps showing the
          // previously fetched (pre-cancel) status and buttons.
          await _loadOrderDetails();
          if (!mounted) return;
          SnackBarUtils.showSuccess(context, 'Order cancelled successfully');
        } else {
          final error = ref.read(orderHistoryProvider).error;
          SnackBarUtils.showError(context, error ?? 'Failed to cancel order');
        }
      }
    }
  }

  Future<void> _handleReorder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reorder?'),
        content: const Text(
          'This will place a new order with the same items and addresses.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Place order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isReordering = true);

    final success = await ref
        .read(orderHistoryProvider.notifier)
        .reorder(widget.orderId);

    if (mounted) {
      setState(() => _isReordering = false);

      if (success) {
        ref.read(activeOrdersProvider.notifier).loadActiveOrders();
        SnackBarUtils.showSuccess(context, 'Order placed successfully!');
        Navigator.pop(context);
      } else {
        final error = ref.read(orderHistoryProvider).error;
        SnackBarUtils.showError(context, error ?? 'Failed to reorder');
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
                color: AppColors.surface(context, Colors.white),
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                child: Row(
                  children: [
                    const Expanded(child: AuthHeader(title: 'Order Details')),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Order not found'),
                      SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                      TextButton.icon(
                        onPressed: _loadOrderDetails,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent(
                            context,
                            Color(0xFF5F2D82),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.spacing(context, 16),
                            vertical: ResponsiveUtils.spacing(context, 8),
                          ),
                          minimumSize: const Size(48, 44),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface(context, Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.surface(context, Colors.white),
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: Row(
                children: [
                  const Expanded(child: AuthHeader(title: 'Order Details')),
                ],
              ),
            ),

            Container(
              height: 1,
              color: AppColors.surface(context, Colors.grey[300]!),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Reveal(child: _buildStatusCard(order)),
                    const SizedBox(height: 28),
                    // Say why it was cancelled right under the status, not at
                    // the very bottom of a long page.
                    if (order.cancelReason != null) ...[
                      Reveal(index: 1, child: _buildCancellationInfo(order)),
                      const SizedBox(height: 28),
                    ],
                    // Map preview for active orders
                    if (_shouldShowMap(order.status)) ...[
                      Reveal(index: 1, child: _buildMapPreview(order)),
                      const SizedBox(height: 28),
                    ],
                    Reveal(
                      index: 2,
                      child: RouteCard(
                        flat: true,
                        pickup: order.pickupAddress,
                        dropoff: order.dropoffAddress,
                        pickupLabel: _isFood(order) ? 'Restaurant' : 'Pickup',
                        dropoffLabel: _isFood(order)
                            ? 'Deliver to'
                            : 'Drop-off',
                        title: 'Route',
                      ),
                    ),
                    const SizedBox(height: 28),
                    Reveal(index: 3, child: _buildReceipt(order)),
                    if (_proofImages.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Reveal(
                        index: 4,
                        child: ProofOfDeliverySection(imageUrls: _proofImages),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Action buttons
            if (_canCancel || _canReorder || _canTrack)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: AppColors.surface(context, Colors.white),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border(context, const Color(0xFFEEE8F3)),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (_canCancel)
                      Expanded(
                        child: PremiumButton(
                          flat: true,
                          label: 'Cancel order',
                          danger: true,
                          outlined: true,
                          loading: _isCancelling,
                          onPressed: _handleCancelOrder,
                        ),
                      ),
                    if (_canCancel && (_canTrack || _canReorder))
                      const SizedBox(width: 12),
                    if (_canTrack)
                      Expanded(
                        flex: _canCancel ? 1 : 2,
                        child: PremiumButton(
                          flat: true,
                          label: 'Track order',
                          icon: Icons.near_me_rounded,
                          onPressed: _handleTrackOrder,
                        ),
                      ),
                    if (_canReorder)
                      Expanded(
                        child: PremiumButton(
                          flat: true,
                          label: 'Reorder',
                          icon: Icons.replay_rounded,
                          loading: _isReordering,
                          onPressed: _handleReorder,
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

  bool _isFood(OrderDto order) {
    final service = OrderServiceLabels.labelForOrder(order);
    return service == 'LesEat' || service == 'LesBuy';
  }

  /// The first thing you see: which service, what is happening, and where it
  /// is on its way. No database ids are shown anywhere on this screen.
  Widget _buildStatusCard(OrderDto order) {
    final service = OrderServiceLabels.labelForOrder(order);
    final style = OrderStyle.status(order.status);
    final raw = order.status.trim().toLowerCase();
    final bad = const {'cancelled', 'canceled', 'failed'}.contains(raw);
    final done = const {'completed', 'delivered'}.contains(raw);
    final progress = OrderProgress.of(
      service: service,
      status: order.status,
      scheduledAt: order.scheduledAt,
    );
    final createdAt = DateTime.tryParse(
      order.createdAt ?? order.updatedAt ?? '',
    )?.toLocal();
    final date = createdAt != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(createdAt)
        : null;
    return OrderStatusHeader(
      service: service,
      date: date,
      statusLabel: style.label,
      tone: bad
          ? HeroTone.danger
          : done
          ? HeroTone.success
          : HeroTone.active,
      headline: (bad || done) ? null : progress.headline,
      stepLabels: (bad || done) ? const [] : progress.stepLabels,
      stepIndex: progress.stepIndex,
    );
  }

  /// Items, price lines, total and how it was paid, as one receipt.
  Widget _buildReceipt(OrderDto order) {
    final items = order.effectiveItems;
    final subtotal = _itemsSubtotal(order);
    final payment = orderPaymentLabel(
      status: order.status,
      paymentStatus: order.paymentStatus,
      paymentMethod: order.paymentMethod,
    );
    final neutral = AppColors.foreground(context, Colors.grey[600]!);
    final statusText = payment.text.isEmpty
        ? ''
        : payment.text[0].toUpperCase() +
              payment.text.substring(1).toLowerCase();
    return ReceiptCard(
      flat: true,
      items: [
        for (final it in items)
          ReceiptItem(
            qty: it.quantity,
            name: it.name,
            price: (it.actualPrice ?? it.estimatedPrice) == null
                ? null
                : Money.format(
                    (it.actualPrice ?? it.estimatedPrice!) * it.quantity,
                  ),
          ),
      ],
      rows: [
        if (subtotal != null) ...[
          // Food / store orders: show what the money is made of instead of
          // calling the delivery fee the "fare".
          ReceiptRow('Subtotal', Money.format(subtotal)),
          ReceiptRow('Delivery fee', Money.format(order.effectiveDeliveryFee)),
          if (order.discountAmount > 0)
            ReceiptRow(
              'Discount',
              '-${Money.format(order.discountAmount)}',
              color: const Color(0xFF2E9E5B),
            ),
        ] else
          ReceiptRow('Estimated fare', Money.format(order.estimatedFare)),
        if (order.actualFare != null)
          ReceiptRow('Actual fare', Money.format(order.actualFare!)),
      ],
      total: Money.format(order.actualFare ?? order.effectiveTotalAmount),
      footer: PaymentStrip(
        method: OrderStyle.paymentMethodLabel(order.paymentMethod),
        status: statusText,
        statusColor: payment.color(neutral),
      ),
    );
  }

  /// Items subtotal recorded with the order (food/store), or null for rides
  /// and parcels where the fare is the whole price.
  double? _itemsSubtotal(OrderDto order) {
    final raw = order.meta?['subtotal'];
    final value = raw is num ? raw.toDouble() : double.tryParse('${raw ?? ''}');
    return value != null && value > 0 ? value : null;
  }

  Widget _buildCancellationInfo(OrderDto order) =>
      CancellationNote(reason: order.cancelReason!);

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
        // Never show a raw enum such as READY_FOR_PICKUP.
        return OrderStatusMapper.toDisplayLabel(status);
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
          color: AppColors.surface(context, Colors.grey[200]!),
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
                style: MapStyles.darkIfDark(context),
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
              ),
              // Loading indicator
              if (_isLoadingRoute)
                Container(
                  color: Colors.black.withValues(alpha: 0.1),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accent(context, const Color(0xFF5F2D82)),
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
                    color: AppColors.surface(
                      context,
                      Colors.black,
                    ).withValues(alpha: 0.6),
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

    final food = _isFood(order);
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(order.pickupLat, order.pickupLng),
        icon: MapPins.icon(food ? MapPinKind.store : MapPinKind.customer),
        anchor: MapPins.anchor,
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ),
    );

    markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(order.dropoffLat, order.dropoffLng),
        icon: MapPins.icon(food ? MapPinKind.customer : MapPinKind.destination),
        anchor: MapPins.anchor,
        infoWindow: const InfoWindow(title: 'Dropoff Location'),
      ),
    );

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

    polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: AppColors.accent(context, Color(0xFF5F2D82)),
        width: 4,
        // Always solid: dashed polylines on long routes crash iOS.
      ),
    );

    return polylines;
  }
}
