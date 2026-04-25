import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

/// Pure presentational dashboard card — receives ALL data as parameters, zero logic.
class RiderHistoryDashboardCard extends StatelessWidget {
  final int totalBookings;
  final int performanceStars;
  final List<double> chartDataPoints;

  const RiderHistoryDashboardCard({
    super.key,
    required this.totalBookings,
    required this.performanceStars,
    required this.chartDataPoints,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.spacing(context, 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Growth chart using fl_chart
            Container(
              width: ResponsiveUtils.spacing(context, 130),
              height: ResponsiveUtils.spacing(context, 100),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EAFF),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.spacing(context, 12),
                ),
              ),
              padding: EdgeInsets.only(
                left: ResponsiveUtils.spacing(context, 8),
                right: ResponsiveUtils.spacing(context, 8),
                top: ResponsiveUtils.spacing(context, 10),
                bottom: ResponsiveUtils.spacing(context, 4),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1.1,
                  minY: 0,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: const FlTitlesData(show: false),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarGroups(),
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 16)),
            // Dashboard info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 18),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    'Total bookings: $totalBookings',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    'Performance:',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Row(
                    children: List.generate(
                      performanceStars,
                      (index) => Icon(
                        Icons.star_rounded,
                        size: ResponsiveUtils.fontSize(context, 20),
                        color: const Color(0xFFFFC107),
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
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(chartDataPoints.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: chartDataPoints[i],
            width: 14,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              topRight: Radius.circular(3),
            ),
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF9B59B6), Color(0xFF5F2D82)],
            ),
          ),
        ],
      );
    });
  }
}
