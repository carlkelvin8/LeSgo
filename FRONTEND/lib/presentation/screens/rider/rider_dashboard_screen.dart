import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/data_source/dto/order/order_dto.dart';
import '../../provider/auth/auth_provider.dart';
import '../../provider/rider/rider_order_provider.dart';

class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  ConsumerState<RiderDashboardScreen> createState() =>
      _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderOrderProvider.notifier).loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final riderState = ref.watch(riderOrderProvider);
    final authState = ref.watch(authProvider);
    final notifier = ref.read(riderOrderProvider.notifier);

    // Show snackbar on success/error
    ref.listen<RiderOrderState>(riderOrderProvider, (prev, next) {
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.successMessage!),
          backgroundColor: Colors.green,
        ));
        notifier.clearMessages();
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: Colors.red,
        ));
        notifier.clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5F2D82),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rider Dashboard',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Hi, ${authState.user?.name ?? 'Rider'}',
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: riderState.isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: riderState.isRefreshing
                ? null
                : () => notifier.loadOrders(silent: true),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: riderState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
            )
          : RefreshIndicator(
              color: const Color(0xFF5F2D82),
              onRefresh: () => notifier.loadOrders(silent: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Active Order ──────────────────────────────────────
                    if (riderState.hasActiveOrder) ...[
                      _SectionHeader(
                        icon: Icons.directions_bike,
                        title: 'Active Order',
                        color: Colors.green,
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                      _ActiveOrderCard(
                        order: riderState.activeOrder!,
                        isActionInProgress: riderState.isActionInProgress,
                        onMarkPickedUp: () =>
                            notifier.markPickedUp(riderState.activeOrder!.id),
                        onMarkCompleted: () =>
                            notifier.markCompleted(riderState.activeOrder!.id),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                    ],

                    // ── Available Orders ──────────────────────────────────
                    _SectionHeader(
                      icon: Icons.inbox,
                      title: 'Available Orders',
                      color: const Color(0xFF5F2D82),
                      badge: riderState.availableOrders.length,
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 8)),

                    if (riderState.availableOrders.isEmpty)
                      _EmptyAvailable(hasActive: riderState.hasActiveOrder)
                    else
                      ...riderState.availableOrders.map(
                        (order) => Padding(
                          padding: EdgeInsets.only(
                            bottom: ResponsiveUtils.spacing(context, 12),
                          ),
                          child: _AvailableOrderCard(
                            order: order,
                            isAccepting: riderState.action ==
                                    RiderOrderAction.accepting &&
                                riderState.isActionInProgress,
                            hasActiveOrder: riderState.hasActiveOrder,
                            onAccept: () => notifier.acceptOrder(order.id),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final int? badge;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        if (badge != null && badge! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$badge',
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active Order Card
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveOrderCard extends StatelessWidget {
  final OrderDto order;
  final bool isActionInProgress;
  final VoidCallback onMarkPickedUp;
  final VoidCallback onMarkCompleted;

  const _ActiveOrderCard({
    required this.order,
    required this.isActionInProgress,
    required this.onMarkPickedUp,
    required this.onMarkCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isAccepted = order.status == 'accepted';
    final isPickedUp = order.status == 'picked_up';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isPickedUp ? Colors.orange : Colors.green,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(
                  isPickedUp ? Icons.local_shipping : Icons.check_circle,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isPickedUp ? 'On the way to customer' : 'Heading to pickup',
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _AddressRow(
                  icon: Icons.my_location,
                  iconColor: const Color(0xFF5F2D82),
                  label: 'Pickup',
                  address: order.pickupAddress,
                  contact: order.pickupContactName,
                  phone: order.pickupContactPhone,
                ),
                const SizedBox(height: 4),
                _DashedDivider(),
                const SizedBox(height: 4),
                _AddressRow(
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  label: 'Drop-off',
                  address: order.dropoffAddress,
                  contact: order.dropoffContactName,
                  phone: order.dropoffContactPhone,
                ),
                const SizedBox(height: 12),
                _OrderMeta(order: order),
                const SizedBox(height: 16),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isActionInProgress
                        ? null
                        : (isAccepted ? onMarkPickedUp : onMarkCompleted),
                    icon: isActionInProgress
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isAccepted
                                ? Icons.inventory_2_outlined
                                : Icons.check_circle_outline,
                            size: 18,
                          ),
                    label: Text(
                      isAccepted ? 'Mark as Picked Up' : 'Mark as Delivered',
                      style: const TextStyle(
                        fontFamily: 'TT Fors',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isAccepted ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Available Order Card
// ─────────────────────────────────────────────────────────────────────────────

class _AvailableOrderCard extends StatelessWidget {
  final OrderDto order;
  final bool isAccepting;
  final bool hasActiveOrder;
  final VoidCallback onAccept;

  const _AvailableOrderCard({
    required this.order,
    required this.isAccepting,
    required this.hasActiveOrder,
    required this.onAccept,
  });

  String _serviceLabel(int serviceId) {
    switch (serviceId) {
      case 1: return 'LesGo';
      case 2: return 'LesRide';
      case 3: return 'LesEat';
      case 4: return 'LesBuy';
      case 5: return 'LesTransport';
      default: return 'Service #$serviceId';
    }
  }

  Color _serviceColor(int serviceId) {
    switch (serviceId) {
      case 1: return const Color(0xFF5F2D82);
      case 2: return Colors.blue;
      case 3: return Colors.orange;
      case 4: return Colors.teal;
      case 5: return Colors.brown;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final svcColor = _serviceColor(order.serviceId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: svcColor.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: svcColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _serviceLabel(order.serviceId),
                    style: const TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Order #${order.id}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '₱${order.estimatedFare.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: svcColor,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _AddressRow(
                  icon: Icons.my_location,
                  iconColor: const Color(0xFF5F2D82),
                  label: 'Pickup',
                  address: order.pickupAddress,
                ),
                const SizedBox(height: 4),
                _DashedDivider(),
                const SizedBox(height: 4),
                _AddressRow(
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  label: 'Drop-off',
                  address: order.dropoffAddress,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Chip(
                      icon: Icons.straighten,
                      label:
                          '${(order.estimatedDistanceM / 1000).toStringAsFixed(1)} km',
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.payment,
                      label: order.paymentMethod.toUpperCase(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Accept button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isAccepting || hasActiveOrder) ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: svcColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isAccepting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            hasActiveOrder
                                ? 'Complete active order first'
                                : 'Accept Order',
                            style: const TextStyle(
                              fontFamily: 'TT Fors',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;
  final String? contact;
  final String? phone;

  const _AddressRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
    this.contact,
    this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (contact != null && contact!.isNotEmpty)
                Text(
                  '$contact${phone != null && phone!.isNotEmpty ? ' · $phone' : ''}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderMeta extends StatelessWidget {
  final OrderDto order;
  const _OrderMeta({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
          icon: Icons.straighten,
          label: '${(order.estimatedDistanceM / 1000).toStringAsFixed(1)} km',
        ),
        const SizedBox(width: 8),
        _Chip(
          icon: Icons.attach_money,
          label: '₱${order.estimatedFare.toStringAsFixed(0)}',
          color: Colors.green,
        ),
        const SizedBox(width: 8),
        _Chip(
          icon: Icons.payment,
          label: order.paymentMethod.toUpperCase(),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _Chip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Row(
        children: List.generate(
          20,
          (i) => Expanded(
            child: Container(
              height: 1,
              color: i.isEven ? Colors.grey.shade300 : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyAvailable extends StatelessWidget {
  final bool hasActive;
  const _EmptyAvailable({required this.hasActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            hasActive
                ? 'No other orders available'
                : 'No orders available right now',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pull down to refresh',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
