import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../widgets/main/riderside/earnings/rider_earnings_light_card.dart';

import '../../../../core/utils/receipt_generator.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/share_utils.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../provider/main/riderside/rider_earnings_insights_provider.dart';

class RiderEarningsInsightsScreen extends ConsumerWidget {
  const RiderEarningsInsightsScreen({super.key});

  void _shareReport(BuildContext context, RiderEarningsInsightsState state) {
    final entries = state.dailyEarnings
        .map(
          (d) => {
            'order_id': '-',
            'service_name': 'Daily Earnings',
            'earnings': d.earnings,
            'completed_at': d.date,
          },
        )
        .toList();

    final receipt = ReceiptGenerator.generateEarningSummaryReceipt(
      period: 'Last 30 Days',
      totalEarnings: state.totalEarnings,
      completedTrips: state.totalTrips,
      averagePerTrip: state.averageEarningsPerTrip,
      entries: entries,
    );

    ShareUtils.saveAndShareReceipt(
      context,
      receipt,
      'LeSGo_Earnings_Insights_Report',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(riderEarningsInsightsProvider);
    final lang = ref.watch(appLanguageProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F2D82)),
        title: Text(
          AppLocalization.translate('earnings_insights', lang),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: insightsAsync.maybeWhen(
              data: (state) =>
                  () => _shareReport(context, state),
              orElse: () => null,
            ),
            tooltip: 'Download/Share Report',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF5F2D82),
        onRefresh: () async {
          ref.invalidate(riderEarningsInsightsProvider);
          await ref.read(riderEarningsInsightsProvider.future);
        },
        child: insightsAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(hp),
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Could not load earnings insights',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$error',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(riderEarningsInsightsProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (state) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              hp,
              ResponsiveUtils.spacing(context, 16),
              hp,
              ResponsiveUtils.scrollBottomPaddingForBottomNav(context),
            ),
            children: [
              if (state.totalTrips == 0 && state.totalEarnings == 0)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveUtils.spacing(context, 16),
                  ),
                  child: Text(
                    'No completed trips in the last 30 days yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              _buildTotalCard(context, state),
              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
              _buildChart(context, state),
              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
              _buildMetricsGrid(context, state),
              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
              _buildProjectionCard(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(
    BuildContext context,
    RiderEarningsInsightsState state,
  ) {
    return RiderEarningsLightCard(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings · Last 30 days',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              'PHP ${state.totalEarnings.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 32),
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(label: '${state.totalTrips} trips'),
                _StatChip(
                  label:
                      'Avg PHP ${state.averageEarningsPerTrip.toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, RiderEarningsInsightsState state) {
    final displayData = state.dailyEarnings.length >= 7
        ? state.dailyEarnings.sublist(state.dailyEarnings.length - 7)
        : state.dailyEarnings;
    final maxY = displayData.fold<double>(
      0,
      (max, d) => d.earnings > max ? d.earnings : max,
    );
    final ceiling = maxY <= 0 ? 200.0 : ((maxY / 200).ceil() * 200).toDouble();

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
            'Last 7 Days',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: ceiling,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final d = displayData[groupIndex];
                      return BarTooltipItem(
                        '${DateFormat('MMM d').format(d.date)}\nPHP ${d.earnings.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= displayData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('E').format(displayData[idx].date),
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'PHP ${value.toInt()}',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ceiling / 4,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(displayData.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: displayData[i].earnings,
                        color: const Color(0xFF5F2D82),
                        width: 24,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context,
    RiderEarningsInsightsState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Duty hours are recorded from on-duty to off-duty. Earlier untracked time is excluded.',
          style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF766B7F)),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.timer_outlined,
                label: 'Hours on duty',
                value: state.totalHoursOnline.toStringAsFixed(1),
                unit: 'hrs',
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),
            Expanded(
              child: _MetricCard(
                icon: Icons.attach_money,
                label: 'Avg / Hour',
                value: state.hasRecordedDutyTime
                    ? 'PHP ${state.averageEarningsPerHour.toStringAsFixed(2)}'
                    : '—',
                unit: state.hasRecordedDutyTime ? '' : 'No recorded duty time',
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.trending_up,
                label: 'Avg / Day',
                value: 'PHP ${state.averageEarningsPerDay.toStringAsFixed(2)}',
                unit: '',
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),
            Expanded(
              child: _MetricCard(
                icon: Icons.star,
                label: 'Best Day',
                value: state.bestDay,
                unit: state.bestHourRange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectionCard(
    BuildContext context,
    RiderEarningsInsightsState state,
  ) {
    final isPositive = state.percentageChange >= 0;

    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Projections & Comparison',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Projected Next 7 Days',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    Text(
                      'PHP ${state.projectedEarnings.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 20),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF5F2D82),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'vs Previous Period',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    Row(
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: isPositive ? Colors.green : Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isPositive ? '+' : ''}${state.percentageChange.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 20),
                            fontWeight: FontWeight.w800,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Text(
            'Previous period: PHP ${state.previousPeriodEarnings.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;

  const _StatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF5F2D82), size: 22),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 11),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
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
}
