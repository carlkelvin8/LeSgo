import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_analytics_provider.dart';

/// Compact revenue trend card with a hand-drawn line chart so the dashboard
/// stays lightweight and does not depend on a chart package.
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

        final hasRevenue = summary.trend.any((point) => point.revenue > 0);
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Revenue trend',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF24172D),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EAF7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'This week',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6D3EA0),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  'PHP ${summary.totalRevenue.toStringAsFixed(2)} total',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 10.5),
                    color: const Color(0xFF918A98),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                SizedBox(
                  height: 142,
                  child: Stack(
                    children: [
                      _RevenueLineChart(trend: summary.trend),
                      if (!hasRevenue)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEDE5F2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.show_chart_rounded, size: 15, color: Color(0xFF9D8DA8)),
                                SizedBox(width: 6),
                                Text('No completed sales yet', style: TextStyle(fontFamily: 'TT Fors', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8E8496))),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RevenueLineChart extends StatelessWidget {
  final List<MerchantTrendPoint> trend;

  const _RevenueLineChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final displayTrend = trend.length > 14 ? _downsample(trend, 14) : trend;
    return CustomPaint(
      painter: _RevenueLinePainter(displayTrend),
      child: const SizedBox.expand(),
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

class _RevenueLinePainter extends CustomPainter {
  final List<MerchantTrendPoint> trend;

  _RevenueLinePainter(this.trend);

  @override
  void paint(Canvas canvas, Size size) {
    if (trend.isEmpty) return;
    const chartTop = 8.0;
    const chartBottom = 116.0;
    final maxRevenue = trend.fold<double>(
      0,
      (max, point) => point.revenue > max ? point.revenue : max,
    );
    final maxValue = maxRevenue <= 0 ? 1 : maxRevenue;
    final plotWidth = size.width;
    final step = trend.length == 1 ? plotWidth : plotWidth / (trend.length - 1);

    final gridPaint = Paint()
      ..color = const Color(0xFFEFEAF3)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = chartTop + (chartBottom - chartTop) * i / 3;
      canvas.drawLine(Offset(0, y), Offset(plotWidth, y), gridPaint);
    }

    final points = <Offset>[];
    for (var i = 0; i < trend.length; i++) {
      final normalized = (trend[i].revenue / maxValue).clamp(0.0, 1.0);
      points.add(Offset(step * i, chartBottom - normalized * (chartBottom - chartTop)));
    }

    final areaPath = Path()..moveTo(points.first.dx, chartBottom);
    for (final point in points) areaPath.lineTo(point.dx, point.dy);
    areaPath
      ..lineTo(points.last.dx, chartBottom)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()..color = const Color(0xFF7B3FA0).withValues(alpha: .08),
    );

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final midpoint = (previous.dx + current.dx) / 2;
      linePath.cubicTo(midpoint, previous.dy, midpoint, current.dy, current.dx, current.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF6D318F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotPaint = Paint()..color = const Color(0xFF6D318F);
    final innerPaint = Paint()..color = Colors.white;
    for (final point in points) {
      canvas.drawCircle(point, 4.5, dotPaint);
      canvas.drawCircle(point, 2, innerPaint);
    }

    for (var i = 0; i < trend.length; i++) {
      final label = trend[i].label;
      if (label.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontFamily: 'TT Fors', fontSize: 9, color: Color(0xFF918A98)),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 44);
      final x = (step * i - painter.width / 2).clamp(0.0, plotWidth - painter.width);
      painter.paint(canvas, Offset(x, chartBottom + 10));
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueLinePainter oldDelegate) => oldDelegate.trend != trend;
}
