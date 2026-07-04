import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// Service that checks if a daily sales summary should be shown.
/// On app open (after 8 PM), it shows today's order count and revenue
/// if not already shown today.
class DailySalesSummaryService {
  static const String _prefKeyPrefix = 'daily_sales_shown_';

  /// Returns true if the summary should be shown (after 8 PM and not yet shown today).
  static Future<bool> shouldShowSummary() async {
    final now = DateTime.now();
    if (now.hour < 20) return false; // Only show after 8 PM

    final prefs = await SharedPreferences.getInstance();
    final todayKey = _prefKeyPrefix + _dateKey(now);
    final alreadyShown = prefs.getBool(todayKey) ?? false;
    return !alreadyShown;
  }

  /// Marks today's summary as shown.
  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _prefKeyPrefix + _dateKey(DateTime.now());
    await prefs.setBool(todayKey, true);
    AppLogger.debug('✅ Daily sales summary marked as shown');
  }

  /// Builds summary data from order list.
  static DailySalesSummaryData buildSummary({
    required int completedOrdersToday,
    required double revenueToday,
  }) {
    return DailySalesSummaryData(
      completedOrders: completedOrdersToday,
      revenue: revenueToday,
    );
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class DailySalesSummaryData {
  final int completedOrders;
  final double revenue;

  const DailySalesSummaryData({
    required this.completedOrders,
    required this.revenue,
  });
}

/// A widget that shows the daily sales summary as an in-app banner.
class DailySalesSummaryBanner extends StatelessWidget {
  final DailySalesSummaryData data;
  final VoidCallback? onDismiss;

  const DailySalesSummaryBanner({
    super.key,
    required this.data,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5F2D82), Color(0xFF9B59F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5F2D82).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Today's Summary",
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(Icons.close, color: Colors.white70, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryMetric(
                label: 'Orders',
                value: '${data.completedOrders}',
                icon: Icons.shopping_bag_outlined,
              ),
              const SizedBox(width: 24),
              _SummaryMetric(
                label: 'Revenue',
                value: 'PHP ${data.revenue.toStringAsFixed(2)}',
                icon: Icons.payments_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
