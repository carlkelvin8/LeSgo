import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
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
      child: InkWell(
        onTap: () => AppRouter.push(context, MainRoutes.merchantAnalytics),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Business performance',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF332A3B),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Color(0xFF8B739D),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Revenue this week',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 11,
                  color: Color(0xFF8A8292),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                weekRevenue,
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 29,
                  height: 1.1,
                  letterSpacing: -.8,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5F2D82),
                ),
              ),
              const Divider(height: 30, color: Color(0xFFF0ECF3)),
              Row(
                children: [
                  _Metric(label: 'Orders today', value: todayOrders),
                  Container(
                    width: 1,
                    height: 32,
                    color: const Color(0xFFEDE7F2),
                  ),
                  const SizedBox(width: 20),
                  _Metric(label: 'Cancellation rate', value: cancelRate),
                ],
              ),
            ],
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
              color: Color(0xFF332A3B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 10,
              color: const Color(0xFF8A8292),
            ),
          ),
        ],
      ),
    );
  }
}
