import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/riderside/rider_stats_provider.dart';

class RiderQuickStatsScreen extends ConsumerWidget {
  const RiderQuickStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(riderStatsProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F2D82)),
        title: Text(
          'Today\'s Stats',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        centerTitle: true,
      ),
      body: statsAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF5F2D82)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your stats...',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: EdgeInsets.all(hp),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not load stats',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(riderStatsProvider);
            await ref.read(riderStatsProvider.future);
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(hp, ResponsiveUtils.spacing(context, 16), hp, 24),
            children: [
              // Today's Earnings Card
              _buildStatCard(
                context,
                icon: Icons.trending_up,
                iconColor: const Color(0xFF4CAF50),
                label: "Today's Earnings",
                value: stats.todayEarningsFormatted,
                subtitle: stats.trendStatus.isEmpty ? null : 'vs yesterday: ${stats.trendStatus}',
              ),
              const SizedBox(height: 16),

              // Completed Trips Card
              _buildStatCard(
                context,
                icon: Icons.local_shipping_outlined,
                iconColor: const Color(0xFF2196F3),
                label: 'Completed Trips',
                value: '${stats.todayTrips}',
                subtitle: stats.todayTrips > 0
                    ? 'Avg: PHP ${(stats.todayEarnings / stats.todayTrips).toStringAsFixed(2)}/trip'
                    : 'No trips yet',
              ),
              const SizedBox(height: 16),

              // Online Hours Card
              _buildStatCard(
                context,
                icon: Icons.schedule,
                iconColor: const Color(0xFFFF9800),
                label: 'Online Hours',
                value: stats.onlineHoursFormatted,
                subtitle: 'Estimated from trips',
              ),
              const SizedBox(height: 16),

              // Weekly Earnings Trend
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Earnings',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last 7 days',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      stats.weeklyEarningsFormatted,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 28),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF5F2D82),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Simple bar chart of daily totals
                    _buildDailyBars(context, stats.dailyTrendData),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tips Card
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: const Color(0xFF2E7D32),
                          size: ResponsiveUtils.fontSize(context, 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pro Tip',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Peak earning hours are typically 11 AM - 1 PM and 5 PM - 8 PM. Maximize your earnings during these times!',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 13),
                        color: Colors.green.shade900,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
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
      child: Row(
        children: [
          Container(
            width: ResponsiveUtils.spacing(context, 48),
            height: ResponsiveUtils.spacing(context, 48),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 20),
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 11),
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBars(BuildContext context, Map<int, double> dailyData) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxValue = dailyData.values.isEmpty ? 1.0 : dailyData.values.reduce((a, b) => a > b ? a : b);
    final now = DateTime.now();
    final currentDay = now.weekday;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final dayIndex = index + 1;
        final value = dailyData[dayIndex] ?? 0.0;
        final isToday = dayIndex == currentDay;
        final height = maxValue > 0 ? (value / maxValue) * 80 : 10.0;

        return Column(
          children: [
            Text(
              dayLabels[index],
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 10),
                color: isToday ? const Color(0xFF5F2D82) : Colors.grey.shade500,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: height.toDouble(),
              decoration: BoxDecoration(
                color: isToday ? const Color(0xFF5F2D82) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PHP ${value.toStringAsFixed(0)}',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 9),
                color: Colors.grey.shade600,
              ),
            ),
          ],
        );
      }),
    );
  }
}
