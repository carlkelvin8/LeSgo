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

    return Material(
      color: const Color(0xFFF5F4F7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => AppRouter.push(context, MainRoutes.merchantAnalytics),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 7)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.insights,
                      color: const Color(0xFF8054A2),
                      size: ResponsiveUtils.fontSize(context, 17),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.north_east_rounded,
                    size: 14,
                    color: Color(0xFFA49BAE),
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
                  color: const Color(0xFF302B36),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 6)),
              Text(
                'Today: $todayOrders orders',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 11),
                  height: 1.4,
                  color: const Color(0xFF918A98),
                ),
              ),
              Text(
                'Week: $weekRevenue · Cancel: $cancelRate',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 11),
                  height: 1.4,
                  color: const Color(0xFF918A98),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
