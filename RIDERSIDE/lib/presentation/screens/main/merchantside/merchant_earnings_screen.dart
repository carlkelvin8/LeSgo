import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/utils/merchant_order_amount_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/screen_auto_refresh.dart';
import '../../../mixins/auto_refresh_mixin.dart';
import '../../../provider/main/merchantside/merchant_earnings_provider.dart';
import '../../../provider/main/merchantside/merchant_orders_provider.dart';
import '../../../widgets/main/merchantside/earnings/merchant_earnings_summary_card.dart';

class MerchantEarningsScreen extends ConsumerStatefulWidget {
  const MerchantEarningsScreen({super.key});

  @override
  ConsumerState<MerchantEarningsScreen> createState() =>
      _MerchantEarningsScreenState();
}

class _MerchantEarningsScreenState extends ConsumerState<MerchantEarningsScreen>
    with WidgetsBindingObserver, AutoRefreshMixin {
  @override
  Duration get autoRefreshInterval => kScreenAutoRefreshInterval;

  @override
  void onAutoRefresh() {
    ref.invalidate(merchantOrdersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(merchantEarningsPeriodProvider);
    final summaryAsync = ref.watch(merchantEarningsSummaryProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Restaurant Earnings',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load earnings',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(merchantOrdersProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F2D82),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (summary) {
          return RefreshIndicator(
            color: const Color(0xFF5F2D82),
            onRefresh: () async {
              ref.invalidate(merchantOrdersProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: ResponsiveUtils.spacing(context, 24),
              ),
              children: [
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                MerchantEarningsSummaryCard(
                  totalEarnings: summary.totalEarnings,
                  pendingEarnings: summary.pendingEarnings,
                  completedOrders: summary.completedOrders,
                  pendingOrders: summary.pendingOrders,
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _periodFilters(context, ref, period),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _statsRow(context, summary),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Text(
                    'Completed Orders',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 17),
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                if (summary.completedEntries.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: ResponsiveUtils.spacing(context, 32),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                        Text(
                          'No completed orders for ${period.label.toLowerCase()}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...summary.completedEntries.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        left: horizontalPadding,
                        right: horizontalPadding,
                        bottom: ResponsiveUtils.spacing(context, 12),
                      ),
                      child: _earningOrderTile(context, entry),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _periodFilters(
    BuildContext context,
    WidgetRef ref,
    MerchantEarningsPeriod selected,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MerchantEarningsPeriod.values.map((period) {
          final isSelected = period == selected;
          return Padding(
            padding: EdgeInsets.only(
              right: ResponsiveUtils.spacing(context, 8),
            ),
            child: FilterChip(
              label: Text(
                period.label,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: isSelected ? Colors.white : const Color(0xFF5F2D82),
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: const Color(0xFF5F2D82),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF5F2D82)
                    : Colors.grey.shade300,
              ),
              onSelected: (_) {
                ref.read(merchantEarningsPeriodProvider.notifier).state =
                    period;
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statsRow(BuildContext context, MerchantEarningsSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            label: 'Avg. Order',
            value: formatMerchantPeso(summary.averageOrderValue),
          ),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 12)),
        Expanded(
          child: _statCard(
            context,
            label: 'Completed',
            value: '${summary.completedOrders}',
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 18),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningOrderTile(BuildContext context, MerchantEarningEntry entry) {
    final order = entry.order;
    final itemNames = order.orderItems?.map((item) => item.itemName).join(', ') ??
        'Order Items';
    final dateLabel = entry.date != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(entry.date!)
        : 'Unknown date';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          AppRouter.push(
            context,
            MainRoutes.merchantOrderDetail,
            arguments: order,
          );
        },
        child: Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: ResponsiveUtils.spacing(context, 44),
                height: ResponsiveUtils.spacing(context, 44),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1E8F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.restaurant,
                  color: const Color(0xFF5F2D82),
                  size: ResponsiveUtils.fontSize(context, 22),
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.referenceNumber ?? order.id}',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      itemNames,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 15),
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 11),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatMerchantPeso(entry.amount),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 15),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5F2D82),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
