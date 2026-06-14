import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/merchant_order_ops_utils.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../data/data_source/dto/merchant/order_dto.dart';
import '../../../../provider/main/merchantside/merchant_menu_image_lookup.dart';
import '../../../../provider/main/merchantside/merchant_menu_provider.dart';
import '../../../../provider/main/merchantside/merchant_orders_provider.dart';
import '../../../../provider/main/merchantside/merchant_prep_timer_provider.dart';
import '../../../../widgets/main/merchantside/orders/merchant_prep_timer_badge.dart';
import '../../../../widgets/widgets.dart';
import '../../../../widgets/main/merchantside/orders/merchant_order_action_handlers.dart';
import '../merchant_order_detail_screen.dart';

class MerchantOrdersView extends ConsumerStatefulWidget {
  const MerchantOrdersView({super.key});

  @override
  ConsumerState<MerchantOrdersView> createState() => _MerchantOrdersViewState();
}

class _MerchantOrdersViewState extends ConsumerState<MerchantOrdersView> {
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

  String? _instructionsPreview(OrderDto order) {
    final orderNote = MerchantOrderOpsUtils.orderSpecialInstructions(order);
    if (orderNote != null) return orderNote;

    final itemNotes = MerchantOrderOpsUtils.itemSpecialInstructions(order);
    if (itemNotes.isNotEmpty) return itemNotes.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final filters = ref.watch(merchantOrderFiltersProvider);
    final selectedFilter = ref.watch(selectedMerchantOrderFilterProvider);
    final ordersAsync = ref.watch(merchantOrdersProvider);
    ref.watch(merchantMenuProvider);
    final imageLookup = ref.watch(menuItemImageLookupProvider);
    final prepTimers = ref.watch(merchantPrepTimerProvider);

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
                      String? firstItemImage;
                      if (order.orderItems != null) {
                        for (final item in order.orderItems!) {
                          final resolved = imageLookup.resolve(item);
                          if (resolved != null && resolved.isNotEmpty) {
                            firstItemImage = resolved;
                            break;
                          }
                        }
                      }

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
                                  orderId: '#${order.referenceNumber ?? order.id}',
                                  itemName: itemNames,
                                  price: totalAmount.toStringAsFixed(2),
                                  customerName: order.user?.name ?? 'Customer',
                                  address: order.dropoffAddress,
                                  imageUrl: firstItemImage,
                                  specialInstructionsPreview:
                                      _instructionsPreview(order),
                                ),
                              ),
                            ),
                            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                            SizedBox(
                              width: ResponsiveUtils.spacing(context, 96),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: MerchantOrderOpsUtils.canAccept(status)
                                        ? () => MerchantOrderActionHandlers.accept(
                                              context,
                                              ref,
                                              orderId: order.id,
                                            )
                                        : null,
                                    onLongPress: MerchantOrderOpsUtils.canReject(status) ||
                                            MerchantOrderOpsUtils.canCancelAfterAccept(status)
                                        ? () => MerchantOrderActionHandlers.handleStatusLongPress(
                                              context,
                                              ref,
                                              status: status,
                                              orderId: order.id,
                                            )
                                        : null,
                                    child: MerchantOrderStatusPanel(
                                      statusType: _getStatusType(order.status),
                                      statusLabel: _getStatusLabel(order.status),
                                    ),
                                  ),
                                  if (MerchantOrderOpsUtils.canReject(status) ||
                                      MerchantOrderOpsUtils.canCancelAfterAccept(status)) ...[
                                    SizedBox(
                                      height: ResponsiveUtils.spacing(context, 6),
                                    ),
                                    if (MerchantOrderOpsUtils.canReject(status))
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              MerchantOrderActionHandlers.reject(
                                            context,
                                            ref,
                                            orderId: order.id,
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFFE53935),
                                            side: const BorderSide(
                                              color: Color(0xFFE53935),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: ResponsiveUtils.spacing(
                                                context,
                                                4,
                                              ),
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            'Reject',
                                            style: TextStyle(
                                              fontFamily: 'TT Fors',
                                              fontSize: ResponsiveUtils.fontSize(
                                                context,
                                                9,
                                              ),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (MerchantOrderOpsUtils
                                        .canCancelAfterAccept(status))
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: MerchantOrderOpsUtils.canReject(
                                                  status)
                                              ? ResponsiveUtils.spacing(
                                                  context,
                                                  4,
                                                )
                                              : 0,
                                        ),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                MerchantOrderActionHandlers
                                                    .cancelAfterAccept(
                                              context,
                                              ref,
                                              orderId: order.id,
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  const Color(0xFFE53935),
                                              side: const BorderSide(
                                                color: Color(0xFFE53935),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical: ResponsiveUtils.spacing(
                                                  context,
                                                  4,
                                                ),
                                              ),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize
                                                  .shrinkWrap,
                                            ),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                fontFamily: 'TT Fors',
                                                fontSize:
                                                    ResponsiveUtils.fontSize(
                                                  context,
                                                  9,
                                                ),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                  if (MerchantOrderOpsUtils.showsPrepTimer(status) &&
                                      prepTimers[order.id] != null) ...[
                                    SizedBox(
                                      height: ResponsiveUtils.spacing(context, 6),
                                    ),
                                    MerchantPrepTimerBadge(
                                      timer: prepTimers[order.id],
                                      compact: true,
                                    ),
                                  ],
                                ],
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
