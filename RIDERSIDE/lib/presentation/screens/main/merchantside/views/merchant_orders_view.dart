import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_orders_provider.dart';
import '../../../../widgets/widgets.dart';

class MerchantOrdersView extends ConsumerWidget {
  const MerchantOrdersView({super.key});

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Accept';
      case 'accepted':
        return 'For Pick Up';
      case 'picked_up':
        return 'For Delivery';
      case 'completed':
        return 'Delivered';
      default:
        return status;
    }
  }

  String _getStatusType(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'accept';
      case 'accepted':
        return 'pickup';
      case 'picked_up':
        return 'delivery';
      case 'completed':
        return 'delivered';
      default:
        return 'accept';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading orders: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(merchantOrdersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        const SizedBox(height: 8),
                        Text(
                          selectedFilter != MerchantOrderFilter.all
                              ? 'No ${selectedFilter.label.toLowerCase()} orders'
                              : 'Orders will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 6)),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    
                    // Get item names from order items
                    final itemNames = order.orderItems
                        ?.map((item) => item.itemName)
                        .join(', ') ?? 'Order Items';
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 18)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: MerchantOrderCard(
                              orderId: '#${order.referenceNumber}',
                              itemName: itemNames,
                              price: order.totalFare.toStringAsFixed(2),
                              customerName: order.user?.name ?? 'Customer',
                              address: order.dropoffAddress,
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                          SizedBox(
                            width: ResponsiveUtils.spacing(context, 82),
                            child: MerchantOrderStatusPanel(
                              statusType: _getStatusType(order.status),
                              statusLabel: _getStatusLabel(order.status),
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
        ],
      ),
    );
  }
}
