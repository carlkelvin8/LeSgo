import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/riderside/rider_performance_provider.dart';

class RiderPerformanceScreen extends ConsumerWidget {
  const RiderPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load performance metrics on first build
    ref.listen(riderPerformanceProvider, (prev, next) {
      if (prev == null) {
        ref.read(riderPerformanceProvider.notifier).loadPerformanceMetrics();
      }
    });

    final performanceState = ref.watch(riderPerformanceProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F2D82)),
        title: Text(
          'Performance Dashboard',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        centerTitle: true,
      ),
      body: performanceState.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF5F2D82)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading performance data...',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(riderPerformanceProvider.notifier).refreshPerformanceMetrics();
              },
              child: ListView(
                padding: EdgeInsets.fromLTRB(hp, ResponsiveUtils.spacing(context, 16), hp, 24),
                children: [
                  // Overall Rating Card
                  Container(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: performanceState.ratingColor.withOpacity(0.1),
                            border: Border.all(
                              color: performanceState.ratingColor,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              performanceState.customerRatingFormatted,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 32),
                                fontWeight: FontWeight.w800,
                                color: performanceState.ratingColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Customer Rating',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 13),
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          performanceState.ratingStatus,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 16),
                            fontWeight: FontWeight.w700,
                            color: performanceState.ratingColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${performanceState.totalReviews} reviews',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Key Performance Indicators
                  Text(
                    'Performance Metrics',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Acceptance Rate
                  _buildPerformanceIndicator(
                    context,
                    label: 'Acceptance Rate',
                    value: performanceState.acceptanceRateFormatted,
                    percentage: performanceState.acceptanceRate,
                    color: const Color(0xFF4CAF50),
                    icon: Icons.thumb_up,
                    description: '${performanceState.acceptedOrders} orders accepted',
                  ),
                  const SizedBox(height: 12),

                  // Completion Rate
                  _buildPerformanceIndicator(
                    context,
                    label: 'Completion Rate',
                    value: performanceState.completionRateFormatted,
                    percentage: performanceState.completionRate,
                    color: const Color(0xFF2196F3),
                    icon: Icons.check_circle,
                    description: 'Orders completed successfully',
                  ),
                  const SizedBox(height: 12),

                  // On-Time Rate
                  _buildPerformanceIndicator(
                    context,
                    label: 'On-Time Rate',
                    value: performanceState.onTimeRateFormatted,
                    percentage: performanceState.onTimeRate,
                    color: const Color(0xFFFFC107),
                    icon: Icons.schedule,
                    description: '${performanceState.lateArrivals} late arrivals',
                  ),
                  const SizedBox(height: 24),

                  // Issues & Statistics
                  Text(
                    'Statistics',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.cancel,
                          label: 'Cancellations',
                          value: performanceState.cancellations.toString(),
                          color: const Color(0xFFF44336),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.schedule,
                          label: 'Late Arrivals',
                          value: performanceState.lateArrivals.toString(),
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.star,
                          label: 'Reviews',
                          value: performanceState.totalReviews.toString(),
                          color: const Color(0xFF5F2D82),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Performance Trends
                  if (performanceState.performanceTrend.isNotEmpty) ...[
                    Text(
                      'Performance Trend',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: performanceState.performanceTrend
                          .map((trend) => _buildTrendItem(context, trend))
                          .toList(),
                    ),
                  ],

                  // Tips & Recommendations
                  const SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5F2D82).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF5F2D82),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: const Color(0xFF5F2D82),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pro Tips',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF5F2D82),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTip(
                          'Accept more orders to improve your acceptance rate and earn more.',
                        ),
                        const SizedBox(height: 8),
                        _buildTip(
                          'Plan routes efficiently to maintain on-time deliveries.',
                        ),
                        const SizedBox(height: 8),
                        _buildTip(
                          'Keep your vehicle and appearance professional for better ratings.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPerformanceIndicator(
    BuildContext context, {
    required String label,
    required String value,
    required double percentage,
    required Color color,
    required IconData icon,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 18),
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 11),
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 10),
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(BuildContext context, PerformanceTrendData trend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trend.period,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTrendStat('Acceptance', trend.acceptance, const Color(0xFF4CAF50)),
              _buildTrendStat('Completion', trend.completion, const Color(0xFF2196F3)),
              _buildTrendStat('On-Time', trend.onTime, const Color(0xFFFFC107)),
              _buildTrendStat('Rating', trend.rating, const Color(0xFF5F2D82)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(1)}%',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '•',
          style: TextStyle(
            color: Color(0xFF5F2D82),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 12,
              color: Color(0xFF5F2D82),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
