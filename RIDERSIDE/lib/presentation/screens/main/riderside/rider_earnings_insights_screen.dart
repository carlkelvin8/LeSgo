import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../widgets/main/riderside/earnings/earnings_design.dart';
import '../../../widgets/main/riderside/profile/profile_panel.dart';

import '../../../../core/utils/receipt_generator.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/share_utils.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../provider/main/riderside/rider_earnings_insights_provider.dart';

class RiderEarningsInsightsScreen extends ConsumerWidget {
  const RiderEarningsInsightsScreen({super.key, this.embedded = false});
  final bool? embedded;

  static void shareReport(
    BuildContext context,
    RiderEarningsInsightsState state,
  ) {
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
      backgroundColor: earningsCanvas(context),
      appBar: embedded == true
          ? null
          : AppBar(
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
                        () => shareReport(context, state),
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
              _buildTotalCard(context, state),
              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
              _buildMetricsGrid(context, state),
              const SizedBox(height: 16),
              _buildChart(context, state),
              const SizedBox(height: 16),
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
    return EarningsBalanceCard(
      title: 'Earnings · Last 30 days',
      total: state.totalEarnings,
      trips: state.totalTrips,
      average: state.averageEarningsPerTrip,
      compact: true,
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

    if (maxY <= 0) {
      return EarningsPanel(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: profileDark(context)
                    ? const Color(0xFF33263F)
                    : const Color(0xFFF4EFF9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.insights_rounded,
                size: 22,
                color: Color(0xFF9562B9),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last 7 Days',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: profileText(context),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'No earnings recorded yet. Your completed trips will build this chart.',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 12,
                      height: 1.5,
                      color: profileMuted(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return EarningsPanel(
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
          const SizedBox(height: 6),
          Text(
            'Daily net earnings',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 12,
              color: profileMuted(context),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
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
                              color: profileMuted(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 64,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'PHP ${NumberFormat.compact().format(value)}',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 10,
                            color: profileMuted(context),
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
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: profileDark(context)
                        ? const Color(0xFF393044)
                        : const Color(0xFFF0ECF5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(displayData.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: displayData[i].earnings,
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF5F2D82), Color(0xFFA67BC8)],
                        ),
                        width: 18,
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
    final metrics = [
      _MetricCard(
        icon: Icons.schedule_outlined,
        label: 'Hours on duty',
        value: state.totalHoursOnline.toStringAsFixed(1),
        unit: 'hours recorded',
      ),
      _MetricCard(
        icon: Icons.payments_outlined,
        label: 'Average / hour',
        value: state.hasRecordedDutyTime
            ? 'PHP ${state.averageEarningsPerHour.toStringAsFixed(2)}'
            : '—',
        unit: state.hasRecordedDutyTime
            ? 'Per duty hour'
            : 'No recorded duty time',
      ),
      _MetricCard(
        icon: Icons.trending_up_rounded,
        label: 'Average / day',
        value: 'PHP ${state.averageEarningsPerDay.toStringAsFixed(2)}',
        unit: 'Last 30 days',
      ),
      _MetricCard(
        icon: Icons.wb_sunny_outlined,
        label: 'Best day',
        value: state.totalTrips == 0 ? '—' : state.bestDay,
        unit: state.totalTrips == 0
            ? 'Complete a trip to start'
            : state.bestHourRange,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Key Metrics',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: profileText(context),
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final single =
                constraints.maxWidth < 290 ||
                MediaQuery.textScalerOf(context).scale(14) > 20;
            return Column(
              children: [
                for (var i = 0; i < metrics.length; i += single ? 1 : 2) ...[
                  if (i > 0) const SizedBox(height: 12),
                  if (single)
                    metrics[i]
                  else
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: metrics[i]),
                          const SizedBox(width: 12),
                          Expanded(child: metrics[i + 1]),
                        ],
                      ),
                    ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Duty hours are recorded from on-duty to off-duty. Earlier untracked time is excluded.',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 11,
            height: 1.6,
            color: profileMuted(context),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectionCard(
    BuildContext context,
    RiderEarningsInsightsState state,
  ) {
    final positive = state.percentageChange >= 0;
    final hasHistory = state.totalTrips > 0 || state.previousPeriodEarnings > 0;
    final accent = profileDark(context)
        ? const Color(0xFFCFACED)
        : const Color(0xFF5F2D82);
    return EarningsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, size: 20, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Looking ahead',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: profileText(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Projected Next 7 Days',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 12,
              color: profileMuted(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'PHP ${state.projectedEarnings.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 26,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (hasHistory)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (positive ? Colors.green : Colors.red).withValues(
                      alpha: .08,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${positive ? '+' : ''}${state.percentageChange.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: positive
                          ? const Color(0xFF27835B)
                          : const Color(0xFFBD4357),
                    ),
                  ),
                ),
              Text(
                hasHistory
                    ? 'vs previous period'
                    : 'More trips will build your forecast',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 12,
                  color: profileMuted(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Previous period: PHP ${state.previousPeriodEarnings.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 11,
              height: 1.5,
              color: profileMuted(context),
            ),
          ),
        ],
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
    final accent = profileDark(context)
        ? const Color(0xFFCFACED)
        : const Color(0xFF5F2D82);
    return EarningsPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 17, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 11,
                    height: 1.4,
                    color: profileMuted(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: profileText(context),
            ),
          ),
          if (unit.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              unit,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 11,
                height: 1.5,
                color: profileMuted(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
