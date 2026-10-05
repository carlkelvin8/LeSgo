import 'package:lesgo/core/theme/app_colors.dart';
import '../../../widgets/common/refreshable_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../provider/main/orders/order_history_provider.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/orders/order_card.dart';
import '../../../../core/constants/order_status_constants.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'order_detail_screen.dart';
import '../../../widgets/common/retry_widget.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(orderHistoryProvider.notifier).loadMoreOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderHistoryProvider);
    final filteredOrders = orderState.filteredOrders;

    return Scaffold(
      backgroundColor: AppColors.surface(context, Colors.grey[50]!),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.surface(context, Colors.white),
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: Row(
                children: [
                  const AuthHeader(title: 'Order History'),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.surface(context, Colors.grey[300]!)),
            Container(
              color: AppColors.surface(context, Colors.white),
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
                      isSelected:
                          orderState.selectedFilter ==
                          OrderStatusConstants.completed,
                      onTap: () => ref
                          .read(orderHistoryProvider.notifier)
                          .changeFilter(OrderStatusConstants.completed),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Cancelled',
                      isSelected:
                          orderState.selectedFilter ==
                          OrderStatusConstants.cancelled,
                      onTap: () => ref
                          .read(orderHistoryProvider.notifier)
                          .changeFilter(OrderStatusConstants.cancelled),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: AppColors.surface(context, Colors.grey[200]!)),
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
                  ? RefreshableEmptyState(
                      onRefresh: () => ref
                          .read(orderHistoryProvider.notifier)
                          .refreshOrders(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AppColors.foreground(context, Colors.grey[400]!),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ${orderState.selectedFilter} orders',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 16,
                              color: AppColors.foreground(context, Colors.grey[600]!),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pull down to refresh',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 13,
                              color: AppColors.foreground(context, Colors.grey[400]!),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.accent(context, Color(0xFF5F2D82)),
                      onRefresh: () => ref
                          .read(orderHistoryProvider.notifier)
                          .refreshOrders(),
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            filteredOrders.length +
                            (orderState.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= filteredOrders.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: orderState.isLoadingMore
                                    ? const CircularProgressIndicator(
                                        color: Color(0xFF5F2D82),
                                      )
                                    : TextButton(
                                        onPressed: () => ref
                                            .read(orderHistoryProvider.notifier)
                                            .loadMoreOrders(),
                                        child: const Text('Load more'),
                                      ),
                              ),
                            );
                          }

                          final order = filteredOrders[index];
                          return OrderCard(
                            order: order,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OrderDetailScreen(orderId: order.id),
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
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 40),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent(context, Color(0xFF5F2D82)) : AppColors.surface(context, Colors.grey[100]!),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent(context, Color(0xFF5F2D82)) : AppColors.border(context, Colors.grey[300]!),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppColors.foreground(context, Colors.grey[700]!),
          ),
        ),
      ),
    );
  }
}
