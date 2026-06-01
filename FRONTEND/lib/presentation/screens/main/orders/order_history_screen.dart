import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../provider/main/orders/order_history_provider.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/orders/order_card.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'order_detail_screen.dart';
import '../../../widgets/common/retry_widget.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderHistoryProvider);
    final filteredOrders = orderState.filteredOrders;

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
                    child: AuthHeader(title: 'Order History'),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: Colors.grey[300]),

            // Filter tabs
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: orderState.selectedFilter == 'all',
                      onTap: () => ref
                          .read(orderHistoryProvider.notifier)
                          .changeFilter('all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Active',
                      isSelected: orderState.selectedFilter == 'active',
                      onTap: () => ref
                          .read(orderHistoryProvider.notifier)
                          .changeFilter('active'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Completed',
                      isSelected: orderState.selectedFilter == 'completed',
                      onTap: () => ref
                          .read(orderHistoryProvider.notifier)
                          .changeFilter('completed'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Cancelled',
                      isSelected: orderState.selectedFilter == 'cancelled',
                      onTap: () => ref
                          .read(orderHistoryProvider.notifier)
                          .changeFilter('cancelled'),
                    ),
                  ],
                ),
              ),
            ),

            Container(height: 1, color: Colors.grey[200]),

            // Orders list
            Expanded(
              child: orderState.isLoading && orderState.orders.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5F2D82),
                      ),
                    )
                  : orderState.error != null && orderState.orders.isEmpty
                      ? RetryWidget(
                          message: orderState.error!,
                          isLoading: orderState.isLoading,
                          onRetry: () => ref
                              .read(orderHistoryProvider.notifier)
                              .refreshOrders(),
                        )
                      : filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No ${orderState.selectedFilter} orders',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pull down to refresh',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 13,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF5F2D82),
                          onRefresh: () => ref
                              .read(orderHistoryProvider.notifier)
                              .refreshOrders(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              return OrderCard(
                                order: order,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderDetailScreen(
                                        orderId: order.id,
                                      ),
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
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5F2D82) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF5F2D82) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
