import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/merchant_format_utils.dart';
import '../../../../provider/main/merchantside/merchant_analytics_provider.dart';

class MerchantAnalyticsPreviewCard extends ConsumerWidget {
  const MerchantAnalyticsPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayOrdersAsync = ref.watch(merchantTodayOrderCountProvider);
    final summaryAsync = ref.watch(merchantWeekAnalyticsPreviewProvider);

    final todayOrders = todayOrdersAsync.when(
      loading: () => '...',
      error: (_, __) => '0',
      data: (count) => '$count',
    );

    final weekRevenue = summaryAsync.maybeWhen(
      data: (summary) => formatMerchantPeso(summary.totalRevenue),
      orElse: () => '...',
    );

    final cancelRate = summaryAsync.maybeWhen(
      data: (summary) => summary.cancellationRate > 0
          ? '${summary.cancellationRate.toStringAsFixed(1)}%'
          : '0%',
      orElse: () => '...',
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => AppRouter.push(context, MainRoutes.merchantAnalytics),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6D318F), Color(0xFF4A1D68)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        ResponsiveUtils.spacing(context, 7),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.insights,
                        color: Colors.white,
                        size: ResponsiveUtils.fontSize(context, 17),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.north_east_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: .75),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                Text(
                  'Business Overview',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                Row(
                  children: [
                    _Metric(label: 'Today', value: todayOrders),
                    _Metric(label: 'This week', value: weekRevenue),
                    _Metric(label: 'Cancelled', value: cancelRate),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 10,
              color: Colors.white.withValues(alpha: .72),
            ),
          ),
        ],
      ),
    );
  }
}
