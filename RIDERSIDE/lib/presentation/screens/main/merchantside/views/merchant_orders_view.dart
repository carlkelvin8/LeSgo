import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_orders_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../../widgets/main/merchantside/orders/merchant_order_dialogs.dart';
import '../merchant_order_detail_screen.dart';

class MerchantOrdersView extends ConsumerStatefulWidget {
  const MerchantOrdersView({super.key});

  @override
  ConsumerState<MerchantOrdersView> createState() => _MerchantOrdersViewState();
}

class _MerchantOrdersViewState extends ConsumerState<MerchantOrdersView> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) ref.invalidate(merchantOrdersProvider);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Accept';
      case 'searching_driver':
      case 'accepted':
      case 'ready_for_pickup':
        return 'For Pick Up';
      case 'picked_up':
      case 'in_progress':
      case 'driver_arrived_at_pickup':
        return 'For Delivery';
      case 'completed':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _getStatusType(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'accept';
      case 'searching_driver':
      case 'accepted':
      case 'ready_for_pickup':
        return 'pickup';
      case 'picked_up':
      case 'in_progress':
      case 'driver_arrived_at_pickup':
        return 'delivery';
      case 'completed':
        return 'delivered';
      default:
        return 'accept';
    }
  }

  Future<void> _handlePendingTap(BuildContext context, int orderId) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Accept Order'),
              onTap: () => Navigator.pop(context, 'accept'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Reject Order'),
              onTap: () => Navigator.pop(context, 'reject'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'accept') {
      final confirm = await showMerchantConfirmDialog(
        context,
        title: 'Accept Order?',
        message: 'This will accept the order and start searching for a driver.',
        confirmLabel: 'Accept',
      );
      if (confirm && mounted) {
        await _runAction(
          () => ref.read(merchantOrderActionProvider).acceptOrder(orderId),
          successMessage: 'Order accepted successfully!',
        );
      }
    } else if (action == 'reject') {
      final reason = await showMerchantCancelReasonDialog(
        context,
        title: 'Reject Order',
        hint: 'Why are you rejecting this order?',
      );
      if (reason != null && mounted) {
        await _runAction(
          () => ref.read(merchantOrderActionProvider).rejectOrder(orderId, reason),
          successMessage: 'Order rejected.',
        );
      }
    }
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updating order...')),
      );
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final filters = ref.watch(merchantOrderFiltersProvider);
    final selectedFilter = ref.watch(selectedMerchantOrderFilterProvider);
    final ordersAsync = ref.watch(merchantOrdersProvider);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: ResponsiveUtils.spacing(context, 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...filters.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      right: ResponsiveUtils.spacing(context, 10),
                    ),
                    child: MerchantOrderFilterChip(
                      label: entry.value.label,
                      isSelected: entry.value == selectedFilter,
                      onTap: () {
                        ref.read(selectedMerchantOrderFilterProvider.notifier).state =
                            entry.value;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 20)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Orders',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 17),
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                'Status',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 14)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(merchantOrdersProvider),
              color: const Color(0xFF5F2D82),
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: ResponsiveUtils.spacing(context, 80)),
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error loading orders: $error'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(merchantOrdersProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                data: (allOrders) {
                  final orders = allOrders.where((order) {
                    final status = order.status.toLowerCase();
                    switch (selectedFilter) {
                      case MerchantOrderFilter.pending:
                        return status == 'pending';
                      case MerchantOrderFilter.pickUp:
                        return status == 'searching_driver' ||
                            status == 'accepted' ||
                            status == 'ready_for_pickup';
                      case MerchantOrderFilter.forDelivery:
                        return status == 'picked_up' ||
                            status == 'in_progress' ||
                            status == 'driver_arrived_at_pickup';
                      case MerchantOrderFilter.delivered:
                        return status == 'completed';
                      case MerchantOrderFilter.all:
                      default:
                        return true;
                    }
                  }).toList();

                  if (orders.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: ResponsiveUtils.spacing(context, 80)),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No orders yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: ResponsiveUtils.spacing(context, 6),
                    ),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final itemNames = order.orderItems
                              ?.map((item) => item.itemName)
                              .join(', ') ??
                          'Order Items';

                      double itemSubtotal = 0;
                      if (order.orderItems != null) {
                        for (var item in order.orderItems!) {
                          itemSubtotal += (item.unitPrice ?? 0.0) * (item.quantity);
                        }
                      }
                      final double deliveryFee =
                          order.estimatedFare ?? order.totalFare ?? order.distanceFare ?? 0.0;
                      final double totalAmount = itemSubtotal + deliveryFee;
                      final status = order.status.toLowerCase();

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveUtils.spacing(context, 18),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MerchantOrderDetailScreen(
                                        order: order,
                                      ),
                                    ),
                                  );
                                },
                                child: MerchantOrderCard(
                                  orderId: '#${order.referenceNumber}',
                                  itemName: itemNames,
                                  price: totalAmount.toStringAsFixed(2),
                                  customerName: order.user?.name ?? 'Customer',
                                  address: order.dropoffAddress,
                                ),
                              ),
                            ),
                            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                            SizedBox(
                              width: ResponsiveUtils.spacing(context, 82),
                              child: GestureDetector(
                                onTap: status == 'pending'
                                    ? () => _handlePendingTap(context, order.id)
                                    : null,
                                child: MerchantOrderStatusPanel(
                                  statusType: _getStatusType(order.status),
                                  statusLabel: _getStatusLabel(order.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
