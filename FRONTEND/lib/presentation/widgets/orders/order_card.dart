import '../../../core/utils/map_pins.dart';
import 'package:lesgo/core/theme/app_tokens.dart';
import 'package:lesgo/core/utils/money.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/data_source/dto/order/order_dto.dart';
import '../../../core/constants/map_styles.dart';
import '../../../core/constants/order_status_constants.dart';
import '../../../core/utils/order_payment_label.dart';
import '../../../core/utils/order_progress.dart';
import '../../../core/utils/order_service_labels.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../screens/tracking/live_tracking_screen.dart';
import '../../../data/data_source/tracking_remote_datasource.dart';
import '../../../core/di/injection.dart';
import '../common/service_icon.dart';
import 'order_style.dart';

/// One row of Order History: service tile, status pill, what was ordered (or
/// the route), payment + total, and a quick action (Track / Reorder).
class OrderCard extends StatefulWidget {
  final OrderDto order;
  final VoidCallback onTap;

  /// Shown on completed orders.
  final VoidCallback? onReorder;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onReorder,
  });

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
          if (mounted) setState(() => _routePolyline = points);
        }
      }
    } catch (_) {
      // Falls back to a straight line when the route can't be loaded.
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  bool _shouldShowMap(String status) {
    final s = status.toLowerCase();
    return s == OrderStatusConstants.accepted ||
        s == OrderStatusConstants.pickedUp ||
        s == OrderStatusConstants.inProgress ||
        s == OrderStatusConstants.driverArrivedAtPickup;
  }

  Set<Marker> _buildMapMarkers() {
    final service = OrderServiceLabels.labelForOrder(widget.order);
    final food = service == 'LesEat' || service == 'LesBuy';
    return {
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.order.pickupLat, widget.order.pickupLng),
        icon: MapPins.icon(food ? MapPinKind.store : MapPinKind.customer),
        anchor: MapPins.anchor,
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(widget.order.dropoffLat, widget.order.dropoffLng),
        icon: MapPins.icon(food ? MapPinKind.customer : MapPinKind.destination),
        anchor: MapPins.anchor,
      ),
    };
  }

  Set<Polyline> _buildMapPolylines() {
    final points = _routePolyline.isNotEmpty
        ? _routePolyline
        : [
            LatLng(widget.order.pickupLat, widget.order.pickupLng),
            LatLng(widget.order.dropoffLat, widget.order.dropoffLng),
          ];
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: AppColors.accent(context, const Color(0xFF5F2D82)),
        width: 3,
        // Always solid: dashed polylines on long routes crash iOS.
      ),
    };
  }

  /// "1-pc Chickenjoy ×2 · +1 more" for food / store orders.
  String? _itemsSummary(String service) {
    if (service != 'LesEat' && service != 'LesBuy') return null;
    final items = widget.order.effectiveItems;
    if (items.isEmpty) return null;
    final first = items.first;
    final head = first.quantity > 1
        ? '${first.name} ×${first.quantity}'
        : first.name;
    return items.length > 1 ? '$head · +${items.length - 1} more' : head;
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final service = OrderServiceLabels.labelForOrder(order);
    final status = OrderStyle.status(order.status);
    final serviceColor = OrderStyle.serviceColor(service);
    final raw = order.status.trim().toLowerCase();
    final cancelled =
        raw == 'cancelled' || raw == 'canceled' || raw == 'failed';
    final completed = raw == 'completed' || raw == 'delivered';
    final active = !cancelled && !completed;
    final createdAt = DateTime.tryParse(
      order.createdAt ?? order.updatedAt ?? '',
    )?.toLocal();
    final formattedDate = createdAt != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(createdAt)
        : 'Date unavailable';
    final payment = orderPaymentLabel(
      status: order.status,
      paymentStatus: order.paymentStatus,
      paymentMethod: order.paymentMethod,
    );
    final muted = AppColors.foreground(context, Colors.grey[600]!);
    final itemsLine = _itemsSummary(service);
    final destination = order.dropoffAddress.isNotEmpty
        ? order.dropoffAddress
        : order.pickupAddress;
    final progress = OrderProgress.of(
      service: service,
      status: order.status,
      scheduledAt: order.scheduledAt,
    );

    final bigText = MediaQuery.textScalerOf(context).scale(1) > 1.35;
    final statusPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 11),
                fontWeight: FontWeight.w700,
                color: status.color,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label:
          '$service order, ${status.label}, ${Money.format(order.effectiveTotalAmount)}',
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: AppCard.decoration(context, radius: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: service tile, title/date, status pill.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceIcon(service, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 16),
                            fontWeight: FontWeight.w800,
                            color: AppColors.foreground(
                              context,
                              Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            color: muted,
                          ),
                        ),
                        if (bigText) ...[const SizedBox(height: 6), statusPill],
                      ],
                    ),
                  ),
                  if (!bigText) ...[const SizedBox(width: 8), statusPill],
                ],
              ),

              // Live progress for orders still in flight.
              if (active) ...[
                const SizedBox(height: 12),
                _MiniProgress(progress: progress, color: status.color),
              ],

              // Map preview for orders a driver is working on.
              if (_shouldShowMap(order.status)) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveTrackingScreen(orderId: order.id),
                    ),
                  ),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface(context, Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(12),
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
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Tap to track',
                                    style: TextStyle(
                                      fontSize: 10,
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
              ],

              const SizedBox(height: 12),

              // What was ordered, or the route.
              if (itemsLine != null) ...[
                _InfoLine(
                  icon: Icons.shopping_basket_outlined,
                  color: serviceColor,
                  text: itemsLine,
                  bold: true,
                ),
                if (destination.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _InfoLine(
                    icon: Icons.location_on_outlined,
                    color: Colors.red.shade400,
                    text: destination,
                  ),
                ],
              ] else
                _Route(from: order.pickupAddress, to: order.dropoffAddress),

              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: AppColors.border(context, Colors.grey[200]!),
              ),
              const SizedBox(height: 10),

              // Footer: payment on the left, total on the right.
              Row(
                children: [
                  Icon(
                    order.paymentMethod.toLowerCase() == 'wallet'
                        ? Icons.account_balance_wallet_outlined
                        : Icons.payments_outlined,
                    size: 15,
                    color: muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${OrderStyle.paymentMethodLabel(order.paymentMethod)} • ${_title(payment.text)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: payment.color(muted),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    // estimatedFare is only the delivery fee for food/store
                    // orders; effectiveTotalAmount is what the customer pays.
                    Money.format(order.effectiveTotalAmount),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 18),
                      fontWeight: FontWeight.w800,
                      decoration: cancelled ? TextDecoration.lineThrough : null,
                      color: cancelled
                          ? AppColors.foreground(context, Colors.grey[500]!)
                          : AppColors.accent(context, const Color(0xFF5F2D82)),
                    ),
                  ),
                ],
              ),

              if (completed && widget.onReorder != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onReorder,
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('Order again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent(
                        context,
                        const Color(0xFF5F2D82),
                      ),
                      side: BorderSide(
                        color: AppColors.accent(
                          context,
                          const Color(0xFF5F2D82),
                        ).withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// "PAID" -> "Paid", "Not charged" stays.
  static String _title(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.color,
    required this.text,
    this.bold = false,
  });
  final IconData icon;
  final Color color;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            height: 1.3,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.foreground(
              context,
              bold ? Colors.black87 : Colors.grey[800]!,
            ),
          ),
        ),
      ),
    ],
  );
}

class _Route extends StatelessWidget {
  const _Route({required this.from, required this.to});
  final String from, to;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'TT Fors',
      fontSize: ResponsiveUtils.fontSize(context, 13),
      color: AppColors.foreground(context, Colors.grey[800]!),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              const SizedBox(height: 5),
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E9E5B),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: AppColors.border(context, Colors.grey[300]!),
                ),
              ),
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5484D),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  from,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
                const SizedBox(height: 10),
                Text(
                  to,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniProgress extends StatelessWidget {
  const _MiniProgress({required this.progress, required this.color});
  final OrderProgress progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final track = AppColors.border(context, Colors.grey[300]!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < progress.stepLabels.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= progress.stepIndex ? color : track,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          progress.headline,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
