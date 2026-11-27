import 'package:lesgo/presentation/widgets/common/empty_state_view.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import '../../../widgets/common/segmented_filter_bar.dart';
import 'package:lesgo/core/theme/app_tokens.dart';
import '../../../widgets/common/refreshable_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../provider/main/orders/order_history_provider.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/orders/order_card.dart';
import '../../../widgets/orders/order_style.dart';
import '../../../../core/constants/order_status_constants.dart';
import '../../../../core/utils/history_grouping.dart';
import '../../../../core/utils/order_service_labels.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/data_source/dto/order/order_dto.dart';
import 'order_detail_screen.dart';
import '../../../widgets/common/retry_widget.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int? _serviceId; // null = all services

  static const _services = [
    (null, 'All'),
    (2, 'LesRide'),
    (1, 'LesGo'),
    (3, 'LesEat'),
    (4, 'LesBuy'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(orderHistoryProvider.notifier).loadMoreOrders();
    }
  }

  bool get _hasLocalFilters => _query.trim().isNotEmpty || _serviceId != null;

  List<OrderDto> _visible(List<OrderDto> orders) {
    final q = _query.trim().toLowerCase();
    return orders.where((o) {
      if (_serviceId != null && o.serviceId != _serviceId) return false;
      if (q.isEmpty) return true;
      final haystack = [
        '#${o.id}',
        '${o.id}',
        OrderServiceLabels.labelForOrder(o),
        o.pickupAddress,
        o.dropoffAddress,
        OrderStyle.status(o.status).label,
        for (final i in o.effectiveItems) i.name,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  void _clearLocalFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _serviceId = null;
    });
  }

  Future<void> _reorder(OrderDto order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Order again?'),
        content: Text(
          'We’ll place the same ${OrderServiceLabels.labelForOrder(order)} order (#${order.id}) again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Order again'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final placed = await ref
        .read(orderHistoryProvider.notifier)
        .reorder(order.id);
    if (!mounted) return;
    if (placed) {
      SnackBarUtils.showSuccess(context, 'Order placed successfully!');
    } else {
      SnackBarUtils.showError(
        context,
        ref.read(orderHistoryProvider).error ??
            'Could not place the order again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderHistoryProvider);
    final statusFiltered = orderState.filteredOrders;
    final visible = _visible(statusFiltered);

    return Scaffold(
      backgroundColor: AppColors.surface(context, const Color(0xFFF8F7FB)),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.surface(context, Colors.white),
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.spacing(context, 16),
                ResponsiveUtils.spacing(context, 16),
                ResponsiveUtils.spacing(context, 16),
                ResponsiveUtils.spacing(context, 8),
              ),
              child: const Row(
                children: [Expanded(child: AuthHeader(title: 'Order History'))],
              ),
            ),
            Container(
              color: AppColors.surface(context, Colors.white),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search place or item',
                      hintStyle: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: AppColors.foreground(context, Colors.grey[400]!),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.foreground(context, Colors.grey[500]!),
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                      filled: true,
                      fillColor: AppColors.surface(context, Colors.grey[100]!),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Status filter (server side).
                  SegmentedFilterBar<String>(
                    selected: orderState.selectedFilter,
                    onChanged: (v) =>
                        ref.read(orderHistoryProvider.notifier).changeFilter(v),
                    segments: const [
                      FilterSegment('all', 'All'),
                      FilterSegment('active', 'Active'),
                      FilterSegment(
                        OrderStatusConstants.completed,
                        'Completed',
                      ),
                      FilterSegment(
                        OrderStatusConstants.cancelled,
                        'Cancelled',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Service filter (on the orders already loaded).
                  SegmentedFilterBar<int?>(
                    selected: _serviceId,
                    onChanged: (v) => setState(() => _serviceId = v),
                    segments: [
                      for (final s in _services)
                        FilterSegment<int?>(s.$1, s.$2),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: AppColors.border(context, Colors.grey[200]!),
            ),
            Expanded(child: _body(orderState, statusFiltered, visible)),
          ],
        ),
      ),
    );
  }

  Widget _body(
    OrderHistoryState orderState,
    List<OrderDto> statusFiltered,
    List<OrderDto> visible,
  ) {
    if (orderState.isLoading && orderState.orders.isEmpty) {
      return const _SkeletonList();
    }
    if (orderState.error != null && orderState.orders.isEmpty) {
      return RetryWidget(
        message: orderState.error!,
        isLoading: orderState.isLoading,
        onRetry: () => ref.read(orderHistoryProvider.notifier).refreshOrders(),
      );
    }
    if (statusFiltered.isEmpty) {
      return RefreshableEmptyState(
        onRefresh: () =>
            ref.read(orderHistoryProvider.notifier).refreshOrders(),
        child: EmptyStateView(
          icon: Icons.receipt_long_outlined,
          title: orderState.selectedFilter == 'all'
              ? 'No orders yet'
              : 'No ${orderState.selectedFilter} orders',
          message: orderState.selectedFilter == 'all'
              ? 'Your rides, food and deliveries will show up here.'
              : 'Pull down to refresh.',
        ),
      );
    }
    if (visible.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 40),
          EmptyStateView(
            icon: Icons.search_off_rounded,
            title: 'No matching orders',
            message: orderState.hasMore
                ? 'Try another search, or scroll down to load older orders.'
                : 'Try another search or service.',
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(
              onPressed: _clearLocalFilters,
              child: const Text('Clear search & service'),
            ),
          ),
        ],
      );
    }

    final now = DateTime.now();
    final groups = HistoryGrouping.group<OrderDto>(
      visible,
      (o) => HistoryGrouping.parse(o.createdAt ?? o.updatedAt),
      (d) => HistoryGrouping.monthLabel(d, now),
    );

    // Flatten into rows: summary, [month header, cards...]..., load-more.
    final rows = <Object>[
      for (final g in groups) ...[g.label, ...g.items],
      if (orderState.hasMore && !_hasLocalFilters) const _LoadMoreRow(),
    ];

    return RefreshIndicator(
      color: AppColors.accent(context, const Color(0xFF5F2D82)),
      onRefresh: () => ref.read(orderHistoryProvider.notifier).refreshOrders(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row is String) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
              child: Text(
                row.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 11,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w800,
                  color: AppColors.foreground(context, const Color(0xFF8B729C)),
                ),
              ),
            );
          }
          if (row is _LoadMoreRow) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: orderState.isLoadingMore
                    ? CircularProgressIndicator(
                        color: AppColors.accent(
                          context,
                          const Color(0xFF5F2D82),
                        ),
                      )
                    : TextButton(
                        onPressed: () => ref
                            .read(orderHistoryProvider.notifier)
                            .loadMoreOrders(),
                        child: const Text('Load older orders'),
                      ),
              ),
            );
          }
          final order = row as OrderDto;
          return OrderCard(
            order: order,
            onReorder: () => _reorder(order),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: order.id),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadMoreRow {
  const _LoadMoreRow();
}

/// Soft pulsing placeholders while the first page loads.
class _SkeletonList extends StatefulWidget {
  const _SkeletonList();

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppColors.surface(context, Colors.grey[200]!);
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(8),
      ),
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Opacity(
        opacity: 0.55 + 0.45 * _c.value,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: AppCard.decoration(context, radius: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            bar(120, 14),
                            const SizedBox(height: 8),
                            bar(90, 10),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    bar(double.infinity, 12),
                    const SizedBox(height: 8),
                    bar(220, 12),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
