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
      data: (summary) =>
          summary.cancellationRate > 0
              ? '${summary.cancellationRate.toStringAsFixed(1)}%'
              : '0%',
      orElse: () => '...',
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveUtils.spacing(context, 44),
            height: ResponsiveUtils.spacing(context, 44),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.insights_outlined,
              color: Colors.white,
              size: ResponsiveUtils.fontSize(context, 24),
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restaurant Analytics',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 15),
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  'Today: $todayOrders orders',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  'This Week: $weekRevenue · Cancel rate: $cancelRate',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              AppRouter.push(context, MainRoutes.merchantAnalytics);
            },
            child: Text(
              'View',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5F2D82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
