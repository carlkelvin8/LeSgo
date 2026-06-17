import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/merchant_order_amount_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/screen_auto_refresh.dart';
import '../../../mixins/auto_refresh_mixin.dart';
import '../../../provider/main/merchantside/merchant_analytics_provider.dart';
import '../../../provider/main/merchantside/merchant_orders_provider.dart';
import '../../../widgets/main/merchantside/reviews/merchant_rating_stars_display.dart';

class MerchantAnalyticsScreen extends ConsumerStatefulWidget {
  const MerchantAnalyticsScreen({super.key});

  @override
  ConsumerState<MerchantAnalyticsScreen> createState() =>
      _MerchantAnalyticsScreenState();
}

class _MerchantAnalyticsScreenState extends ConsumerState<MerchantAnalyticsScreen>
    with WidgetsBindingObserver, AutoRefreshMixin {
  @override
  Duration get autoRefreshInterval => kScreenAutoRefreshInterval;

  @override
  void onAutoRefresh() {
    ref.invalidate(merchantOrdersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(merchantAnalyticsPeriodProvider);
    final summaryAsync = ref.watch(merchantAnalyticsSummaryProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Restaurant Analytics',
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
        error: (error, _) => _errorState(context, ref, error, horizontalPadding),
        data: (summary) => RefreshIndicator(
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
              _summaryHero(context, summary, horizontalPadding),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: _periodFilters(context, ref, period),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              _sectionCard(
                context,
                horizontalPadding,
                title: 'Order Volume',
                subtitle: _trendSubtitle(period),
                child: _ordersTrendChart(context, summary.trend),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: _miniMetric(
                        context,
                        label: 'Completed',
                        value: '${summary.completedOrders}',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 10)),
                    Expanded(
                      child: _miniMetric(
                        context,
                        label: 'Cancelled',
                        value: '${summary.cancelledOrders}',
                        icon: Icons.cancel_outlined,
                        color: const Color(0xFFC62828),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 10)),
                    Expanded(
                      child: _miniMetric(
                        context,
                        label: 'In Progress',
                        value: '${summary.activeOrders}',
                        icon: Icons.hourglass_top_outlined,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              _sectionCard(
                context,
                horizontalPadding,
                title: 'Peak Hours',
                subtitle: 'Busiest times for completed orders',
                child: summary.peakHours.isEmpty
                    ? _emptyHint(context, 'No completed orders in this period')
                    : Column(
                        children: summary.peakHours.map((peak) {
                          final maxCount = summary.peakHours.first.orderCount;
                          final fraction = maxCount > 0
                              ? peak.orderCount / maxCount
                              : 0.0;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: ResponsiveUtils.spacing(context, 10),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: ResponsiveUtils.spacing(context, 52),
                                  child: Text(
                                    peak.displayLabel,
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize:
                                          ResponsiveUtils.fontSize(context, 13),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: fraction,
                                      minHeight: 10,
                                      backgroundColor: const Color(0xFFE8D9F5),
                                      color: const Color(0xFF5F2D82),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: ResponsiveUtils.spacing(context, 36),
                                  child: Text(
                                    '${peak.orderCount}',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize:
                                          ResponsiveUtils.fontSize(context, 12),
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              _sectionCard(
                context,
                horizontalPadding,
                title: 'Top Menu Items',
                subtitle: 'By quantity sold (completed orders)',
                child: summary.topItems.isEmpty
                    ? _emptyHint(context, 'No item sales in this period')
                    : Column(
                        children: summary.topItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: ResponsiveUtils.spacing(context, 12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: ResponsiveUtils.spacing(context, 28),
                                  height: ResponsiveUtils.spacing(context, 28),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3EAFF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize:
                                          ResponsiveUtils.fontSize(context, 12),
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF5F2D82),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width: ResponsiveUtils.spacing(context, 10)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'TT Fors',
                                          fontSize: ResponsiveUtils.fontSize(
                                              context, 14),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${item.quantitySold} sold · ${formatMerchantPeso(item.revenue)}',
                                        style: TextStyle(
                                          fontFamily: 'TT Fors',
                                          fontSize: ResponsiveUtils.fontSize(
                                              context, 12),
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              _sectionCard(
                context,
                horizontalPadding,
                title: 'Customer Satisfaction',
                subtitle: 'Based on customer reviews',
                child: Row(
                  children: [
                    MerchantRatingStarsDisplay(
                      rating: summary.averageRating,
                      size: ResponsiveUtils.fontSize(context, 20),
                      showRatingText: true,
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                    Text(
                      '${summary.totalReviews} reviews',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 13),
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              _customerAnalyticsSection(context, summary, horizontalPadding),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              _productAnalyticsSection(context, summary, horizontalPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorState(
    BuildContext context,
    WidgetRef ref,
    Object error,
    double horizontalPadding,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load analytics',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 16),
                fontWeight: FontWeight.w700,
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
              onPressed: () => ref.invalidate(merchantOrdersProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryHero(
    BuildContext context,
    MerchantAnalyticsSummary summary,
    double horizontalPadding,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5F2D82), Color(0xFF8E44AD)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5F2D82).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            Text(
              formatMerchantPeso(summary.totalRevenue),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 30),
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 14)),
            Row(
              children: [
                Expanded(
                  child: _heroMetric(
                    context,
                    'Orders',
                    '${summary.totalOrders}',
                  ),
                ),
                Expanded(
                  child: _heroMetric(
                    context,
                    'Avg. Order',
                    formatMerchantPeso(summary.averageOrderValue),
                  ),
                ),
                Expanded(
                  child: _heroMetric(
                    context,
                    'Cancel Rate',
                    '${summary.cancellationRate.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroMetric(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 11),
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 15),
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _periodFilters(
    BuildContext context,
    WidgetRef ref,
    MerchantEarningsPeriod period,
  ) {
    return Wrap(
      spacing: ResponsiveUtils.spacing(context, 8),
      runSpacing: ResponsiveUtils.spacing(context, 8),
      children: MerchantEarningsPeriod.values.map((value) {
        final selected = value == period;
        return FilterChip(
          label: Text(
            value.label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
          selected: selected,
          showCheckmark: false,
          selectedColor: const Color(0xFF5F2D82),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: selected ? const Color(0xFF5F2D82) : Colors.grey.shade300,
          ),
          onSelected: (_) {
            ref.read(merchantAnalyticsPeriodProvider.notifier).state = value;
          },
        );
      }).toList(),
    );
  }

  Widget _sectionCard(
    BuildContext context,
    double horizontalPadding, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 16),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 4)),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12),
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 14)),
            child,
          ],
        ),
      ),
    );
  }

  Widget _miniMetric(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: ResponsiveUtils.fontSize(context, 20)),
          SizedBox(height: ResponsiveUtils.spacing(context, 6)),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 18),
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 11),
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(BuildContext context, String message) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.spacing(context, 8),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 13),
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  String _trendSubtitle(MerchantEarningsPeriod period) {
    switch (period) {
      case MerchantEarningsPeriod.today:
        return 'Orders placed today by hour';
      case MerchantEarningsPeriod.week:
        return 'Orders in the last 7 days';
      case MerchantEarningsPeriod.month:
        return 'Orders this month by day';
      case MerchantEarningsPeriod.all:
        return 'Orders in the last 30 days';
    }
  }

  Widget _ordersTrendChart(
    BuildContext context,
    List<MerchantTrendPoint> trend,
  ) {
    if (trend.every((point) => point.orderCount == 0)) {
      return _emptyHint(context, 'No orders in this period');
    }

    final maxOrders = trend
        .map((point) => point.orderCount)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final maxY = maxOrders <= 0 ? 1.0 : maxOrders * 1.2;

    return SizedBox(
      height: ResponsiveUtils.spacing(context, 180),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final point = trend[group.x.toInt()];
                return BarTooltipItem(
                  '${point.orderCount} orders\n${formatMerchantPeso(point.revenue)}',
                  TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 11),
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= trend.length) {
                    return const SizedBox.shrink();
                  }
                  final label = trend[index].label;
                  if (label.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 9),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(trend.length, (index) {
            final count = trend[index].orderCount.toDouble();
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: count,
                  width: trend.length > 20 ? 6 : 12,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF9B59B6), Color(0xFF5F2D82)],
                  ),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _customerAnalyticsSection(
    BuildContext context,
    MerchantAnalyticsSummary summary,
    double horizontalPadding,
  ) {
    return _sectionCard(
      context,
      horizontalPadding,
      title: 'Customer Analytics',
      subtitle: 'New vs returning, top spenders, and lifetime value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _newVsReturningRow(context, summary),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          if (summary.topCustomers.isNotEmpty) ...[
            Text(
              'Top Customers',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            ...summary.topCustomers.asMap().entries.map((entry) {
              final index = entry.key;
              final customer = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: ResponsiveUtils.spacing(context, 8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EAFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 11),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5F2D82),
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 13),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${customer.orderCount} order${customer.orderCount == 1 ? '' : 's'} · ${formatMerchantPeso(customer.totalSpent)}',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 11),
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Row(
            children: [
              Expanded(
                child: _miniMetric(
                  context,
                  label: 'Avg Order Value',
                  value: formatMerchantPeso(summary.averageOrderValue),
                  icon: Icons.shopping_cart_outlined,
                  color: const Color(0xFF5F2D82),
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 10)),
              Expanded(
                child: _miniMetric(
                  context,
                  label: 'Avg Lifetime Value',
                  value: formatMerchantPeso(summary.avgCustomerLifetimeValue),
                  icon: Icons.trending_up,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _newVsReturningRow(
    BuildContext context,
    MerchantAnalyticsSummary summary,
  ) {
    final total = summary.newCustomerCount + summary.returningCustomerCount;
    if (total == 0) return _emptyHint(context, 'No customer data in this period');

    final newFraction = summary.newCustomerCount / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New vs Returning',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 10)),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 24,
            child: Row(
              children: [
                Expanded(
                  flex: summary.newCustomerCount,
                  child: Container(
                    color: const Color(0xFF5F2D82),
                    alignment: Alignment.center,
                    child: summary.newCustomerCount > 0
                        ? Text(
                            'New ${summary.newCustomerCount}',
                            style: const TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                Expanded(
                  flex: summary.returningCustomerCount,
                  child: Container(
                    color: const Color(0xFF9B59B6),
                    alignment: Alignment.center,
                    child: summary.returningCustomerCount > 0
                        ? Text(
                            'Returning ${summary.returningCustomerCount}',
                            style: const TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 6)),
        Row(
          children: [
            _dotLegend(context, 'New', const Color(0xFF5F2D82)),
            SizedBox(width: ResponsiveUtils.spacing(context, 16)),
            _dotLegend(context, 'Returning', const Color(0xFF9B59B6)),
            const Spacer(),
            Text(
              '${(newFraction * 100).toStringAsFixed(0)}% new',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 11),
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dotLegend(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 6)),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _productAnalyticsSection(
    BuildContext context,
    MerchantAnalyticsSummary summary,
    double horizontalPadding,
  ) {
    return _sectionCard(
      context,
      horizontalPadding,
      title: 'Product Analytics',
      subtitle: 'Best & least sellers, category performance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.leastSoldItems.isNotEmpty) ...[
            Text(
              'Least-Selling Items',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                fontWeight: FontWeight.w700,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            ...summary.leastSoldItems.map((item) => Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveUtils.spacing(context, 8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.arrow_downward,
                      size: 14, color: Colors.red.shade400),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 13),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${item.quantitySold} sold · ${formatMerchantPeso(item.revenue)}',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 11),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          ],
          if (summary.categoryPerformance.isNotEmpty) ...[
            Text(
              'Category Performance',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            ...summary.categoryPerformance.map((cat) {
              final maxRev = summary.categoryPerformance.first.revenue;
              final fraction = maxRev > 0 ? cat.revenue / maxRev : 0.0;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: ResponsiveUtils.spacing(context, 10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat.categoryName,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 13),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${formatMerchantPeso(cat.revenue)} · ${cat.itemCount} items',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 11),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE8D9F5),
                        color: const Color(0xFF5F2D82),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (summary.categoryPerformance.isEmpty &&
              summary.leastSoldItems.isEmpty)
            _emptyHint(context, 'No product data in this period'),
        ],
      ),
    );
  }
}
