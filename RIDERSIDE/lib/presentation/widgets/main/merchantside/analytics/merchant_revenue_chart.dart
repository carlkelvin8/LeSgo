import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_analytics_provider.dart';

/// A simple bar chart widget displaying revenue trend data.
/// Uses Column of colored Container bars — no external chart package needed.
class MerchantRevenueChart extends ConsumerWidget {
  const MerchantRevenueChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(merchantAnalyticsSummaryProvider);

    return analyticsAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        if (summary.trend.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue Trend',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 15),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 4)),
              Text(
                'PHP ${summary.totalRevenue.toStringAsFixed(2)} total',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              SizedBox(
                height: 140,
                child: _BarChart(trend: summary.trend),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<MerchantTrendPoint> trend;

  const _BarChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final maxRevenue = trend.fold<double>(
      0,
      (max, point) => point.revenue > max ? point.revenue : max,
    );

    // Only show a subset of bars if there are too many
    final displayTrend = trend.length > 14
        ? _downsample(trend, 14)
        : trend;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: displayTrend.map((point) {
        final barHeight =
            maxRevenue > 0 ? (point.revenue / maxRevenue) * 110 : 0.0;
        final showLabel = point.label.isNotEmpty;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: double.infinity,
                  height: barHeight < 4 && point.revenue > 0 ? 4 : barHeight,
                  decoration: BoxDecoration(
                    color: point.revenue > 0
                        ? const Color(0xFF5F2D82)
                        : Colors.grey.shade200,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                ),
                const SizedBox(height: 4),
                if (showLabel)
                  Text(
                    point.label,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 9),
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  )
                else
                  const SizedBox(height: 12),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<MerchantTrendPoint> _downsample(
    List<MerchantTrendPoint> data,
    int targetCount,
  ) {
    if (data.length <= targetCount) return data;
    final step = data.length / targetCount;
    final result = <MerchantTrendPoint>[];
    for (var i = 0; i < targetCount; i++) {
      result.add(data[(i * step).floor()]);
    }
    return result;
  }
}
